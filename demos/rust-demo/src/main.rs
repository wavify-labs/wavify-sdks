use env_logger::Env;
use std::env;
use std::ffi::CString;
use std::os::raw::c_float;
use std::time::Instant;

use wavify::*;

fn main() {
    let args: Vec<String> = env::args().collect();

    let (model_path, file_path) = if args.len() < 3 {
        (
            "../../models/model-en.bin",
            "../../assets/samples_gb1.wav",
            // "../../assets/samples_gb1_small.wav",
            // "../../assets/samples_gb1_tiny.wav",
            // "../../assets/english.wav",
        )
    } else {
        (&args[1] as &str, &args[2] as &str)
    };

    env_logger::from_env(Env::default().default_filter_or("debug")).init();

    unsafe {
        let model_path_c = CString::new(model_path).expect("CString::new failed");
        let stt_engine = create_stt_engine(model_path_c.as_ptr());

        let data = from_file(file_path);
        let now = Instant::now();
        let raw_result = stt(stt_engine, data);
        let result = read_result(raw_result);
        println!("{:?}", result);
        println!("{:?}", now.elapsed());

        destroy_stt_engine(stt_engine);
    }
}
