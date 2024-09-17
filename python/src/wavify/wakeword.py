"""
Wavify's wakeword engine.
"""

import ctypes
from ctypes import POINTER, c_char_p, c_float
import math

from wavify.types import FloatArray
from wavify.utils import load_lib


class WakeWordEngineInner(ctypes.Structure):
    """
    A placeholder class for the inner structure of the wakeword engine.
    """

    pass


class WakeWordEngine:
    """
    A class to represent the wakeword engine.

    Attributes:
        lib (CDLL): The loaded wavify core library.
        engine_inner (POINTER(WakeWordEngineInner)): A pointer to
            the inner wakeword engine structure.
    """

    def __init__(self, model_path: str, api_key: str, lib_path=None):
        """
        Initialize the wakeword engine.

        Args:
            model_path (str): The path to the model file.
            api_key (str): The API key for authentication.
                lib_path (Path, optional): The path to the library.
                If None, default paths will be used.

        Raises:
            NotImplementedError: If the provided library path is not supported.
        """
        if lib_path is None:
            self.lib = load_lib()
        else:
            raise NotImplementedError

        self.lib.create_wake_word_engine.argtypes = [c_char_p, c_char_p]
        self.lib.create_wake_word_engine.restype = POINTER(WakeWordEngineInner)

        self.lib.destroy_wake_word_engine.argtypes = [POINTER(WakeWordEngineInner)]
        self.lib.destroy_wake_word_engine.restype = None

        self.lib.detect_wake_word.argtypes = [POINTER(WakeWordEngineInner), FloatArray]
        self.lib.detect_wake_word.restype = c_float

        self.engine_inner = self.lib.create_wake_word_engine(
            model_path.encode("utf-8"), api_key.encode("utf-8")
        )

    def destroy(self):
        """
        Destroy the wakeword engine and free resources.
        """
        self.lib.destroy_wake_word_engine(self.engine_inner)

    def detect(self, data):
        """
        Perform wakeword detection on the given data.

        Args:
            data (list): A list of float values representing the audio data.
                The length should be equal to 2 seconds sampled at 16kHz.

        Returns:
            float: The probability that the audio contains the wakeword.
        """
        arr = (c_float * len(data))(*data)
        float_array = FloatArray(arr, len(data))
        probability = self.lib.detect_wake_word(self.engine_inner, float_array)

        if math.isnan(probability):
            raise RuntimeError("Wavify's core engine caused a runtime error.")
        else:
            return probability
