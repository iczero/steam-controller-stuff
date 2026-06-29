use std::os::fd::AsFd;

use rustix::io::Errno;

pub fn hid_get_input_report(
    hidraw_fd: impl AsFd,
    buf: &mut [u8],
) -> rustix::io::Result<Option<&[u8]>> {
    let fd = hidraw_fd.as_fd();
    loop {
        return match rustix::io::read(fd, &mut *buf) {
            Ok(read_len) => Ok(Some(&buf[..read_len])),
            Err(Errno::INTR) => continue,
            Err(Errno::AGAIN) => Ok(None),
            Err(err) => Err(err),
        };
    }
}

pub fn hid_set_output_report(hidraw_fd: impl AsFd, buf: &[u8]) -> rustix::io::Result<()> {
    let fd = hidraw_fd.as_fd();
    loop {
        return match rustix::io::write(fd, buf) {
            Ok(_) => Ok(()),
            Err(Errno::INTR) => continue,
            Err(Errno::AGAIN) => {
                unreachable!("hidraw writes should be blocking even with O_NONBLOCK")
            }
            Err(err) => Err(err),
        };
    }
}
