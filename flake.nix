{
  description = "Webassembly tooling";

  inputs = {
      rust-overlay.url = "github:oxalica/rust-overlay";
      naersk.url = "github:nix-community/naersk";
  };

  outputs = { self, nixpkgs, rust-overlay, naersk}: 
  let get-pkgs = system: import nixpkgs {
      overlays = [(import rust-overlay)]; 
      inherit system;
  };

  in rec{ 

    packages.x86_64-linux.wasm-tooling = 
    let pkgs = get-pkgs "x86_64-linux"; in {
        rust = pkgs.callPackage ./rust.nix {naersk-src=naersk;};
    };

    packages.x86_64-darwin.wasm-tooling = 
    let pkgs = get-pkgs "x86_64-darwin"; in {
        rust = pkgs.callPackage ./rust.nix {naersk-src=naersk;};
    };

    devShells."x86_64-linux".rust = packages.x86_64-linux.wasm-tooling.rust.devShell;
  };
}
