use anyhow::Result;
use env_logger::Env;
use std::env;

use wavify::{set_log_level, LogLevel, SttEngine};

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();

    let (model_path, file_path) = if args.len() < 3 {
        (
            "../../../../models/model-en.bin",
            "../../../../assets/samples_jfk.wav",
        )
    } else {
        (&args[1] as &str, &args[2] as &str)
    };

    set_log_level(Some(LogLevel::Debug));
    env_logger::Builder::from_env(Env::default().default_filter_or("debug")).init();

    let engine = SttEngine::new(model_path, &env::var("WAVIFY_API_KEY")?)?;
    let result = engine.stt_from_file(file_path)?;
    println!("{:?}", result);

    engine.destroy();

    Ok(())
}
