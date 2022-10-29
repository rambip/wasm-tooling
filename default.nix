{pkgs, wasm-bindgen-version}:
let
    # sources
    sources = import ./nix/sources.nix;

    # to get the exact rust version I want, with wasm enabled
    rust-overlay = import sources.rust-overlay;

    pinned-pkgs = import sources.nixpkgs {
        overlays = [rust-overlay];
        config = {system = pkgs.system;};
    };

    rust-custom = pinned-pkgs.rust-bin.stable.latest.minimal.override {
        targets = ["wasm32-unknown-unknown"];
    };


    naersk = pkgs.callPackage sources.naersk {
        cargo = rust-custom;
        rustc = rust-custom;
    };

    get-wasm-bindgen-cli = {system, version}:
        pkgs.stdenv.mkDerivation {
            name = "wasm-bindgen-cli";
            inherit version;
            src = sources."wasm-bindgen-${version}-${system}";
            installPhase = ''
            mkdir -p $out/bin
            cp wasm-bindgen wasm-bindgen-test-runner wasm2es6js $out/bin
            '';
        };

in

rec {
    inherit naersk;
    inherit rust-custom;
    wasm-bindgen-cli = get-wasm-bindgen-cli {system=pkgs.system; version=wasm-bindgen-version;};
    buildWasmWithTrunk = {src}: naersk.buildPackage {
        inherit src;
        cargoBuild = args: '''';
        copyBins = false;
        postInstall = ''trunk build -d $out'';
        buildInputs = [pkgs.trunk wasm-bindgen-cli pkgs.binaryen];
    };
}
