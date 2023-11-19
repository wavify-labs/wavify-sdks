from typing import List
from setuptools import find_packages, setup
import platform
from pathlib import Path


# TODO: add support for more platforms
def include_build_assets() -> List[str]:
    if platform.system() == 'Linux' and platform.machine() == "x86_64":
        repo_root_path = Path(__file__).parent.parent
        wavify_core_lib_path = repo_root_path / "lib" / "x86_64-unknown-linux-gnu" / "libwavify_core.so"
        tflite_lib_path = repo_root_path / "lib" / "x86_64-unknown-linux-gnu" / "libtensorflowlite_c.so"
        return [str(wavify_core_lib_path), str(tflite_lib_path)]
    else:
        raise NotImplementedError

    
setup(
    name='wavfiy',
    packages=find_packages(include=["wavify"]),
    version='0.1.0',
    description='Wavify ASR Python SDK',
    author='Wavify',
    package_data={'wavify': include_build_assets()},
    include_package_data=True,
    install_requires=[],
    keywords="Speech-to-Text, Speech Recognition, Voice Recognition, ASR, Automatic Speech Recognition",
    )