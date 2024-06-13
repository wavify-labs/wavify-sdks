import os
from time import time
from pathlib import Path

from wavify.stt import SttEngine

engine = SttEngine("../../models/model-de.bin", os.getenv("WAVIFY_API_KEY"))

now = time()
result_file = engine.stt_from_file(
    Path(__file__).parent.parent.parent / "assets" / "de.wav"
)
print(result_file)
print(f"Took {time()-now}s")
engine.destroy()
