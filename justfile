set dotenv-load := true

python-build:
	cd python && python -m build

python-lint:
	ruff check .

python-format:
	isort --profile black .
	black .

python-write-documentation:
	cd python/src/wavify && pydoc stt.SttEngine

python-demo-stt-run:
	#!/usr/bin/env bash
	cd demos/python-demo
	source venv/bin/activate
	source .env 
	export WAVIFY_API_KEY=$WAVIFY_API_KEY
	python speech-to-text.py

python-demo-wakeword-mic-run:
	#!/usr/bin/env bash
	cd demos/python-demo
	source venv/bin/activate
	source .env 
	export WAVIFY_API_KEY=$WAVIFY_API_KEY
	python detect-wake-word.py

python-demo-wakeword-file-run:
	#!/usr/bin/env bash
	cd demos/python-demo
	source venv/bin/activate
	source .env 
	export WAVIFY_API_KEY=$WAVIFY_API_KEY
	python detect-wake-word.py --use-file --file-path ../../assets/samples_jfk.wav 

rust-build:
	rm -rf rust/lib
	cd rust && cargo clean && cargo build

rust-demo-run:
	#!/usr/bin/env bash
	set -euxo pipefail
	cd demos/rust-demo
	source .env 
	export WAVIFY_API_KEY=$WAVIFY_API_KEY
	cargo run --bin stt-demo

rust-write-documentation:
	cd rust && cargo doc


### Internal commands for the Wavify core development team:

libs-link:
	#!/usr/bin/env bash

	if [ -z $WAVIFY_CORE_SOURCE_PATH ]; then
		echo "The location of the of the wavify-core source is not set."
		exit 1
	fi

	LIB_AARCH64="lib/aarch64-linux-android"
	LIB_LINUX="lib/x86_64-unknown-linux-gnu"
	LIB_LINUX_ARM64="lib/aarch64-unknown-linux-gnu"
	LIB_WINDOWS="lib/x86_64-pc-windows-gnu"

	rm -rf $LIB_AARCH64
	rm -rf $LIB_LINUX
	rm -rf $LIB_LINUX_ARM64
	rm -rf $LIB_WINDOWS
	rm -rf "python/${LIB_AARCH64}"
	rm -rf "python/${LIB_LINUX}"
	rm -rf "python/${LIB_LINUX_ARM64}"
	rm -rf "python/${LIB_WINDOWS}"

	mkdir -p $LIB_AARCH64
	mkdir -p $LIB_LINUX
	mkdir -p $LIB_LINUX_ARM64
	mkdir -p $LIB_WINDOWS

	# Copy libtensorflowlite_c.so, accounting for the variable hash
	AARCH64_PATH_TF=$(find $WAVIFY_CORE_SOURCE_PATH/target/build/aarch64-linux-android/aarch64-linux-android/release -name libtensorflowlite_c.so -print -quit)
	X86_64_LINUX_PATH_TF=$(find $WAVIFY_CORE_SOURCE_PATH/target/build/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/release -name libtensorflowlite_c.so -print -quit)
	ARM64_LINUX_PATH_TF=$(find $WAVIFY_CORE_SOURCE_PATH/target/build/aarch64-unknown-linux-gnu/aarch64-unknown-linux-gnu/release -name libtensorflowlite_c.so -print -quit)
	WINDOWS_PATH_TF=$(find $WAVIFY_CORE_SOURCE_PATH/target/build/x86_64-pc-windows-gnu/x86_64-pc-windows-gnu/release -name tensorflowlite_c.dll -print -quit)

	if [ -n "$AARCH64_PATH_TF" ]; then
	    cp "$AARCH64_PATH_TF" "${LIB_AARCH64}/"
	else
	    echo "libtensorflowlite_c.so not found for aarch64."
	fi

	if [ -n "$X86_64_LINUX_PATH_TF" ]; then
	    cp "$X86_64_LINUX_PATH_TF" "${LIB_LINUX}/"
	else
	    echo "libtensorflowlite_c.so not found for x86_64."
	fi

	if [ -n "$ARM64_LINUX_PATH_TF" ]; then
	    cp "$ARM64_LINUX_PATH_TF" "${LIB_LINUX_ARM64}/"
	else
	    echo "libtensorflowlite_c.so not found for aarch64."
	fi

	if [ -n "$WINDOWS_PATH_TF" ]; then
	    cp "$WINDOWS_PATH_TF" "${LIB_WINDOWS}/"
	else
	    echo "tensorflowlite_c.dll not found for Windows."
	fi

	AARCH64_PATH_WAVIFY=$WAVIFY_CORE_SOURCE_PATH/target/build/aarch64-linux-android/aarch64-linux-android/release/libwavify_core.so 
	X86_64_LINUX_PATH_WAVIFY=$WAVIFY_CORE_SOURCE_PATH/target/build/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/release/libwavify_core.so 
	ARM64_LINUX_PATH_WAVIFY=$WAVIFY_CORE_SOURCE_PATH/target/build/aarch64-unknown-linux-gnu/aarch64-unknown-linux-gnu/release/libwavify_core.so 
	WINDOWS_PATH_WAVIFY=$WAVIFY_CORE_SOURCE_PATH/target/build/x86_64-pc-windows-gnu/x86_64-pc-windows-gnu/release/wavify_core.dll

	cp "$AARCH64_PATH_WAVIFY" "${LIB_AARCH64}/"
	cp "$X86_64_LINUX_PATH_WAVIFY" "${LIB_LINUX}/"
	cp "$ARM64_LINUX_PATH_WAVIFY" "${LIB_LINUX_ARM64}/"
	cp "$WINDOWS_PATH_WAVIFY" "${LIB_WINDOWS}/"
	mkdir python/lib
	cp -r lib/aarch64-linux-android python/lib && cp -r lib/x86_64-* python/lib && cp -r lib/aarch64-unknown-linux-gnu python/lib


libs-link-apple:
	#!/usr/bin/env bash

	if [ -z $WAVIFY_CORE_SOURCE_PATH ]; then
		echo "The location of the of the wavify-core source is not set."
		exit 1
	fi

	rm -rf lib/aarch64-apple-ios
	rm -rf lib/aarch64-apple-darwin
	rm -rf python/lib/aarch64-apple-darwin

	LIB_MACOS="lib/aarch64-apple-darwin"
	LIB_IOS="lib/aarch64-apple-ios"

	mkdir -p $LIB_MACOS
	mkdir -p $LIB_IOS

	MAC_PATH_TF=$(find $WAVIFY_CORE_SOURCE_PATH/target/build/aarch64-apple-darwin/aarch64-apple-darwin/release -name libtensorflowlite_c.dylib -print -quit)

	if [ -n "$MAC_PATH_TF" ]; then
	    cp "$MAC_PATH_TF" "${LIB_MACOS}/"
	else
	    echo "libtensorflowlite_c.so not found for MacOS."
	fi

	MACOS_PATH_WAVIFY=$WAVIFY_CORE_SOURCE_PATH/target/build/aarch64-apple-darwin/aarch64-apple-darwin/release/libwavify_core.dylib
	IOS_PATH_WAVIFY=$WAVIFY_CORE_SOURCE_PATH/target/build/aarch64-apple-ios/aarch64-apple-ios/release/libwavify_core.a
	IOS_SIM_PATH_WAVIFY=$WAVIFY_CORE_SOURCE_PATH/target/libwavify_core_fat.a

	cp "$MACOS_PATH_WAVIFY" "${LIB_MACOS}/"
	cp "$IOS_PATH_WAVIFY" "${LIB_IOS}/"
	cp "$IOS_PATH_WAVIFY" lib/WavifyCore.xcframework/ios-arm64/WavifyCore.framework/WavifyCore
	cp "$IOS_SIM_PATH_WAVIFY" lib/WavifyCore.xcframework/ios-arm64_x86_64-simulator/WavifyCore.framework/WavifyCore
	cp -r lib/aarch64-apple-darwin python/lib

libs-link-x86_64-linux:
	#!/usr/bin/env bash

	if [ -z $WAVIFY_CORE_SOURCE_PATH ]; then
		echo "The location of the of the wavify-core source is not set."
		exit 1
	fi

	LIB_LINUX="lib/x86_64-unknown-linux-gnu"
	rm -rf $LIB_LINUX
	mkdir -p $LIB_LINUX

	# Copy libtensorflowlite_c.so, accounting for the variable hash
	X86_64_LINUX_PATH_TF=$(find $WAVIFY_CORE_SOURCE_PATH/target/build/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/release -name libtensorflowlite_c.so -print -quit)

	if [ -n "$X86_64_LINUX_PATH_TF" ]; then
	    cp "$X86_64_LINUX_PATH_TF" "${LIB_LINUX}/"
	else
	    echo "libtensorflowlite_c.so not found for x86_64."
	fi

	X86_64_LINUX_PATH_WAVIFY=$WAVIFY_CORE_SOURCE_PATH/target/build/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/release/libwavify_core.so 

	cp "$X86_64_LINUX_PATH_WAVIFY" "${LIB_LINUX}/"

	rm -rf python/lib/x86_64-unknown-linux-gnu
	cp -rf $LIB_LINUX python/lib

libs-bundle:
	tar -czvf aarch64-linux-android.tar.gz lib/aarch64-linux-android
	tar -czvf aarch64-apple-darwin.tar.gz lib/aarch64-apple-darwin
	tar -czvf x86_64-pc-windows-gnu.tar.gz lib/x86_64-pc-windows-gnu
	tar -czvf x86_64-unknown-linux-gnu.tar.gz lib/x86_64-unknown-linux-gnu
	tar -czvf aarch64-unknown-linux-gnu.tar.gz lib/aarch64-unknown-linux-gnu

libs-bundle-remove:
	rm aarch64-linux-android.tar.gz 
	rm aarch64-apple-darwin.tar.gz 
	rm x86_64-pc-windows-gnu.tar.gz
	rm x86_64-unknown-linux-gnu.tar.gz
	rm aarch64-unknown-linux-gnu.tar.gz
