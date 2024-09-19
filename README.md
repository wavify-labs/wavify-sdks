<p>
  <a href="https://wavify.dev">
    <picture>
      <source media="(prefers-color-scheme: light)" srcset="https://github.com/wavify-labs/wavify-sdks/blob/main/assets/wavify-black-pink-word.svg">
      <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wavify-labs/wavify-sdks/blob/main/assets/wavify-white-pink-word.svg">
      <img src="https://raw.githubusercontent.com/NixOS/nixos-homepage/main/public/logo/nixos-hires.png" width="500px" alt="NixOS logo">
    </picture>
  </a>
</p>

[![Documentation](https://img.shields.io/badge/documentation-grey)](https://www.wavify.dev/docs)
![Static Badge](https://img.shields.io/badge/platforms-Linux%20%7C%20Android%20%7C%20macOS%20%7C%20iOS%20%7C%20Windows-green)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/wavify-labs/wavify-sdks/release.yaml)

Wavify is a collection of small speech models and a runtime that is blazingly fast and runs anywhere.

## Features

### Tasks

- [X] Speech-to-text
- [X] Wake-word detection
- [ ] Speech-to-intent

### Bindings

- [X] Python
- [X] Kotlin
- [X] Swift
- [X] Rust
- [ ] Flutter
- [ ] C++

Additional foreign language bindings can be developed externally and we welcome contributions to list them here. 
Function signature are available in `lib/wavify_core.h`.

### Platforms

- `aarch64-apple-ios`
- `aarch64-linux-android`
- `aarch64-unknown-linux-gnu`
- `aarch64-apple-darwin`
- `x86_64-pc-windows-gnu`
- `x86_64-unknown-linux-gnu`

## Benchmarks

Running speech-to-text on `assets/samples_jfk.wav` on a Raspberry Pi 5.

|Engine   |Size    |Time   |Real-time factor   |
|---|---|---|---|
| Whisper.cpp <br>   | 75MB <br> (Whisper tiny)  | 4.91s  | 0.45  |
| Wavify  | 45MB   | 2.21s  | 0.20  |

## Demo

https://github.com/user-attachments/assets/d8cf06e2-c29e-4d0f-9466-a1269b92a584

## Usage

Speech-to-text models for supported languages are available [here](https://github.com/wavify-labs/wavify-sdks/tree/main/models). The filename specifies the language in which 
the model operates, indicated by the ISO 639-1 code.

We provide the example wake-word model [model-wakeword-alexa.bin](https://github.com/wavify-labs/wavify-sdks/tree/main/models). For custom models please contact us 
at founders@wavify.dev.

You'll also need an API key which is available for free. You can get it from your [dashboard](https://www.wavify.dev/signin/password_signin) once signed in.

### Python

```bash
pip install wavify
```

```python
import os
from wavify.stt import SttEngine

engine = SttEngine("path/to/your/model", os.getenv("WAVIFY_API_KEY"))
result = engine.stt_from_file("/path/to/your/file")
```

```python
import os
from wavify.wakeword import WakeWordEngine

engine = WakeWordEngine("path/to/your/model", os.getenv("WAVIFY_API_KEY"))
audio = ... # audio needs to be 2 seconds sampled at 16kHz, 16 bit linearly encoded and single channel
result = engine.detect(audio)
```

### Rust

```bash
cargo add wavify
```

```rust
use std::env;
use anyhow::Result;
use wavify::SttEngine;

fn main() -> Result<()> {
  let engine = SttEngine::new("/path/to/your/model", &env::var("WAVIFY_API_KEY")?)?;
  let result = engine.stt_from_file("/path/to/your/file")?;
  Ok(())
}
```

### Android

Kotlin bindings and an example app showcasing the integration of Wavify is available in `android/`.

```kotlin
import dev.wavify.SttEngine

val modelPath = File(applicationContext.filesDir, "/your/model").absolutePath
val apiKey = BuildConfig.WAVIFY_AP_KEY
val appName = applicationContext.packageName
val engine = SttEngine.create(modelPath, apiKey, appName) 

val audioFloats = floatArrayOf(0.0f, 0.1f, 0.2f) // Replace with actual audio data
val result = engine.stt(audioFloats)
```

### iOS

Swift bindings and an example app showcasing the integration of Wavify is available in `ios/`.

```swift
guard let modelPath = Bundle.main.path(forResource: "/your/model", ofType: "bin") else {
  fatalError("Failed to find model file.")
}
guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "WAVIFY_API_KEY") as? String else {
  fatalError("No api key found.")
}
engine = SttEngine(modelPath: modelPath, apiKey: apiKey)!
let audioFloats: [Float] = [3.14, 2.71, 1.61]
engine.recognizeSpeech(from: convertDataToFloatArray(data: floatValues.withUnsafeBufferPointer { Data(buffer: $0) })
```

## Contributing

Contributions to `wavify` are welcome. 

- Please report bugs as GitHub issues.
- Questions via GitHub issues are welcome!
- To build from source, check the [contributing page](https://github.com/wavify-labs/wavify-sdks/blob/main/CONTRIBUTING.md).

## Contact

For specialized solutions, including the development of custom models optimized for your specific use case, or to discuss 
how Wavify can be adapted to meet your requirements, you can contact our team directly at founders@wavify.dev.
