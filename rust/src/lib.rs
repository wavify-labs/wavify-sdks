use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_float};

use hound::WavReader;
#[macro_use]
extern crate log;
use log::Level;

#[repr(C)]
pub struct SttEngine {}

#[repr(C)]
pub struct FloatArray {
    pub data: *const f32,
    pub len: usize,
}

extern "C" {
    pub fn create_stt_engine(model_path: *const c_char) -> *mut SttEngine;
    pub fn destroy_stt_engine(model: *mut SttEngine);
    pub fn stt(model: *mut SttEngine, data: FloatArray) -> *mut c_char;
    pub fn free_result(result: *mut c_char);
}

pub fn from_file(filename: &str) -> FloatArray {
    let mut reader = WavReader::open(filename).unwrap();

    let mut float_data = Vec::new();

    for sample in reader.samples::<i16>() {
        let float_sample = sample.unwrap() as f64 / i16::MAX as f64;
        float_data.push(float_sample);
    }

    let data: Vec<f32> = float_data.iter().map(|v| *v as f32).collect();
    log!(
        Level::Debug,
        "Audio codec: {:?} with len: {}",
        &data[..10],
        data.len()
    );

    // data under pointer needs to outlive the function
    let data_boxed = Box::new(data);
    let data_ptr = Box::leak(data_boxed.clone()).as_ptr();
    let data_len = data_boxed.len();

    FloatArray {
        data: data_ptr,
        len: data_len,
    }
}

// TODO: Call destroy method after reading
pub unsafe fn read_result(ffi_result: *mut c_char) -> String {
    let result_string = unsafe {
        let c_str = CStr::from_ptr(ffi_result);
        c_str.to_string_lossy().into_owned()
    };
    free_result(ffi_result);
    result_string
}
