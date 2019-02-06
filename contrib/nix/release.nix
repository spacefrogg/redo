{ nixpkgsSrc ? import <nixpkgs> }:

let
  pkgs = nixpkgsSrc {};

in pkgs.callPackage ./default.nix { doCheck = true; }
