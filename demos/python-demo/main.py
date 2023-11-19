from wavify import asr

lib = asr.WavifyASR()

model = lib.create_model("../../models/whisper-tiny-en.tflite", "../../models/tokenizer.json")

res = lib.process(model, [1.0, 2.0])
print(res)