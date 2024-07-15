set dotenv-load := true

libs-link core='/home/david/Projects/wavify-core':
	#!/usr/bin/env bash
	rm -rf lib/
	rm -rf python/lib/
	echo {{core}}

	LIB_AARCH64="lib/aarch64-linux-android"
	LIB_LINUX="lib/x86_64-unknown-linux-gnu"
	LIB_WINDOWS="lib/x86_64-pc-windows-gnu"
	LIB_AARCH64_PYTHON_SDK="python/lib/aarch64-linux-android"
	LIB_LINUX_PYTHON_SDK="python/lib/x86_64-unknown-linux-gnu"
	LIB_WINDOWS_PYTHON_SDK="python/lib/x86_64-pc-windows-gnu"
	mkdir -p $LIB_AARCH64
	mkdir -p $LIB_LINUX
	mkdir -p $LIB_WINDOWS
	mkdir -p $LIB_AARCH64_PYTHON_SDK
	mkdir -p $LIB_LINUX_PYTHON_SDK
	mkdir -p $LIB_WINDOWS_PYTHON_SDK

	# Copy libtensorflowlite_c.so, accounting for the variable hash
	AARCH64_PATH_TF=$(find {{core}}/target/build/aarch64-linux-android/aarch64-linux-android/release -name libtensorflowlite_c.so -print -quit)
	X86_64_LINUX_PATH_TF=$(find {{core}}/target/build/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/release -name libtensorflowlite_c.so -print -quit)
	WINDOWS_PATH_TF=$(find {{core}}/target/build/x86_64-pc-windows-gnu/x86_64-pc-windows-gnu/release -name tensorflowlite_c.dll -print -quit)

	if [ -n "$AARCH64_PATH_TF" ]; then
	    cp "$AARCH64_PATH_TF" "${LIB_AARCH64}/"
		cp "$AARCH64_PATH_TF" "${LIB_AARCH64_PYTHON_SDK}/"
	else
	    echo "libtensorflowlite_c.so not found for aarch64."
	fi

	if [ -n "$X86_64_LINUX_PATH_TF" ]; then
	    cp "$X86_64_LINUX_PATH_TF" "${LIB_LINUX}/"
		cp "$X86_64_LINUX_PATH_TF" "${LIB_LINUX_PYTHON_SDK}/"
	else
	    echo "libtensorflowlite_c.so not found for x86_64."
	fi

	if [ -n "$WINDOWS_PATH_TF" ]; then
	    cp "$WINDOWS_PATH_TF" "${LIB_WINDOWS}/"
		cp "$WINDOWS_PATH_TF" "${LIB_WINDOWS_PYTHON_SDK}/"
	else
	    echo "tensorflowlite_c.dll not found for Windows."
	fi

	AARCH64_PATH_WAVIFY={{core}}/target/build/aarch64-linux-android/aarch64-linux-android/release/libwavify_core.so 
	X86_64_LINUX_PATH_WAVIFY={{core}}/target/build/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/release/libwavify_core.so 
	WINDOWS_PATH_WAVIFY={{core}}/target/build/x86_64-pc-windows-gnu/x86_64-pc-windows-gnu/release/wavify_core.dll

	cp "$AARCH64_PATH_WAVIFY" "${LIB_AARCH64}/"
	cp "$X86_64_LINUX_PATH_WAVIFY" "${LIB_LINUX}/"
	cp "$WINDOWS_PATH_WAVIFY" "${LIB_WINDOWS}/"
	cp "$AARCH64_PATH_WAVIFY" "${LIB_AARCH64_PYTHON_SDK}/"
	cp "$X86_64_LINUX_PATH_WAVIFY" "${LIB_LINUX_PYTHON_SDK}/"
	cp "$WINDOWS_PATH_WAVIFY" "${LIB_WINDOWS_PYTHON_SDK}/"

libs-bundle:
	tar -czvf aarch64-linux-android.tar.gz lib/aarch64-linux-android
	tar -czvf x86_64-pc-windows-gnu.tar.gz lib/x86_64-pc-windows-gnu
	tar -czvf x86_64-unknown-linux-gnu.tar.gz lib/x86_64-unknown-linux-gnu

libs-bundle-remove:
	rm aarch64-linux-android.tar.gz 
	rm x86_64-pc-windows-gnu.tar.gz
	rm x86_64-unknown-linux-gnu.tar.gz

python-build:
	rm -rf python/lib
	cp -r lib/ python/lib
	cd python && python -m build

python-lint:
	ruff check .

python-format:
	isort --profile black .
	black .

python-write-documentation:
	cd python/src/wavify && pydoc stt.SttEngine

rust-build:
	rm -rf rust/lib
	cp -r lib/ rust/lib
	cd rust && cargo clean && cargo build

rust-demo-run:
	#!/usr/bin/env bash
	set -euxo pipefail
	cd demos/rust-demo
	source .env 
	export WAVIFY_API_KEY=$WAVIFY_API_KEY
	cargo run

rust-write-documentation:
	cd rust && cargo doc

audio-convert filename:
	ffmpeg -i assets/{{filename}}.mp3 -ar 16000 assets/{{filename}}.wav
