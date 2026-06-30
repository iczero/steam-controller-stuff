use std::io::Read;
use std::path::PathBuf;
use std::process::ExitCode;
use std::time::Duration;

use bytes::Bytes;
use clap::Parser;
use eyre::Context;
use hid_sctrl::haptics::{HapticsStreamer, StreamStatus};
use hid_sctrl::io::{hid_get_input_report, hid_set_output_report};
use rustix::io::Errno;
use tracing::{debug, info, trace, warn};

#[derive(clap::Parser)]
struct Args {
    #[command(subcommand)]
    command: Commands,
}

#[derive(clap::Subcommand)]
enum Commands {
    TestAudio(TestAudioArgs),
}

#[derive(clap::Args)]
struct TestAudioArgs {
    /// hidraw device
    hidraw_device: PathBuf,
    /// audio file
    audio_file: PathBuf,
}

fn main() -> eyre::Result<ExitCode> {
    hid_sctrl::common::initialize_logging();
    info!("hello");

    let args = Args::parse();
    match args.command {
        Commands::TestAudio(args) => test_audio(args),
    }
}

const HID_REPORT_SIZE: usize = 64;

fn test_audio(args: TestAudioArgs) -> eyre::Result<ExitCode> {
    use rustix::fs::{self, OFlags};
    use rustix::thread::clock_nanosleep_absolute;
    use rustix::time::{ClockId, Timespec, clock_gettime};

    // target tick rate in ms
    const TICKRATE: u64 = 2;
    const TICKRATE_TS: Timespec = Timespec {
        tv_sec: 0,
        tv_nsec: (TICKRATE as i64) * 1_000_000,
    };

    let mut wake_time = clock_gettime(ClockId::Monotonic);

    let hidraw = fs::open(
        &args.hidraw_device,
        OFlags::RDWR | OFlags::NONBLOCK,
        fs::Mode::empty(),
    )
    .wrap_err("open hidraw file failed")?;

    let mut in_buf = [0u8; HID_REPORT_SIZE];
    let mut out_buf = [0u8; HID_REPORT_SIZE];

    let mut tick_counter: u64 = 0;

    let (left_send, left_recv) = async_channel::bounded::<Bytes>(64);
    let (right_send, right_recv) = async_channel::bounded::<Bytes>(64);

    let bytes_per_sample = 1.;
    let samples_per_ms = 8.;
    let baseline_rate: f32 = bytes_per_sample * samples_per_ms;
    let mut streamers = [
        HapticsStreamer::new(0, left_recv, TICKRATE, baseline_rate), // INT_LEFT
        HapticsStreamer::new(4, right_recv, TICKRATE, baseline_rate), // INT_RIGHT
                                                                     // HapticsStreamer::new(2, left_recv, TICKRATE, baseline_rate), // INT_BOTH
    ];

    let mut in_file = std::fs::File::open(&args.audio_file).wrap_err("opening pcm file")?;

    std::thread::spawn(move || {
        fn transform_sample(sample: i8) -> i8 {
            (sample as f32 * 0.9) as i8
        }

        let mut buf = [0u8; 65536];
        loop {
            let bytes_read = in_file.read(&mut buf).expect("reading pcm file");
            if bytes_read == 0 {
                // g'bye
                return;
            }

            let read_slice = &buf[..bytes_read];

            // TOOD: actually handle partial reads
            // heheheh shitcode
            assert!(bytes_read.is_multiple_of(2), "oops");

            let mut left_buf = Vec::with_capacity(bytes_read / 2);
            let mut right_buf = Vec::with_capacity(bytes_read / 2);

            for chunk in read_slice.chunks_exact(2) {
                let left_sample = chunk[0] as i8;
                let right_sample = chunk[1] as i8;

                left_buf.push(transform_sample(left_sample) as u8);
                right_buf.push(transform_sample(right_sample) as u8);
            }

            left_send
                .send_blocking(Bytes::from_owner(left_buf))
                .expect("receiver gone");
            right_send
                .send_blocking(Bytes::from_owner(right_buf))
                .expect("receiver gone");
        }
    });

    // configure for 8khz s8 pcm, both INT_LEFT and INT_RIGHT
    hid_set_output_report(&hidraw, &[0x86, 0x02, 0x02, 0x04]).wrap_err("configuring stream")?;

    // HACK: wait for reader to actually read some data and also for the controller to process
    //       the configuration request.
    //       ideally we'd wait for ack before starting. TODO.
    std::thread::sleep(Duration::from_millis(200));

    let mut next_streamer = 0;

    loop {
        let loop_start = clock_gettime(ClockId::Monotonic);
        let error = loop_start
            .checked_sub(wake_time)
            .expect("time travel is forbidden");
        if error > TICKRATE_TS {
            // joever
            warn!("ran out of time, resetting! {error:?} behind");
            wake_time = clock_gettime(ClockId::Monotonic);
        }
        wake_time += TICKRATE_TS;

        'handle_report: {
            let Some(in_report) =
                hid_get_input_report(&hidraw, &mut in_buf).wrap_err("reading input report")?
            else {
                break 'handle_report;
            };

            if in_report.is_empty() {
                warn!("input report too short");
                break 'handle_report;
            }

            match in_report[0] {
                0x44 => {
                    if in_report.len() < 3 {
                        warn!("stream feedback report too short");
                        break 'handle_report;
                    }

                    let target = in_report[1];
                    let status = StreamStatus::from_bits_truncate(in_report[2]);

                    match target {
                        0 => streamers[0].handle_status(status),
                        1 => streamers[1].handle_status(status),
                        n => debug!("ignoring unknown target {n}"),
                    }
                }
                id => trace!("ignoring unhandled input report 0x{id:x}"),
            }
        }

        for s in &mut streamers {
            s.tick();
        }

        // TODO: less shit code?
        for _ in 0..streamers.len() {
            let len = streamers[next_streamer].poll_send(&mut out_buf);
            if len > 0 {
                debug!("sending buffer for {}", streamers[next_streamer].id);
                hid_set_output_report(&hidraw, &out_buf[..len])
                    .wrap_err("writing output report")?;
            }
            next_streamer = (next_streamer + 1) % streamers.len();
            if len > 0 {
                break;
            }
        }

        if streamers.iter().all(|s| s.ended) {
            info!("done");
            return Ok(ExitCode::SUCCESS);
        }

        {
            // pointless code
            if tick_counter & 0b1 > 0 {
                debug!("tock: {tick_counter}");
            } else {
                debug!("tick: {tick_counter}");
            }
            tick_counter += TICKRATE;
        }

        while let Err(err) = clock_nanosleep_absolute(ClockId::Monotonic, &wake_time) {
            if matches!(err, Errno::INTR) {
                continue;
            }

            panic!("insomnia: {err}");
        }
    }
}
