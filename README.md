# wavify-sdks

[![Documentation](https://img.shields.io/badge/documentation-grey)](https://www.wavify.dev/docs)
![Static Badge](https://img.shields.io/badge/platforms-Linux%20%7C%20Android%20%7C%20macOS%20%7C%20iOS%20%7C%20Windows-green)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/wavify-labs/wavify-sdks/release.yaml)

Wavify is a collection of small speech models and a runtime that kicks ass and runs anywhere.

## Benchmarks
|Engine   |Size   |Threads   |Time   |Real-time factor   |
|---|---|---|---|---|
| Whisper.cpp <br> (-O3 with NEON)   | 75MB <br> (Whisper tiny)  | 4  | 9.2s  | 0.84  |
| Wavify  | 45MB  | 4  | 3.8s  | 0.35  |

## Usage

Speech-to-text models for supported languages are available in `models/`. The filename specifies the language in which 
the model operates, indicated by the ISO 639-1 code.

You'll also need an API key which you can get from your [dashboard](https://www.wavify.dev/signin/password_signin) once signed in.

### Python

```bash
pip install wavify
```

```python
import os
from wavify.stt import SttEngine

engine = SttEngine("path/to/your/model", os.getenv("WAVIFY_API_KEY"))
result = Wavify.stt_from_file("/path/to/your/file")
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

An example app showcasing the integration of Wavify is available in `android/`.

### iOS

Coming soon.

## Compatibility

- `aarch64-apple-ios`
- `aarch64-linux-android`
- `x86_64-apple-darwin`
- `x86_64-pc-windows-gnu`
- `x86_64-unknown-linux-gnu`

## Contributing

Contributions to `wavify` are welcome. 

- Please report bugs as GitHub issues.
- Questions via GitHub issues are welcome!
- To build from source, check the [contributing page](https://github.com/wavify-labs/wavify-sdks/blob/main/CONTRIBUTING.md).
