{ localFlake }:

{ lib, config, self, inputs }:

{

  perSystem = { pkgs, inputs', self', system }: {
    packages.nebula-nightly = pkgs.callPackage ./nebula-nightly.nix { };
  };

  flake.nixosModules.nebula;

}
