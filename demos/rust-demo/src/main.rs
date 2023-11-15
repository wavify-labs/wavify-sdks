use env_logger::Env;
use std::env;
use std::ffi::CString;
use std::os::raw::c_float;
use std::time::Instant;

use wavify_asr::*;

fn main() {
    let args: Vec<String> = env::args().collect();

    let (model_path, tokenizer_path, file_path) = if args.len() < 4 {
        (
            "../../models/whisper-tiny-en.tflite",
            "../../models/tokenizer.json",
            "../../assets/english.wav",
        )
    } else {
        (&args[1] as &str, &args[2] as &str, &args[3] as &str)
    };

    env_logger::from_env(Env::default().default_filter_or("debug")).init();

    unsafe {
        let model_path_c = CString::new(model_path).expect("CString::new failed");
        let tokenizer_path_c = CString::new(tokenizer_path).expect("CString::new failed");
        let model = create_model(model_path_c.as_ptr(), tokenizer_path_c.as_ptr());

        let data = from_file(file_path);
        let now = Instant::now();
        let raw_result = process(model, data);
        let result = read_result(raw_result);
        println!("{:?}", result);
        println!("{:?}", now.elapsed());

        destroy_model(model);
    }
}
