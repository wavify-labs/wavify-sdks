link-libs core='/home/manuel/Projects/wavify-core':
	#!/usr/bin/env bash
	set -euxo pipefail
	echo {{core}}

	LIB_AARCH64="lib/aarch64-linux-android"
	LIB_LINUX="lib/x86_64-unknown-linux-gnu"
	LIB_WINDOWS="lib/x86_64-pc-windows-gnu"
	mkdir -p $LIB_AARCH64
	mkdir -p $LIB_LINUX
	mkdir -p $LIB_WINDOWS

	# Create symbolic links for libtensorflowlite_c.so, accounting for the variable hash
	AARCH64_PATH_TF=$(find {{core}}/target/aarch64-linux-android/release -name libtensorflowlite_c.so -print -quit)
	X86_64_LINUX_PATH_TF=$(find {{core}}/target/x86_64-unknown-linux-gnu/release -name libtensorflowlite_c.so -print -quit)
	WINDOWS_PATH_TF=$(find {{core}}/target/x86_64-pc-windows-gnu/release -name tensorflowlite_c.dll -print -quit)

	if [ -n "$AARCH64_PATH_TF" ]; then
	    ln -sfn "$AARCH64_PATH_TF" "${LIB_AARCH64}/libtensorflowlite_c.so"
	else
	    echo "libtensorflowlite_c.so not found for aarch64."
	fi

	if [ -n "$X86_64_LINUX_PATH_TF" ]; then
	    ln -sfn "$X86_64_LINUX_PATH_TF" "${LIB_LINUX}/libtensorflowlite_c.so"
	else
	    echo "libtensorflowlite_c.so not found for x86_64."
	fi

	if [ -n "$WINDOWS_PATH_TF" ]; then
	    ln -sfn "$WINDOWS_PATH_TF" "${LIB_WINDOWS}/tensorflowlite_c.dll"
	else
	    echo "tensorflowlite_c.dll not found for Windows."
	fi

	AARCH64_PATH_WAVIFY={{core}}/target/aarch64-linux-android/release/libwavify_core.so 
	X86_64_LINUX_PATH_WAVIFY={{core}}/target/x86_64-unknown-linux-gnu/release/libwavify_core.so 
	WINDOWS_PATH_WAVIFY={{core}}/target/x86_64-pc-windows-gnu/release/wavify_core.dll

	ln -s "$AARCH64_PATH_WAVIFY" "${LIB_AARCH64}/libwavify_core.so"
	ln -s "$X86_64_LINUX_PATH_WAVIFY" "${LIB_LINUX}/libwavify_core.so"
	ln -s "$WINDOWS_PATH_WAVIFY" "${LIB_WINDOWS}/wavify_core.dll"