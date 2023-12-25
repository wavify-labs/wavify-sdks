from pathlib import Path 
from wavify import asr

lib = asr.WavifyASR()

model = lib.create_model("../../models/whisper-tiny-en.tflite", "../../models/tokenizer.json")

result_data = lib.process(model, [1.0, 2.0])
print(result_data)

result_file = lib.process_file(model, Path(__file__).parent.parent.parent / "assets" / "english.wav")
print(result_file)

lib.destroy_model(model)