import os
from time import time
from pathlib import Path

from wavify.stt import SttEngine
from wavify.utils import LogLevel, set_log_level

set_log_level(LogLevel.DEBUG)

model_path = Path(__file__).parent.parent.parent / "models" / "model-en.bin"
wav_path = Path(__file__).parent.parent.parent / "assets" / "samples_jfk.wav"

engine = SttEngine(model_path.as_posix(), os.getenv("WAVIFY_API_KEY"))

now = time()
result_file = engine.stt_from_file(wav_path)

print(result_file)
print(f"Took {time()-now}s")

engine.destroy()
