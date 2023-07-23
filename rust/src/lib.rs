use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_float};

use hound::WavReader;

#[repr(C)]
pub struct Whisper {}

#[repr(C)]
pub struct FloatArray {
    pub data: *const c_float,
    pub len: usize,
}

#[repr(C)]
#[derive(Debug)]
pub struct StringArray {
    data: *const *mut c_char,
    len: usize,
}

extern "C" {
    pub fn create_model(model_path: *const c_char) -> *mut Whisper;
    pub fn destroy_model(model: *mut Whisper);
    pub fn process(model: *const Whisper, data: FloatArray) -> StringArray;
}

pub fn from_file(filename: &str) -> FloatArray {
    let mut reader = WavReader::open(filename).unwrap();

    let mut float_data = Vec::new();

    for sample in reader.samples::<i16>() {
        let float_sample = sample.unwrap() as f64 / i16::MAX as f64;
        float_data.push(float_sample);
    }

    let data: Vec<c_float> = float_data.iter().map(|v| *v as c_float).collect();
    FloatArray {
        data: data.as_ptr(),
        len: data.len(),
    }
}

pub fn free_strings(array: StringArray) -> Vec<String> {
    let c_strings = unsafe {
        assert!(!array.data.is_null());
        Vec::from_raw_parts(array.data as *mut _, array.len, array.len)
    };

    let strings: Vec<String> = c_strings
        .iter()
        .map(|&c_str| unsafe {
            let c_str = CStr::from_ptr(c_str);
            c_str.to_string_lossy().into_owned()
        })
        .collect();

    for &c_str in &c_strings {
        unsafe {
            let _ = CString::from_raw(c_str as *mut _);
        }
    }

    strings
}
