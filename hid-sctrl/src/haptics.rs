use bytes::{BufMut, Bytes};
use tracing::{debug, error, info, warn};

bitflags::bitflags! {
    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub struct StreamStatus: u8 {
        const BUFFER_OVERRUN =  1 << 0;
        const STREAM_STOPPED =  1 << 1;
        const NEEDS_MORE_DATA = 1 << 2;
        const HAS_ENOUGH_DATA = 1 << 3;
        const CONFIG_REJECTED_INVALID = 1 << 4;
        const CONFIG_ACCEPTED = 1 << 5;
        const CONFIG_REJECTED_ALREADY_RUNNING = 1 << 6;
        const UNKNOWN_BIT_8 = 1 << 7;
    }
}

// TODO: consider ringbuf crate or just a return channel for buffer reuse
pub struct HapticsStreamer {
    pub id: u8,
    pub recv: async_channel::Receiver<Bytes>,
    pub current_buffer: Option<Bytes>,
    pub ended: bool,

    /// milliseconds per tick
    pub tickrate: u64,
    /// expected audio rate in bytes per millisecond
    pub baseline_rate: isize,

    // THIS IS A BUCKET
    pub bucket: isize,
    // pub initial_bucket: isize,
    pub is_low: bool,
}

impl HapticsStreamer {
    pub fn new(
        id: u8,
        recv: async_channel::Receiver<Bytes>,
        tickrate: u64,
        baseline_rate: isize,
    ) -> Self {
        // let initial_bucket: isize = baseline_rate * 8;

        Self {
            id,
            recv,
            current_buffer: None,
            ended: false,

            tickrate,
            baseline_rate,

            // initial_bucket,
            bucket: 0,
            is_low: true,
        }
    }

    pub fn handle_status(&mut self, status: StreamStatus) {
        if status.contains(StreamStatus::BUFFER_OVERRUN) {
            warn!("buffer overrun reported");
            self.bucket -= self.baseline_rate * 4;
        }
        if status.contains(StreamStatus::STREAM_STOPPED) {
            error!("stream stop reported");
            // self.bucket += self.initial_bucket;
            self.is_low = true;
        }
        if status.contains(StreamStatus::NEEDS_MORE_DATA) {
            info!("received buffer low");
            self.is_low = true;
        }
        if status.contains(StreamStatus::HAS_ENOUGH_DATA) {
            info!("received buffer high");
            self.is_low = false;
        }
        if status.contains(StreamStatus::CONFIG_REJECTED_INVALID) {
            error!("controller rejects stream configuration: invalid");
            panic!("configuration failed");
        }
        if status.contains(StreamStatus::CONFIG_ACCEPTED) {
            info!("stream configuration was accepted by controller");
        }
        if status.contains(StreamStatus::CONFIG_REJECTED_ALREADY_RUNNING) {
            error!("controller rejects stream configuration: stream already running");
            panic!("configuration failed");
        }
        if status.contains(StreamStatus::UNKNOWN_BIT_8) {
            error!("got unknown bit in status");
        }
    }

    pub fn next_chunk(&mut self, mut buf: &mut [u8]) -> usize {
        let mut bytes_written = 0;
        while !buf.is_empty() {
            if let Some(current) = &mut self.current_buffer {
                if current.len() <= buf.len() {
                    let current = self.current_buffer.take().unwrap();
                    buf.put_slice(&current);
                    bytes_written += current.len();
                } else {
                    let split = current.split_to(buf.len());
                    buf.put_slice(&split);
                    bytes_written += split.len();
                }
            } else {
                match self.recv.try_recv() {
                    Ok(buf) => {
                        self.current_buffer.replace(buf);
                    }
                    Err(async_channel::TryRecvError::Empty) => {
                        warn!("no available buffers!");
                        break;
                    }
                    Err(async_channel::TryRecvError::Closed) => {
                        self.ended = true;
                        break;
                    }
                }
            }
        }

        bytes_written
    }

    pub fn tick(&mut self) {
        if self.ended {
            return;
        }

        let increment = self.baseline_rate * (self.tickrate as isize);
        self.bucket += increment;
        if self.is_low {
            self.bucket += increment / 8;
        } else {
            self.bucket -= increment / 8;
        }
        debug!("bucket is {}", self.bucket);
    }

    pub fn poll_send(&mut self, buf: &mut [u8]) -> usize {
        assert!(buf.len() > 2);

        if self.ended {
            // nothing more to send
            return 0;
        }

        let send_len = buf.len() - 2;
        if (self.bucket.max(0) as usize) < send_len {
            // bucket not full enough
            return 0;
        }

        buf[0] = 0x87; // push data
        buf[1] = self.id; // target
        let len = self.next_chunk(&mut buf[2..]);
        if len == 0 {
            // unavailable
            return 0;
        }

        self.bucket -= len as isize;

        len + 2
    }
}
