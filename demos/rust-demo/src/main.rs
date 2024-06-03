use anyhow::Result;
use env_logger::Env;
use std::env;
use std::time::Instant;

use wavify::SttEngine;

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();

    let api_key = env::var("WAVIFY_API_KEY")?;

    let (model_path, file_path) = if args.len() < 3 {
        ("../../models/model-en.bin", "../../assets/samples_gb0.wav")
    } else {
        (&args[1] as &str, &args[2] as &str)
    };

    env_logger::Builder::from_env(Env::default().default_filter_or("debug")).init();

    let engine = SttEngine::new(model_path, &api_key)?;
    let now = Instant::now();
    let result = engine.stt_from_file(file_path)?;
    println!("{:?}", result);
    println!("{:?}", now.elapsed());
    engine.destroy();

    Ok(())
}
