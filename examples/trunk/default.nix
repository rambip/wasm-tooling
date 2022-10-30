{pkgs? import <nixpkgs> {}}:
let 
    wasm-tools = pkgs.callPackage ../../default.nix {}; 
in
    wasm-tools.rust.buildWithTrunk {src = ./.;}
