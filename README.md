# What is it

This repo hosts usefull [nix](https://nixos.org/nix) expressions to compile things to [webassembly](https://webassembly.org/)


# How to use it


For example, you can use it like this in your trunk project:

```nix
{pkgs? import <nixpkgs> {}}:
let 
    wasm-tools = callPackage (builtins.fetchTarball "https://github.com/rambip/wasm-tooling/archive/master.tar.gz"); 
in
    wasm-tools.rust.buildWithTrunk {src= ./.;}

```

⚠️ Make sure you use wasm-bindgen version 0.2.78 in your Cargo.toml, otherwise it will not work !


# Goals

Nix is arguably the best build/packaging system in existence.

Rust is arguably the most loved languages and the best to create webassembly projects

Yet, it is hard to find ways to easily compile a rust project to webassembly with nix !!!

This is my attempt to fix that.
