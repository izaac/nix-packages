# Izaac's custom Nix packages
{
  description = "Izaac's custom Nix packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    treefmt-nix,
    ...
  }: let
    systems = ["x86_64-linux"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    treefmtEval =
      forEachSystem (system:
        treefmt-nix.lib.evalModule (mkPkgs system) ./treefmt.nix);
  in {
    packages = forEachSystem (system: let
      pkgs = mkPkgs system;
    in {
      vcrunch = pkgs.callPackage ./pkgs/vcrunch {};
      zelda-oot = pkgs.callPackage ./pkgs/zelda-oot {};
      ethereal-waves = pkgs.callPackage ./pkgs/ethereal-waves {};
      brush-shell = pkgs.callPackage ./pkgs/brush-shell {};
      brave-origin = pkgs.callPackage ./pkgs/brave-origin {};
    });

    formatter =
      forEachSystem (system:
        treefmtEval.${system}.config.build.wrapper);

    checks = forEachSystem (system: {
      formatting = treefmtEval.${system}.config.build.check self;
    });

    overlays.default = final: _prev: {
      izaac-vcrunch = final.callPackage ./pkgs/vcrunch {};
      izaac-zelda-oot = final.callPackage ./pkgs/zelda-oot {};
      izaac-ethereal-waves = final.callPackage ./pkgs/ethereal-waves {};
      izaac-brush-shell = final.callPackage ./pkgs/brush-shell {};
      izaac-brave-origin = final.callPackage ./pkgs/brave-origin {};
    };
  };
}
