use anyhow::Result;
use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use cpal::SampleRate;
use env_logger::Env;
use hound;
use std::env;
use std::io::Read;
use std::iter::Iterator;
use std::path::Path;
use std::sync::Arc;
use std::time::{Duration, Instant};

use wavify::{set_log_level, LogLevel, WakeWordEngine};

fn detect_in_stream(
    frames: impl Iterator<Item = Vec<f32>>,
    continuous: bool,
    relaxation_time: Duration,
    threshold: f32,
) {
    let engine = WakeWordEngine::new(
        "../../models/hey-wavify.bin",
        &std::env::var("WAVIFY_API_KEY").unwrap(),
    )
    .unwrap();
    let mut last_activation_time = Instant::now();
    let mut max_score = 0.0;

    for (i, frame) in frames.enumerate() {
        let pred = engine.detect(&frame).unwrap();
        if pred > max_score {
            max_score = pred;
        }
        if continuous {
            if Instant::now().duration_since(last_activation_time) < relaxation_time {
                continue;
            } else if pred > threshold {
                last_activation_time = Instant::now();
            }
        }

        if pred > threshold {
            print!("\x07\x1b[34m"); // This will output the bell character and change text color to blue
        }

        println!(
            "{:8.3}| {:8.3}{:8.3}\x1b[0m",
            i as f32 / 8.0,
            pred,
            max_score
        ); // Reset text color
    }
}

fn sliding_window_frames(length: usize, chunks: usize) -> impl Iterator<Item = Vec<f32>> {
    let chunk_size = 16_000 * length / chunks;
    let mut sliding_frames = vec![0i16; 16_000 * length];

    let host = cpal::default_host();

    let devices = host.input_devices().unwrap();
    let mut selected_device = None;

    for device in devices {
        match device.default_input_config() {
            Ok(config) => {
                println!("Selected device: {}", device.name().unwrap());
                selected_device = Some((device, config));
                break;
            }
            Err(e) => {
                println!(
                    "Skipping device: {} due to error: {}",
                    device.name().unwrap(),
                    e
                );
            }
        }
    }

    let (device, config) = selected_device.unwrap();
    let stream_config: cpal::StreamConfig = config.into();

    let (tx, rx) = std::sync::mpsc::sync_channel(1);
    let tx = Arc::new(std::sync::Mutex::new(tx));

    let stream = device
        .build_input_stream(
            &stream_config,
            move |data: &[f32], _: &cpal::InputCallbackInfo| {
                let mut buffer = vec![0i16; chunk_size];
                for (i, &sample) in data.iter().enumerate().take(chunk_size) {
                    buffer[i] = (sample * 32768.0) as i16;
                }
                if let Err(e) = tx.lock().unwrap().send(buffer) {
                    eprintln!("Failed to send audio buffer: {:?}", e);
                }
            },
            |err| println!("Stream error: {}", err),
            Some(Duration::from_secs(2)),
        )
        .unwrap();
    stream.play().unwrap();

    std::iter::from_fn(move || {
        sliding_frames.drain(..chunk_size);
        let buffer = match rx.recv() {
            Ok(buffer) => buffer,
            Err(e) => {
                println!(
                    "Error receiving data from audio stream: {:?}",
                    e.to_string()
                );
                panic!()
            }
        };
        sliding_frames.extend(buffer.iter());
        let data: Vec<f32> = sliding_frames.iter().map(|&x| x as f32).collect();
        Some(normalize(&data))
    })
}

fn normalize(data: &[f32]) -> Vec<f32> {
    let min = data.iter().cloned().fold(f32::INFINITY, f32::min);
    let max = data.iter().cloned().fold(f32::NEG_INFINITY, f32::max);
    data.iter().map(|&x| (x - min) / (max - min)).collect()
}

fn main() {
    // Example usage
    let frames = sliding_window_frames(3, 8);
    detect_in_stream(frames, true, Duration::from_secs_f32(0.5), 0.8);
}
