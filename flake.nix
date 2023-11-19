{
  description = "Wavify-sdk developtment environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
    android.url = "github:tadfisher/android-nixpkgs";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, android }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [
          (import rust-overlay)
          (self: super: {
            rustToolchain = super.rust-bin.stable.latest.default.override {
              extensions = [ "rust-src" ];
              targets = [ "armv7-linux-androideabi" "aarch64-linux-android" "i686-linux-android" "x86_64-unknown-linux-gnu" ];
            };
          })
          (
            final: prev: {
              inherit (self.packages.${final.system}) android-sdk android-studio;
            }
          )
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        crossPkgs = import nixpkgs { system = "aarch64-linux"; };
        pythonPackages = pkgs.python310Packages;
        python = pythonPackages.python;
        pythonDeps = p: with p; [
          wheel
          setuptools
          twine
          pip
        ];
      in
      with pkgs;
      {
        devShells.default = mkShell {
          packages = (with pkgs; [
            rustToolchain
            openssl
            pkg-config
            libclang
            cmake
            gfortran9
            # openblas
            mold
            gcc
            nix-tree
            (python.withPackages pythonDeps)
          ]);
          RUST_SRC_PATH = rustPlatform.rustLibSrc;
          shellHook = ''
            export LIBCLANG_PATH="${pkgs.libclang.lib}/lib"
            export ANDROID_HOME="${android-sdk}/share/android-sdk"
            export ANDROID_SDK_ROOT="${android-sdk}/share/android-sdk"
            export ANDROID_NDK_HOME="${android-sdk}/share/android-sdk/ndk-bundle"
            export ANDROID_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"
            export CC="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang"
            export CXX="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang++"
            export JAVA_HOME="${jdk11.home}"

            export LINUX_TFLITEC_PREBUILT_PATH="${pkgs.tensorflow-lite}/lib/libtensorflowlite_c.so"
            export ANDROID_TFLITEC_PREBUILT_PATH="${crossPkgs.tensorflow-lite}/lib/libtensorflowlite_c.so"

          '';
        };
        packages = {
          android-sdk = android.sdk.${system} (sdkPkgs: with sdkPkgs; [
            build-tools-30-0-2
            cmdline-tools-latest
            emulator
            platform-tools
            platforms-android-3
            ndk-bundle
          ]);

          android-studio = pkgs.androidStudioPackages.stable;
        };
      }
    );
}
