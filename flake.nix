{
  description = "Izaac's custom Nix packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
  in {
    packages = forEachSystem (system: let
      pkgs = mkPkgs system;
    in {
      vcrunch = pkgs.callPackage ./pkgs/vcrunch {};
      zelda-oot = pkgs.callPackage ./pkgs/zelda-oot {};
      ethereal-waves = pkgs.callPackage ./pkgs/ethereal-waves {};
      brush-shell = pkgs.callPackage ./pkgs/brush-shell {};
    });

    overlays.default = final: _prev: {
      izaac-vcrunch = final.callPackage ./pkgs/vcrunch {};
      izaac-zelda-oot = final.callPackage ./pkgs/zelda-oot {};
      izaac-ethereal-waves = final.callPackage ./pkgs/ethereal-waves {};
      izaac-brush-shell = final.callPackage ./pkgs/brush-shell {};
    };
  };
}
