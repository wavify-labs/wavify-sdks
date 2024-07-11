"""
Wavify's speech-to-text engine.
"""

import ctypes
import platform
import struct
import wave
from ctypes import POINTER, c_char_p, c_float, c_uint64
from pathlib import Path


class FloatArray(ctypes.Structure):
    """
    A ctypes structure that represents an array of floats.

    Attributes:
        data (POINTER(c_float)): A pointer to the float data.
        len (c_uint64): The length of the float array.
    """
    _fields_ = [
        ("data", POINTER(c_float)),
        ("len", c_uint64),
    ]


class SttEngineInner(ctypes.Structure):
    """
    A placeholder class for the inner structure of the STT engine.
    """
    pass


def default_library_path() -> (Path, Path):
    """
    Determine the default library paths based on the current platform and architecture.

    Returns:
        tuple: A tuple containing the paths to the Wavify core and TensorFlow Lite libraries.

    Raises:
        NotImplementedError: If the platform or architecture is not supported.
    """
    base = Path(__file__).parent / "lib"
    if platform.system() == "Linux" and platform.machine() == "x86_64":
        platform_dir = base / "x86_64-unknown-linux-gnu"
        return (
            platform_dir / "libwavify_core.so",
            platform_dir / "libtensorflowlite_c.so",
        )
    elif platform.system() == "Windows" and platform.machine() in ["x86_64", "AMD64"]:
        platform_dir = base / "x86_64-pc-windows-gnu"
        return platform_dir / "wavify_core.dll", platform_dir / "tensorflowlite_c.dll"
    else:
        return NotImplementedError


class SttEngine:
    """
    A class to represent the Speech-to-Text (STT) engine.

    Attributes:
        lib (CDLL): The loaded wavify core library.
        engine_inner (POINTER(SttEngineInner)): A pointer to the inner STT engine structure.
    """

    def __init__(self, model_path: str, api_key: str, lib_path=None):
        """
        Initialize the STT engine.

        Args:
            model_path (str): The path to the model file.
            api_key (str): The API key for authentication.
            lib_path (Path, optional): The path to the library. If None, default paths will be used.

        Raises:
            NotImplementedError: If the provided library path is not supported.
        """
        if lib_path is None:
            wavify_lib, tflite_lib = default_library_path()
            ctypes.cdll.LoadLibrary(str(tflite_lib))
            self.lib = ctypes.cdll.LoadLibrary(str(wavify_lib))
        else:
            raise NotImplementedError

        self.lib.create_stt_engine.argtypes = [c_char_p, c_char_p]
        self.lib.create_stt_engine.restype = POINTER(SttEngineInner)

        self.lib.destroy_stt_engine.argtypes = [POINTER(SttEngineInner)]
        self.lib.destroy_stt_engine.restype = None

        self.lib.stt.argtypes = [POINTER(SttEngineInner), FloatArray]
        self.lib.stt.restype = c_char_p

        self.engine_inner = self.lib.create_stt_engine(
            model_path.encode("utf-8"), api_key.encode("utf-8")
        )

    def destroy(self):
        """
        Destroy the STT engine and free resources.
        """
        self.lib.destroy_stt_engine(self.engine_inner)

    def stt(self, data):
        """
        Perform speech-to-text on the given data.

        Args:
            data (list): A list of float values representing the audio data.

        Returns:
            str: The transcribed text.
        """
        arr = (c_float * len(data))(*data)
        float_array = FloatArray(arr, len(data))
        return self.lib.stt(self.engine_inner, float_array).decode("utf-8")

    def stt_from_file(self, file: Path):
        """
        Perform speech-to-text on audio data from a mono, 16bit wave file.

        Args:
            file (Path): The path to the wave file.

        Returns:
            str: The transcribed text.
        """
        wavefile = wave.open(str(file), "r")
        n = wavefile.getnframes()
        wavedata = wavefile.readframes(n)
        data = list(struct.unpack(f"<{n}h", wavedata))
        float_data = [sample / 32767 for sample in data]  # TODO: maybe use numpy here
        return self.stt(float_data)

