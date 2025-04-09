{
  description = "Soham's Personal Nix Config!";

  inputs = {

    # Prefer using github: to prevent hash mismatches.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

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
    inputs@{
      nixpkgs,
      home-manager,
      self,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs =
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
          overlays = [ (import self.inputs.emacs-overlay) ];
        }
        // {
          outPath = inputs.nixpkgs.outPath;
        };
      pkgs-fork = import inputs.fork-nixpkgs {
        inherit system;
      };
    in
    {
      defaultPackage.x86_64-linux = home-manager.packages.x86_64-linux.default;

      packages.x86_64-linux.custom-emacs = pkgs.callPackage ./custom-emacs.nix { };

      # nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      #   inherit system;
      #   modules = [

      #     (import ./dell/configuration.nix {
      #       inherit pkgs;
      #       inherit system;
      #       inherit (inputs) nixpkgs;
      #       inherit (inputs) nixpkgs-unstable;
      #     })
      #   ];
      # };

      nixosConfigurations.thonker = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # inputs.lix-module.nixosModules.default
          inputs.lanzaboote.nixosModules.lanzaboote
          ./t495/thinkpad.nix
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t495
          inputs.agenix.nixosModules.default
          ({
            environment.systemPackages = [
              inputs.agenix.packages.${system}.default
            ];
          })

        ];
        specialArgs = {
          inherit (inputs) nixpkgs-unstable;
          inherit (inputs) nixpkgs;
        };
      };

      nixosConfigurations.yamlmaster = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          ./yamlmaster/yamlmaster.nix
          inputs.agenix.nixosModules.default
          ({
            environment.systemPackages = [
              inputs.agenix.packages.${system}.default
            ];
          })
        ];

        specialArgs = {
          inherit (inputs) nixpkgs-unstable;
          inherit (inputs) nixpkgs;
        };
          
      };
      homeConfigurations."sohamg" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
        extraSpecialArgs = { inherit (inputs) nixpkgs; };
      };
    };
}
