{pkgs, naersk-src}:
let 
    sources = import ./nix/sources.nix;

    rust-custom = pkgs.rust-bin.stable.latest.minimal.override {
        targets = ["wasm32-unknown-unknown"];
    };

    naersk = pkgs.callPackage naersk-src {
        cargo = rust-custom;
        rustc = rust-custom;
    };

    get-wasm-bindgen-cli = {src}:
        let cargo_deps = (builtins.fromTOML (builtins.readFile "${src}/Cargo.toml")).dependencies;
            trunk_config = if builtins.pathExists "${src}/Trunk.toml"
                          then (builtins.fromTOML (builtins.readFile "${src}/Trunk.toml"))
                          else {};
            trunk_tools = if builtins.hasAttr"tools" trunk_config then trunk_config.tools else {};

            version_cargo = if builtins.hasAttr "wasm-bindgen" cargo_deps 
                then builtins.replaceStrings ["="] [""] cargo_deps.wasm-bindgen 
                else "0.2";

            version_trunk = if builtins.hasAttr "wasm_bindgen" trunk_tools
                then trunk_tools.wasm_bindgen
                else "0.2";

            isValid = version: builtins.hasAttr "wasm-bindgen-${version}-${pkgs.system}" sources;
            versions = builtins.filter isValid [version_cargo version_trunk];

            version = if (builtins.length versions) == 0 then "0.2.83" else builtins.head versions;

        in 
            pkgs.stdenv.mkDerivation {
                name = "wasm-bindgen-cli";
                inherit version;
                src = sources."wasm-bindgen-${version}-${pkgs.system}";
                installPhase = ''
                mkdir -p $out/bin
                cp wasm-bindgen wasm-bindgen-test-runner wasm2es6js $out/bin
                '';
            }
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
            (get-wasm-bindgen-cli {inherit src;})
            pkgs.trunk 
            pkgs.binaryen
        ];
    };
    buildWithWasmBindgen = {src}: naersk.buildPackage {
        inherit src;
        cargoBuildOptions = list: list++ ["--target=wasm32-unknown-unknown"];
        copyBins = false;
        postInstall = ''
            wasm-bindgen \
            --target web \
            --out-dir $out \
            ./target/wasm32-unknown-unknown/release/*.wasm

        wasm-opt -Os $out/*.wasm -o $out/*.wasm
        '';
        buildInputs = [pkgs.binaryen (get-wasm-bindgen-cli {inherit src;})];
    };
    
    devShell = pkgs.mkShell {
        nativeBuildInputs = [rust-custom];
    };
}
