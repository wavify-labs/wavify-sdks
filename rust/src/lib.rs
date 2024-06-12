use hound::WavReader;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

#[macro_use]
extern crate log;
use log::Level;

pub struct SttEngine {
    inner: *mut SttEngineInner,
}

#[repr(C)]
struct SttEngineInner {
    // C ABI does not allow zero-sized structs so we add a dummy field
    _dummy: c_char,
}

#[repr(C)]
pub struct FloatArray {
    pub data: *const f32,
    pub len: usize,
}

#[derive(Debug)]
pub enum WavifyError {
    InitError,
    InferenceError,
}

impl std::fmt::Display for WavifyError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::InitError => write!(f, "Failed to initialize"),
            Self::InferenceError => write!(f, "Failed to run inference"),
        }
    }
}

impl std::error::Error for WavifyError {}

extern "C" {
    fn create_stt_engine(model_path: *const c_char, api_key: *const c_char) -> *mut SttEngineInner;
    fn destroy_stt_engine(model: *mut SttEngineInner);
    fn stt(model: *mut SttEngineInner, data: FloatArray) -> *mut c_char;
    fn free_result(result: *mut c_char);
}

impl SttEngine {
    pub fn new(model_path: &str, api_key: &str) -> Result<SttEngine, WavifyError> {
        let maybe_model_path_c = CString::new(model_path);
        let maybe_api_key_c = CString::new(api_key);
        match (maybe_model_path_c, maybe_api_key_c) {
            (Ok(model_path_c), Ok(api_key_c)) => unsafe {
                let inner = create_stt_engine(model_path_c.as_ptr(), api_key_c.as_ptr());
                Ok(SttEngine { inner })
            },
            (_, _) => Err(WavifyError::InitError),
        }
    }

    pub fn destroy(self) {
        unsafe { destroy_stt_engine(self.inner) }
    }

    pub fn stt(&self, data: &[f32]) -> Result<String, WavifyError> {
        let float_array = FloatArray {
            data: data.as_ptr(),
            len: data.len(),
        };

        unsafe {
            let result_ptr = stt(self.inner, float_array);
            if result_ptr.is_null() {
                return Err(WavifyError::InferenceError);
            }

            let result = CStr::from_ptr(result_ptr).to_string_lossy().into_owned();
            free_result(result_ptr);
            Ok(result)
        }
    }

    pub fn stt_from_file(&self, filename: &str) -> Result<String, WavifyError> {
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

        self.stt(&data)
    }
}
