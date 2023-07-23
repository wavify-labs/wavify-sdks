use std::ffi::CString;
use std::time::Instant;

use wavify_asr::*;

fn main() {
    unsafe {
        let model_path =
            CString::new("../models/whisper-tiny-de-finished-quant").expect("CString::new failed");
        let model = create_model(model_path.as_ptr());

        for _ in 0..5 {
            let data = from_file("../ml.wav");
            let now = Instant::now();
            let raw_result = process(model, data);
            let result = free_strings(raw_result);
            println!("{:?}", result);
            println!("{:?}", now.elapsed());
        }

        destroy_model(model);
    }
}
