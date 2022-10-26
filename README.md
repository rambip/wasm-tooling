# What is it

This repo hosts usefull [nix](https://nixos.org/nix) expressions to compile things to [webassembly](https://webassembly.org/)


# How to use it

If you know how to use nix, the default.nix file defines a derivation.

This derivation does multiple things:
- it changes the rust version and settings to compile to webassembly
- it download naersk, a nix buildtool for rust
- it defines a function buildWasmWithTrunk, which takes a trunk project and directly compile it

For example, you can use it like this in your trunk project:

```nix
let my-overlay = import (builtins.fetchTarball "https://github.com/rambip/wasm-tooling/archive/master.tar.gz");
    pkgs = import <nixpkgs> {overlays = [my-overlay];};
in
    buildWasmWithTrunk ./.

```


# Goals

Nix is arguably the best build/packaging system in existence.

Rust is arguably the most loved languages and the best to create webassembly projects

Yet, it is hard to find ways to easily compile a rust project to webassembly with nix !!!

This is my attempt to fix that.
