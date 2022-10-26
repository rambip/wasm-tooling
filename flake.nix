{
  description = "my webassembly tooling";

  outputs = { self, nixpkgs }: {
      tools = import ./tools.nix {inherit nixpkgs;};
 };
}
