use std::f32::consts::E;

fn main() {
    let baseline: f32 = 0.;

    let mut prev = 3.;

    let mut tick: u32 = 0;
    let tickrate: u32 = std::env::args()
        .nth(1)
        .expect("need arg")
        .parse()
        .expect("parse fail");

    let time_constant: f32 = 10.;

    let smoothing_factor: f32 = 1. - E.powf(tickrate as f32 / -time_constant);

    while tick < 50 {
        let cur = baseline;
        prev = smoothing_factor * cur + (1. - smoothing_factor) * prev;

        tick += tickrate;

        println!("tick {tick}: value: {prev}");
    }
}
