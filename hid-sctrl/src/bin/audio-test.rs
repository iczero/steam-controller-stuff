use std::path::PathBuf;
use std::process::ExitCode;

use clap::Parser;
use eyre::Context;
use rustix::io::Errno;
use tracing::{debug, info, warn};

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

    let mut hidraw = fs::open(
        &args.hidraw_device,
        OFlags::RDONLY | OFlags::NONBLOCK,
        fs::Mode::empty(),
    )
    .wrap_err("open hidraw file failed")?;

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

        debug!("tock");

        while let Err(err) = clock_nanosleep_absolute(ClockId::Monotonic, &wake_time) {
            if matches!(err, Errno::INTR) {
                continue;
            }

            panic!("insomnia: {err}");
        }
    }
}
