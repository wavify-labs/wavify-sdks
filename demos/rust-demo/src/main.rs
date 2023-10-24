use env_logger::Env;
use std::env;
use std::ffi::CString;
use std::os::raw::c_float;
use std::time::Instant;

use wavify_asr::*;

fn main() {
    let args: Vec<String> = env::args().collect();

    let (model_path, file_path) = if args.len() < 3 {
        (
            "../../models/whisper-tiny-de-finished-quant",
            "../../ml.wav",
        )
    } else {
        (&args[1] as &str, &args[2] as &str)
    };

    env_logger::from_env(Env::default().default_filter_or("debug")).init();

    unsafe {
        let model_path_c = CString::new(model_path).expect("CString::new failed");
        let model = create_model(model_path_c.as_ptr());

        test_float(0.123 as c_float);
        let data = from_file(file_path);
        let now = Instant::now();
        let raw_result = process(model, data);
        let result = free_strings(raw_result);
        println!("{:?}", result);
        println!("{:?}", now.elapsed());

        destroy_model(model);
    }
}
