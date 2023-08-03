{
  description = "Rust developtment environment";

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
        wavfiylib = builtins.toString ./. + "/x86_64-unkown-linux";
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        crossPkgs = import nixpkgs { system = "aarch64-linux"; };
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
            openblas
            # crossPkgs.openblas
            # crossPkgs.openssl
            mold
            gcc
          ]);
          RUST_SRC_PATH = rustPlatform.rustLibSrc;
          LD_LIBRARY_PATH = lib.makeLibraryPath [
            wavfiylib
          ];
          shellHook = ''
            export LIBCLANG_PATH="${pkgs.libclang.lib}/lib"
            export ANDROID_HOME="${android-sdk}/share/android-sdk"
            export ANDROID_SDK_ROOT="${android-sdk}/share/android-sdk"
            export ANDROID_NDK_HOME="${android-sdk}/share/android-sdk/ndk-bundle"
            export ANDROID_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"
            export OPENBLAS_INCLUDE_DIR="${crossPkgs.openblas.dev}/include"
            export OPENBLAS_LIBRARY="${crossPkgs.openblas}/lib/libopenblas.so"
            # export OPENSSL_LIB_DIR="${crossPkgs.openssl.out}/lib"
            # export OPENSSL_INCLUDE_DIR="${crossPkgs.openssl.dev}/include"
            # export CC="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang"
            # export CXX="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang++"
            export JAVA_HOME="${jdk11.home}"
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
