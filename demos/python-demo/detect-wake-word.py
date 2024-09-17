import os
import argparse
from time import time
from pathlib import Path
from collections.abc import Iterable
from typing import Union

import numpy as np
from wavify.wakeword import WakeWordEngine
from wavify.utils import LogLevel, set_log_level


DURATION_IN_SECONDS = 2
SR = 16_000
DURATION_IN_SAMPLES = int(DURATION_IN_SECONDS * SR)
WINDOWS = int(5 * DURATION_IN_SECONDS)
RELAXATION_TIME = 0.1
THRESHOLD = 0.5


def detect_in_stream(
    frames: Iterable[np.ndarray],
    continuous: bool,
    relaxation_time: float,
    threshold,
):
    engine = WakeWordEngine("../../models/alexa.bin", os.getenv("WAVIFY_API_KEY"))
    last_activation_time = time()
    max_score = 0
    try:
        for i, frame in enumerate(frames):
            pred = engine.detect(frame)
            if pred > max_score:
                max_score = pred
            if continuous:
                if not time() - last_activation_time > relaxation_time:
                    pred = 0
                elif pred > threshold:
                    last_activation_time = time()

            print(
                "\a\033[34m" * bool(pred > threshold)
                + f"{i/8:8.3f}| {pred:8.3f}{max_score:8.3f}\033[0m",
                end="\r\n"[int(pred > threshold)],
            )
    except ValueError:
        print("Audio stream is exhausted.")


def sliding_window_frames(length: int, chunks: int, file: Union[Path, None]) -> None:
    import pyaudio
    import wave

    chunk_size = 16_000 * length // chunks
    chunk_size = int(chunk_size)
    sliding_frames = np.zeros(int(16_000 * length), dtype=np.int16)
    if not bool(file):
        audio = pyaudio.PyAudio()
        stream = audio.open(
            format=pyaudio.paInt16,
            channels=1,
            rate=16_000,
            input=True,
        )

        def read_next():
            return np.frombuffer(stream.read(chunk_size), dtype=np.int16)

    else:
        wf = wave.open(str(file), "rb")

        def read_next():
            return np.frombuffer(wf.readframes(chunk_size), dtype=np.int16)

    print("\033[34m🎤 Listening ...\033[0m")
    try:
        while True:
            np.concatenate(
                [sliding_frames[chunk_size:], read_next()],
                out=sliding_frames,
            )
            data = np.array(sliding_frames, np.float32)
            yield (data - np.min(data)) / (np.max(data) - np.min(data))
            # yield np.array(sliding_frames, np.float32) / 32768.0
    except KeyboardInterrupt:
        print("\033[34m👋 Stop callback\033[0m")


if __name__ == "__main__":
    set_log_level(LogLevel.INFO)

    parser = argparse.ArgumentParser(
        description="Detect wake words in audio input from file or microphone."
    )

    parser.add_argument(
        "--use-file",
        action="store_true",
        help="If set, the program will use the file specified by --file-path",
    )

    parser.add_argument(
        "--file-path", type=str, help="The path to the audio file to be used as input."
    )

    args = parser.parse_args()

    if args.use_file:
        if args.file_path is None:
            print("Error: --file-path must be specified if --use-file is set.")
            exit(1)
        elif not Path(args.file_path).exists():
            print(f"Error: The file {args.file_path} does not exist.")
            exit(1)
        else:
            print(f"Using file: {args.file_path}")
            frame_generator = sliding_window_frames(
                DURATION_IN_SECONDS, WINDOWS, Path(args.file_path)
            )
    else:
        print("Using microphone as input.")
        frame_generator = sliding_window_frames(DURATION_IN_SECONDS, WINDOWS, None)

    detect_in_stream(
        frames=frame_generator,
        continuous=True,
        relaxation_time=RELAXATION_TIME,
        threshold=THRESHOLD,
    )
