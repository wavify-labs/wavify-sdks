import os
from time import time
from pathlib import Path

from wavify.stt import SttEngine
from wavify.utils import LogLevel, set_log_level

set_log_level(LogLevel.DEBUG)
engine = SttEngine(
    model_path="../../models/model-en-turbo.bin",
    language="en",
    api_key=os.getenv("WAVIFY_API_KEY"),
)

now = time()
result_file = engine.stt_from_file(
    Path(__file__).parent.parent.parent / "assets" / "samples_jfk.wav"
)
print(result_file)
print(f"Took {time()-now}s")
engine.destroy()
