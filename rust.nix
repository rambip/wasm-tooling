{pkgs, naersk}:
let 
    sources = import ./nix/sources.nix;

    rust-custom = pkgs.rust-bin.stable.latest.minimal.override {
        targets = ["wasm32-unknown-unknown"];
    };

    get-wasm-bindgen-cli = version:
        pkgs.stdenv.mkDerivation {
            name = "wasm-bindgen-cli";
            inherit version;
            src = sources."wasm-bindgen-${version}-${pkgs.system}";
            installPhase = ''
            mkdir -p $out/bin
            cp wasm-bindgen wasm-bindgen-test-runner wasm2es6js $out/bin
            '';
        };

    get-wasm-bindgen-cli-version = file:
        let cargo_toml = builtins.fromTOML (builtins.readFile file);
        in builtins.replaceStrings ["="] [""] cargo_toml.wasm-bindgen
    ;
in
rec {
    inherit naersk;
    buildWithTrunk = {src}: naersk.buildPackage {
        inherit src;
        cargoBuild = args: '''';
        copyBins = false;
        postInstall = ''trunk build -d $out'';
        buildInputs = [
            (get-wasm-bindgen-cli (get-wasm-bindgen-cli-version "${src}/Cargo.toml"))
            pkgs.trunk 
            pkgs.binaryen
        ];
    };
}
