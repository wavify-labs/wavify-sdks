running on android:

```
cargo build --target aarch64-linux-android --release
adb push target/aarch64-linux-android/release/rust-demo /storage/emulated/0/Android/data
adb push ../../lib/aarch64-linux-android/libwavify_core.so /storage/emulated/0/Android/data
```

then copy binary to /data/data/com.termux/files/home and copy library to /data/data/com.termux/files/usr/lib and moke both executable `chmod +x`
then run

```
export LD_LIBRARY_PATH=/data/data/com.termux/files/usr/lib
```