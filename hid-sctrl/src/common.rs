use tracing::debug;

pub fn setup_log_handlers() {
    use tracing_error::ErrorLayer;
    use tracing_subscriber::prelude::*;
    use tracing_subscriber::{EnvFilter, fmt};

    color_eyre::install().unwrap();

    let fmt_layer = fmt::layer().with_writer(std::io::stderr);
    let filter_layer = EnvFilter::try_from_default_env()
        .or_else(|_| EnvFilter::try_new("info"))
        .unwrap();

    tracing_subscriber::registry()
        .with(filter_layer)
        .with(fmt_layer)
        .with(ErrorLayer::default())
        .init();
}

pub fn initialize_logging() {
    use std::sync::Once;

    static INITIALIZE: Once = Once::new();
    INITIALIZE.call_once(setup_log_handlers);
}

/// Start a multi-thread flavor Tokio runtime
pub fn start_tokio_runtime_mt(default_max_threads: usize) -> tokio::runtime::Runtime {
    let thread_count: usize = if let Ok(env_threads_str) = std::env::var("TOKIO_WORKER_THREADS")
        && let Ok(env_threads) = env_threads_str.parse()
    {
        env_threads
    } else if let Ok(sys_threads) = std::thread::available_parallelism() {
        usize::min(sys_threads.get(), default_max_threads)
    } else {
        1
    };

    debug!("starting runtime with {thread_count} threads");

    tokio::runtime::Builder::new_multi_thread()
        .worker_threads(thread_count)
        .thread_name_fn(|| {
            use std::sync::atomic::{self, AtomicUsize};

            static COUNTER: AtomicUsize = AtomicUsize::new(1);
            let count = COUNTER.fetch_add(1, atomic::Ordering::Relaxed);
            format!("tokio-rt-{count}")
        })
        .enable_all()
        .build()
        .expect("failed to construct runtime")
}
