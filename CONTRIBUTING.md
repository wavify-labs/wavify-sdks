# How to contribute

## Getting started

Clone the repository. By default, this will fetch large files from Git LFS such as libraries for different targets and models.

```
git clone git@github.com:wavify-labs/wavify-sdks.git

# or this if you don't want large asset files
GIT_LFS_SKIP_SMUDGE=1 git clone git@github.com:wavify-labs/wavify-sdks.git
```

The development environment is provided by nix:

```
curl -L https://nixos.org/nix/install | sh
nix develop 
```

## Usage

The `justfile` serves documentation purposes. Every functionality is a command and can be run like this:

```
just <some command> 	
```
