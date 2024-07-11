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
              extensions = [ "rust-src" "rust-analyzer"];
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
        pythonPackages = pkgs.python310Packages;
        python = pythonPackages.python;
        pythonDeps = p: with p; [
          # sdk
          wheel
          twine
          build
          hatchling
          black
          isort
          # demo
          pip
          # benchmark
          soundfile
          inflect
          matplotlib
          numpy
          pytube
          requests
          editdistance
          more-itertools
          regex
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
            mold
            gcc
            nix-tree
            ffmpeg
            sox
            ruff
            (python.withPackages pythonDeps)
            just
          ]);
          RUST_SRC_PATH = rustPlatform.rustLibSrc;
          LD_LIBRARY_PATH = lib.makeLibraryPath [
            pkgs.stdenv.cc.cc.lib
          ];
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
