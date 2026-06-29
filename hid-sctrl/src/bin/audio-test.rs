use std::io::Read;
use std::path::PathBuf;
use std::process::ExitCode;

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

    // target tick rate: 1 ms
    const TICKRATE: Timespec = Timespec {
        tv_sec: 0,
        tv_nsec: 1_000_000,
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

    let (left_send, left_recv) = async_channel::bounded(64);
    let (right_send, right_recv) = async_channel::bounded(64);

    let mut streamers = [
        HapticsStreamer::new(0, left_recv),  // INT_LEFT
        HapticsStreamer::new(4, right_recv), // INT_RIGHT
    ];

    let mut in_file = std::fs::File::open(&args.audio_file).wrap_err("opening pcm file")?;

    std::thread::spawn(move || {
        let mut buf = [0u8; 65536];
        loop {
            let bytes_read = in_file.read(&mut buf).expect("reading pcm file");
            let read_slice = &buf[..bytes_read];

            // TOOD: actually handle partial reads
            // heheheh shitcode
            assert!(bytes_read % 4 == 0, "oops");

            let mut left_buf = Vec::with_capacity(bytes_read / 2);
            let mut right_buf = Vec::with_capacity(bytes_read / 2);

            for chunk in read_slice.chunks_exact(4) {
                left_buf.extend(&chunk[0..2]);
                right_buf.extend(&chunk[2..4]);
            }

            left_send
                .send_blocking(Bytes::from_owner(left_buf))
                .expect("receiver gone");
            right_send
                .send_blocking(Bytes::from_owner(right_buf))
                .expect("receiver gone");
        }
    });

    let mut next_streamer = 0;

    loop {
        let loop_start = clock_gettime(ClockId::Monotonic);
        let error = loop_start
            .checked_sub(wake_time)
            .expect("time travel is forbidden");
        if error > TICKRATE {
            // joever
            warn!("ran out of time, resetting! {error:?} behind");
            wake_time = clock_gettime(ClockId::Monotonic);
        }
        wake_time += TICKRATE;

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
                        n => warn!("ignoring unknown target {n}"),
                    }
                }
                id => trace!("ignoring unhandled input report 0x{id:x}"),
            }
        }

        if tick_counter.is_multiple_of(2) {
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
        }

        if tick_counter == 0 {
            // configure for 8khz s16le pcm, both INT_LEFT and INT_RIGHT
            hid_set_output_report(&hidraw, &[0x86, 0x02, 0x02, 0x00])
                .wrap_err("configuring stream")?;
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
            tick_counter += 1;
        }

        while let Err(err) = clock_nanosleep_absolute(ClockId::Monotonic, &wake_time) {
            if matches!(err, Errno::INTR) {
                continue;
            }

            panic!("insomnia: {err}");
        }
    }
}
