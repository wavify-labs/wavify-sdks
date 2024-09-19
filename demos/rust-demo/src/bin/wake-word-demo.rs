use std::env;

use wavify::WakeWordEngine;

const DURATION_IN_SECONDS: f32 = 2.0;
const SR: usize = 16_000;
const DURATION_IN_SAMPLES: usize = (DURATION_IN_SECONDS * SR as f32) as usize;
const THRESHOLD: f32 = 0.5;
const CHUNKS: usize = (10.0 * DURATION_IN_SECONDS) as usize;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();

    let (model_path, file_path) = if args.len() < 3 {
        (
            "../../models/model-wakeword-alexa.bin",
            "../../assets/alexa.wav",
        )
    } else {
        (&args[1] as &str, &args[2] as &str)
    };

    let api_key =
        env::var("WAVIFY_API_KEY").expect("Please set the WAVIFY_API_KEY environment variable");
    let engine = WakeWordEngine::new(model_path, &api_key)?;

    let mut max_score = 0.0;
    let mut sliding_frames = vec![0i16; DURATION_IN_SAMPLES];
    let chunk_size = (SR as f32 * DURATION_IN_SECONDS / CHUNKS as f32) as usize;

    let mut reader = hound::WavReader::open(file_path)?;
    let spec = reader.spec();

    if spec.channels != 1 || spec.sample_rate != SR as u32 {
        panic!("The WAV file must be mono with a 16kHz sample rate.");
    }

    let mut samples_iter = reader.samples::<i16>();

    loop {
        let mut new_samples = Vec::with_capacity(chunk_size);
        for _ in 0..chunk_size {
            match samples_iter.next() {
                Some(Ok(sample)) => new_samples.push(sample),
                Some(Err(e)) => return Err(Box::new(e)),
                None => break,
            }
        }

        if new_samples.is_empty() {
            println!("Audio stream is exhausted.");
            break;
        }

        sliding_frames.drain(..new_samples.len());
        sliding_frames.extend(new_samples);

        let data_f32: Vec<f32> = normalize(&sliding_frames);

        let pred = engine.detect(&data_f32)?;

        if pred > max_score {
            max_score = pred;
        }

        if pred > THRESHOLD {
            print!("\x07\x1b[34m"); // Bell character and blue color
        }

        println!("{:8.3} {:8.3}\x1b[0m", pred, max_score);
    }

    Ok(())
}

fn normalize(samples: &[i16]) -> Vec<f32> {
    let min_sample = samples.iter().min().copied().unwrap_or(0) as f32;
    let max_sample = samples.iter().max().copied().unwrap_or(0) as f32;
    let range = max_sample - min_sample;

    if range == 0.0 {
        return vec![0.0; samples.len()];
    }

    samples
        .iter()
        .map(|&s| (s as f32 - min_sample) / range)
        .collect()
}
