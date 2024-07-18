use hound::WavReader;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

#[macro_use]
extern crate log;
use log::Level;

/// Represents the Speech-to-Text Engine.
pub struct SttEngine {
    inner: *mut SttEngineInner,
}

#[repr(C)]
struct SttEngineInner {
    // C ABI does not allow zero-sized structs so we add a dummy field
    _dummy: c_char,
}

/// A struct representing an array of floating-point numbers.
#[repr(C)]
pub struct FloatArray {
    /// Pointer to the array data.
    pub data: *const f32,
    /// Length of the array.
    pub len: usize,
}

/// Represents possible errors that can occur during the speech-to-text process.
#[derive(Debug)]
pub enum WavifyError {
    /// Error that occurs during initialization of the STT engine.
    InitError,
    /// Error that occurs during inference.
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
    fn setup_logger(level: *const c_char);
}

impl SttEngine {
    /// Creates a new instance of `SttEngine`.
    ///
    /// # Arguments
    ///
    /// * `model_path` - A string slice that holds the path to the model.
    /// * `api_key` - A string slice that holds the API key.
    ///
    /// # Returns
    ///
    /// A result that, if successful, contains a new instance of `SttEngine`. Otherwise, it contains a `WavifyError`.
    ///
    /// # Examples
    ///
    /// ```
    /// let engine = SttEngine::new("path/to/model", "api_key");
    /// ```
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

    /// Destroys the `SttEngine` instance, freeing any resources.
    pub fn destroy(self) {
        unsafe { destroy_stt_engine(self.inner) }
    }

    /// Performs speech-to-text on the given audio data.
    ///
    /// # Arguments
    ///
    /// * `data` - A slice of floating-point numbers representing the audio data.
    ///
    /// # Returns
    ///
    /// A result that, if successful, contains a `String` with the recognized text. Otherwise, it contains a `WavifyError`.
    ///
    /// # Examples
    ///
    /// ```
    /// let text = engine.stt(&audio_data).unwrap();
    /// ```
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

    /// Performs speech-to-text on an audio file.
    ///
    /// # Arguments
    ///
    /// * `filename` - A string slice that holds the path to the audio file.
    ///
    /// # Returns
    ///
    /// A result that, if successful, contains a `String` with the recognized text. Otherwise, it contains a `WavifyError`.
    ///
    /// # Examples
    ///
    /// ```
    /// let text = engine.stt_from_file("path/to/audio.wav").unwrap();
    /// ```
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

/// Sets up the logger using the underlying library.
///
/// # Examples
///
/// ```
/// set_log_level(level: &str);
/// ```
///
/// # Panics
///
/// This function does not panic.
///
/// # Errors
///
/// This function does not return any errors. Any errors during the logger setup
/// must be handled internally by the core library.
/// 

pub fn set_log_level(level: &str) {

    let c_level = CString::new(level).expect("Log level conversion failed");
    unsafe {
        setup_logger(c_level.as_ptr());
    }
}
