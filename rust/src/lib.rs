use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_float};

use hound::WavReader;
#[macro_use]
extern crate log;
use log::Level;

#[repr(C)]
pub struct Model {}

#[repr(C)]
pub struct FloatArray {
    pub data: *const f32,
    pub len: usize,
}

extern "C" {
    pub fn create_model(model_path: *const c_char) -> *mut Model;
    pub fn destroy_model(model: *mut Model);
    pub fn process(model: *const Model, data: FloatArray) -> *mut c_char;
    pub fn test_float(n: c_float);
}

pub fn from_file(filename: &str) -> FloatArray {
    let mut reader = WavReader::open(filename).unwrap();

    let mut float_data = Vec::new();

    for sample in reader.samples::<i16>() {
        let float_sample = sample.unwrap() as f64 / i16::MAX as f64;
        float_data.push(float_sample);
    }

    let data: Vec<f32> = float_data.iter().map(|v| *v as f32).collect();
    log!(Level::Debug, "Audio codec: {:?}", &data[..10]);
    let out = FloatArray {
        data: data.as_ptr(),
        len: data.len(),
    };
    std::mem::forget(data); // TODO: deal with memory leak
    out
}

pub fn read_result(ffi_result: *mut c_char) -> String {
    let result_string = unsafe {
        let c_str = CStr::from_ptr(ffi_result);
        c_str.to_string_lossy().into_owned()
    };
    result_string
}
