{pkgs? import <nixpkgs> {}}:
let 
    wasm-tools = pkgs.callPackage (builtins.fetchTarball "https://github.com/rambip/wasm-tooling/archive/master.tar.gz") {}; 
in
    wasm-tools.buildWithTrunk {src = ./.;}
