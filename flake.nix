{
  description = "Hyperline for NixOS: custom games for Deadlock, played together";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      # Steam is unfree, and so is Hyperline; allow only those.
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "hyperline"
            "steam"
            "steam-unwrapped"
          ];
      };
    in
    {
      packages.${system}.default = pkgs.callPackage ./package.nix { };

      overlays.default = final: _: { hyperline = final.callPackage ./package.nix { }; };

      nixosModules.default = import ./module.nix { hyperline = ./package.nix; };

      checks.${system}.default = self.packages.${system}.default;

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
