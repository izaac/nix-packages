# Izaac's custom Nix packages
{
  description = "Izaac's custom Nix packages";

  nixConfig = {
    extra-substituters = ["https://izaac-nix.cachix.org"];
    extra-trusted-public-keys = [
      "izaac-nix.cachix.org-1:ff3lZcS/eWO6i3+BXAds6MbSnEzDe2HMWvTY2bcoXDk="
    ];
  };

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
    inherit (nixpkgs) lib;
    systems = ["x86_64-linux" "aarch64-darwin"];
    forEachSystem = lib.genAttrs systems;
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
      linuxOnly = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        vcrunch = pkgs.callPackage ./pkgs/vcrunch {};
        zelda-oot = pkgs.callPackage ./pkgs/zelda-oot {};
        brush-shell = pkgs.callPackage ./pkgs/brush-shell {};
        brave-origin = pkgs.callPackage ./pkgs/brave-origin {};
        flashgbx = pkgs.callPackage ./pkgs/flashgbx {};
      };
    in
      linuxOnly
      // {
        antigravity-cli = pkgs.callPackage ./pkgs/antigravity-cli {};
        proton-drive-cli = pkgs.callPackage ./pkgs/proton-drive-cli {};
      });

    formatter =
      forEachSystem (system:
        treefmtEval.${system}.config.build.wrapper);

    checks = forEachSystem (system: {
      formatting = treefmtEval.${system}.config.build.check self;
    });

    overlays.default = final: _prev: let
      linuxOnly = lib.optionalAttrs final.stdenv.hostPlatform.isLinux {
        izaac-vcrunch = final.callPackage ./pkgs/vcrunch {};
        izaac-zelda-oot = final.callPackage ./pkgs/zelda-oot {};
        izaac-brush-shell = final.callPackage ./pkgs/brush-shell {};
        izaac-brave-origin = final.callPackage ./pkgs/brave-origin {};
        izaac-flashgbx = final.callPackage ./pkgs/flashgbx {};
      };
    in
      linuxOnly
      // {
        izaac-antigravity-cli = final.callPackage ./pkgs/antigravity-cli {};
        izaac-proton-drive-cli = final.callPackage ./pkgs/proton-drive-cli {};
      };
  };
}
