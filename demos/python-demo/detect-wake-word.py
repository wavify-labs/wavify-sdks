import os
from time import time
from pathlib import Path

from wavify.wakeword import WakeWordEngine 
from wavify.utils import LogLevel, set_log_level

set_log_level(LogLevel.DEBUG)
engine = WakeWordEngine("../../models/hey-wavify.bin", os.getenv("WAVIFY_API_KEY"))

now = time()
data = list(range(16_000))
result = engine.detect(data)
print(f"Took {time()-now}s")
engine.destroy()
