"""
Symbols used across various engine types of Wavify.
"""

from enum import Enum
import ctypes
import platform
from typing import Union
from ctypes import CDLL
from pathlib import Path


class LogLevel(Enum):
    TRACE = "trace"
    DEBUG = "debug"
    INFO = "info"
    WARN = "warn"
    ERROR = "error"


def set_log_level(level: Union[LogLevel, None] = LogLevel.INFO):
    """
    Set the logging level.
    Available values are: LogLevel.TRACE, LogLevel.DEBUG,
    LogLevel.INFO, LogLevel.WARN, LogLevel.ERROR.
    If None provided, log level is set to LogLevel.INFO

    Args:
        level (Union[LogLevel, None]): The logging level.
    """
    lib = load_lib()
    if isinstance(level, str):
        # If level is a LogLevel.value, convert it to LogLevel enum if possible
        try:
            level_enum = LogLevel[level.upper()]
        # if regular string was provided raise error
        except KeyError:
            raise ValueError(
                "Invalid type for level. " + "Must be a LogLevel or LogLevel.value"
            )
        lib.setup_logger(level_enum.value.encode("utf-8"))
    elif isinstance(level, LogLevel):
        lib.setup_logger(level.value.encode("utf-8"))
    else:
        raise ValueError(
            "Invalid type for level. " + "Must be a LogLevel or LogLevel.value"
        )


def default_library_path() -> tuple[Path, Path]:
    """
    Determine the default library paths based on the current platform and architecture.

    Returns:
        tuple: A tuple containing the paths to the Wavify core and
        TensorFlow Lite libraries.

    Raises:
        NotImplementedError: If the platform or architecture is not supported.
    """
    base = Path(__file__).parent / "lib"
    system = platform.system()
    machine = platform.machine()

    paths = {
        ("Linux", "x86_64"): "x86_64-unknown-linux-gnu",
        ("Linux", "aarch64"): "aarch64-unknown-linux-gnu",
        ("Windows", "x86_64"): "x86_64-pc-windows-gnu",
        ("Windows", "AMD64"): "x86_64-pc-windows-gnu",
        ("Darwin", "arm64"): "aarch64-apple-darwin",
    }

    if (system, machine) not in paths:
        raise NotImplementedError(
            f"Unsupported platform or architecture: {system}, {machine}"
        )

    platform_dir = base / paths[(system, machine)]

    if system == "Windows":
        return platform_dir / "wavify_core.dll", platform_dir / "tensorflowlite_c.dll"
    elif system == "Darwin":
        return (
            platform_dir / "libwavify_core.dylib",
            platform_dir / "libtensorflowlite_c.dylib",
        )
    else:
        return (
            platform_dir / "libwavify_core.so",
            platform_dir / "libtensorflowlite_c.so",
        )


def load_lib() -> CDLL:
    wavify_lib, tflite_lib = default_library_path()
    ctypes.cdll.LoadLibrary(str(tflite_lib))
    lib = ctypes.cdll.LoadLibrary(str(wavify_lib))
    return lib
