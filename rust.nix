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

    maybe = name: condition: if condition == false then null else name;

    get-wasm-bindgen-cli = {src}:
        let 
            isValid = version: builtins.hasAttr "wasm-bindgen-${version}-${pkgs.system}" sources;

            cargo_info = {
                path = "${src}/Cargo.toml";
                ${maybe "config" (builtins.pathExists cargo_info.path)} = builtins.fromTOML (builtins.readFile cargo_info.path);
                ${maybe "raw_version" (cargo_info.config.dependencies.wasm-bindgen or false)} = cargo_info.config.dependencies.wasm-bindgen;
                ${maybe "version" (cargo_info ? raw_version)} = builtins.replaceStrings ["="] [""] cargo_info.raw_version;
                ${maybe "precise_version" (cargo_info ? version && isValid cargo_info.version)} = cargo_info.version;
            };
            trunk_info = {
                path = "${src}/Trunk.toml";
                ${maybe "config" (builtins.pathExists trunk_info.path)} = builtins.fromTOML (builtins.readFile cargo_info.path);
                ${maybe "version" (trunk_info.dependencies.wasm-bindgen or false)} = trunk_info.dependencies.wasm-bindgen;
            };

            version = cargo_info.precise_version or trunk_info.version or "0.2.83"; 
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
        postInstall = ''wasm-bindgen --version && trunk build -d $out'';
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
