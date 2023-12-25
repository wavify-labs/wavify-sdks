import ctypes
from pathlib import Path
from ctypes import c_char_p, c_uint64, POINTER, c_float, c_uint8
import wave
import struct

class FloatArray(ctypes.Structure):
    _fields_ = [
        ('data', POINTER(c_float)),
        ('len', c_uint64),
    ]

class WavifyASRModel(ctypes.Structure):
    pass

def default_library_path() -> (Path, Path):
    # TODO: support more plattforms 
    base = Path(__file__).parent.parent / "x86_64-unknown-linux-gnu"
    return base / "libwavify_core.so", base / "libtensorflowlite_c.so"

class WavifyASR:
    def __init__(self, lib_path=None):
        if lib_path == None:
            wavify_lib, tflite_lib = default_library_path()
            ctypes.cdll.LoadLibrary(tflite_lib)
            self.lib = ctypes.cdll.LoadLibrary(wavify_lib)
        else:
            raise NotImplementedError

        self.lib.create_model.argtypes = [c_char_p, c_char_p]
        self.lib.create_model.restype = POINTER(WavifyASRModel)

        self.lib.destroy_model.argtypes = [POINTER(WavifyASRModel)]
        self.lib.destroy_model.restype = None

        self.lib.process.argtypes = [POINTER(WavifyASRModel), FloatArray]
        self.lib.process.restype = c_char_p

    def create_model(self, model_path: str, tokenizer_path: str) -> POINTER(WavifyASRModel):
        return self.lib.create_model(model_path.encode('utf-8'), tokenizer_path.encode('utf-8'))

    def destroy_model(self, model: POINTER(WavifyASRModel)):
        self.lib.destroy_model(model)

    def process(self, model: POINTER(WavifyASRModel), data):
        arr = (c_float * len(data))(*data)
        float_array = FloatArray(arr, len(data))
        return self.lib.process(model, float_array).decode("utf-8")
    
    def process_file(self, model: POINTER(WavifyASRModel), file: Path):
        """Process a mono, 16bit wave file"""
        wavefile = wave.open(str(file), 'r')
        n = wavefile.getnframes()
        wavedata = wavefile.readframes(n)
        data = list(struct.unpack(f"<{n}h", wavedata))
        float_data = [sample / 32767 for sample in data] # TODO: maybe use numpy here
        return self.process(model, float_data)
    
