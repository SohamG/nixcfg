{
  description = "Soham's Personal Nix Config!";

  inputs = {

    # Prefer using github: to prevent hash mismatches.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-stable.url = "github:nixos/nixpkgs/25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    flake-parts.url = "github:hercules-ci/flake-parts";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # lix-module = {
    #   url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0-1.tar.gz";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      top@{
        config,
        withSystem,
        moduleWithSystem,
        flake-parts-lib,
        ...
      }:
      let
        inherit (flake-parts-lib) importApply;
        # flakeModules.nebula = importApply ./nebulaModule.nix {
        #   localFlake = self;
        # };
      in
      {
        imports = [
          # inputs.home-manager.flakeModules.default
        ];

        systems = [ "x86_64-linux" ];

        perSystem =
          {
            config,
            pkgs,
            self',
            inputs',
            system,
            ...
          }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
              };
              overlays = [ (import inputs.emacs-overlay) ];
            };

            packages = {
              default = inputs'.home-manager.packages.default;
              ghostty = inputs'.ghostty.packages.ghostty;
              nebula-nightly = pkgs.callPackage ./nebula-nightly.nix { };
              custom-emacs = pkgs.callPackage ./custom-emacs.nix { };
            };

          };

        flake.nixosConfigurations.nixos = withSystem "x86_64-linux"
          (ctx@{config, inputs', ... }: inputs.nixpkgs.lib.nixosSystem {
          modules = [
            inputs.agenix.nixosModules.default
            ./dell/configuration.nix
          ];
          specialArgs = {
              inherit (inputs) nixpkgs;
              inherit (inputs) nixpkgs-unstable;
              inherit (config) packages;
          };
            
          });

        flake.nixosConfigurations.thonker = withSystem "x86_64-linux" (
          ctx@{ config, inputs', ... }:
          inputs.nixpkgs.lib.nixosSystem {
            modules = [
              # inputs.lix-module.nixosModules.default
              inputs.determinate.nixosModules.default
              inputs.lanzaboote.nixosModules.lanzaboote
              ./t495/thinkpad.nix
              inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t495
              inputs.agenix.nixosModules.default
              ({
                environment.systemPackages = [
                  inputs'.agenix.packages.default
                ];
              })
            ];
            specialArgs = {
              inherit (inputs) nixpkgs-unstable;
              inherit (inputs) nixpkgs-stable;
              inherit (inputs) nixpkgs;
              inherit (config) packages;
            };
          }
        );

        flake.nixosConfigurations.yamlmaster = withSystem "x86_64-linux" (
          ctx@{ config, inputs', ... }:
          inputs.nixpkgs.lib.nixosSystem {

            modules = [
              ./yamlmaster/yamlmaster.nix
              inputs.agenix.nixosModules.default
              ({
                environment.systemPackages = [
                  inputs'.agenix.packages.default
                ];
                nix.registry.self.flake = ctx.self';
              })
            ];

            specialArgs = {
              inherit (inputs) nixpkgs-unstable;
              inherit (inputs) nixpkgs;
              inherit (config) packages;
            };

          }
        );
        flake.homeConfigurations.sohamg = withSystem "x86_64-linux" (
          ctx@{ config, inputs', self', ... }:
          inputs.home-manager.lib.homeManagerConfiguration {
            inherit (ctx) pkgs;
            modules = [ ./home.nix ];
            extraSpecialArgs = {
              inherit (inputs) nixpkgs;
              packages = config.packages;
            };
          }
        );

        flake.templates.default = {
          path = ./template;
        };
      });
}
