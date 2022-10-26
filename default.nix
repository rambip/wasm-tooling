let
    # to get the exact rust version I want, with wasm enabled
    rust-overlay = (import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"));

    custom-overlay = final: prev:
        {
            rust-custom = prev.rust-bin.stable."${prev.rustc.version}".minimal.override {
                targets = ["wasm32-unknown-unknown"];
            };
            rustc = final.rust-custom;
            cargo = final.rust-custom;

            naersk = prev.callPackage (import (builtins.fetchTarball "https://github.com/nix-community/naersk/archive/master.tar.gz")) {};

            wasm-bindgen-cli = final.naersk.buildPackage {
                src =(prev.fetchCrate {
                        pname = "wasm-bindgen-cli";
                        version = "0.2.78";
                        sha256 = "sha256-5s+HidnVfDV0AXA+/YcXNGVjv/E9JeK0Ttng4mCVX8M=";
                        });
                buildInputs = [prev.openssl];
                nativeBuildInputs = [ prev.pkg-config ];
            };

            buildWasmWithTrunk = source: final.naersk.buildPackage {
                src = source;
                cargoBuild = args: '''';
                copyBins = false;
                postInstall = ''final.trunk build -d $out'';
                buildInputs = [prev.trunk final.wasm-bindgen-cli prev.binaryen];
            };
        };

        composeExtensions =
    f: g: final: prev:
      let fApplied = f final prev;
          prev' = prev // fApplied;
      in fApplied // g final prev';

in
    composeExtensions rust-overlay custom-overlay
