import os
from time import time
from pathlib import Path

from wavify.stt import SttEngine, LogLevel

engine = SttEngine("../../models/model-en.bin", os.getenv("WAVIFY_API_KEY"))
engine.set_log_level(LogLevel.DEBUG)

now = time()
result_file = engine.stt_from_file(
    Path(__file__).parent.parent.parent / "assets" / "samples_jfk.wav"
)
print(result_file)
print(f"Took {time()-now}s")
engine.destroy()
