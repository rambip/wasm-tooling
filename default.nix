let
    # sources
    sources = import ./nix/sources.nix;

    # to get the exact rust version I want, with wasm enabled
    rust-overlay = import sources.rust-overlay;

    pinned-pkgs = import sources.nixpkgs {};

    custom-overlay = final: prev:
        {
            rust-custom = prev.rust-bin.stable."${prev.rustc.version}".minimal.override {
                targets = ["wasm32-unknown-unknown"];
            };
            rustc = final.rust-custom;
            cargo = final.rust-custom;

            # best nix-rust build tool
            naersk = prev.callPackage (import sources.naersk) {};

            # specific version !
            wasm-bindgen-cli = pinned-pkgs.wasm-bindgen-cli;

            buildWasmWithTrunk = source: final.naersk.buildPackage {
                src = source;
                cargoBuild = args: '''';
                copyBins = false;
                postInstall = ''trunk build -d $out'';
                buildInputs = [prev.trunk final.wasm-bindgen-cli prev.binaryen];
            };
        };

in
    pinned-pkgs.lib.composeExtensions rust-overlay custom-overlay
