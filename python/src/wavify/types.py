"""
Types used internally by Wavify.
"""

import ctypes
from ctypes import POINTER, c_float, c_uint64

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
