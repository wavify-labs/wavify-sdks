import os
from pathlib import Path

from wavify.stt import SttEngine

engine = SttEngine("../../models/model-en.bin", os.getenv("WAVIFY_API_KEY"))

result_file = engine.stt_from_file(
    Path(__file__).parent.parent.parent / "assets" / "english.wav"
)
print(result_file)

engine.destroy()
