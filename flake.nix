{
  description = "Soham's Personal Nix Config!";

  inputs = {
    # Prefer using github: to prevent hash mismatches.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };
  outputs = inputs@{ nixpkgs, home-manager, self, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [ (import self.inputs.emacs-overlay) ];
      } // {
        outPath = inputs.nixpkgs.outPath;
      };
    in {
      defaultPackage.x86_64-linux = home-manager.defaultPackage.x86_64-linux;

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [

          (import ./dell/configuration.nix {
            inherit pkgs;
            inherit system;
            inherit (inputs) nixpkgs;
            inherit (inputs) nixpkgs-unstable;
          })
        ];
      };

      nixosConfigurations.thonker = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          inputs.lanzaboote.nixosModules.lanzaboote
          ./t495/thinkpad.nix
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t495
        ];
        specialArgs = {
          inherit (inputs) nixpkgs-unstable;
          inherit (inputs) nixpkgs;
        };
      };
      homeConfigurations."sohamg" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [./home.nix];
      };
    };
}
