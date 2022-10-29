{pkgs ? import <nixpkgs> {}}:
let
    # sources
    sources = import ./nix/sources.nix;

    # to get the exact rust version I want, with wasm enabled
    rust-overlay = import sources.rust-overlay;

    pinned-pkgs = import sources.nixpkgs {
        overlays = [rust-overlay];
    };

    rust-custom = pinned-pkgs.rust-bin.stable.latest.minimal.override {
        targets = ["wasm32-unknown-unknown"];
    };

    wasm-bindgen-cli = pinned-pkgs.wasm-bindgen-cli;

    naersk = pkgs.callPackage sources.naersk {
        cargo = rust-custom;
        rustc = rust-custom;
    };

in
{
    buildWasmWithTrunk = {src}: naersk.buildPackage {
        inherit src;
        cargoBuild = args: '''';
        copyBins = false;
        postInstall = ''trunk build -d $out'';
        buildInputs = [pkgs.trunk wasm-bindgen-cli pkgs.binaryen];
    };
}
