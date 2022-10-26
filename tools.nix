# to get the exact rust version I want, with wasm enabled
let
    rust-overlay = (import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"));

    change-rust-toolchain = self: super:
        rec {
            rust-custom = self.rust-bin.stable."${super.rustc.version}".minimal.override {
                targets = ["wasm32-unknown-unknown"];
            };
            rustc = rust-custom;
            cargo = rust-custom;
        };

in

{nixpkgs? import <nixpkgs>}: 
    let pkgsWithOverlay = nixpkgs {overlays=[ rust-overlay change-rust-toolchain];}; in with pkgsWithOverlay;
    rec {
        naersk = callPackage (import (builtins.fetchTarball "https://github.com/nix-community/naersk/archive/master.tar.gz")) {};

        # custom version of wasm-bindgen
        wasm-bindgen-cli = naersk.buildPackage {
            src =(pkgsWithOverlay.fetchCrate {
                    pname = "wasm-bindgen-cli";
                    version = "0.2.78";
                    sha256 = "sha256-5s+HidnVfDV0AXA+/YcXNGVjv/E9JeK0Ttng4mCVX8M=";
                    });
            buildInputs = [openssl];
            nativeBuildInputs = [ pkg-config ];
        };

        buildWasmWithTrunk = source: naersk.buildPackage {
            src = source;
            cargoBuild = args: '''';
            copyBins = false;
            postInstall = ''trunk build -d $out'';
            buildInputs = [trunk wasm-bindgen-cli binaryen];
    };
}

