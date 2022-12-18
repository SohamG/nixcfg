{
  description = "Soham's Personal Nix Config!";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs@{ nixpkgs, home-manager, self, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [ (import self.inputs.emacs-overlay) ];
      };
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (import ./system/configuration.nix {
            inherit pkgs;
            inherit system;
          })
          # home-manager.nixosModules.home-manager
          # {
          #   home-manager.useGlobalPkgs = true;
          #   home-manager.useUserPackages = true;
          #   home-manager.users.sohamg = {
          #     home.username = "sohamg";
          #     home.homeDirectory = "/home/sohamg";
          #     home.packages = with pkgs; [ zsh emacs vim flameshot ];
          #     home.stateVersion = "22.05";
          #     programs.home-manager.enable = true;
          #     programs.direnv.enable = true;
          #     programs.direnv.nix-direnv.enable = true;
          #     services.emacs.enable = true;
          #     services.flameshot.enable = true;
          #     programs.vscode.enable = true;
          #     programs.vscode.package = pkgs.vscode.fhs;
          #   };
          # }
        ];
      };
      homeConfigurations.sohamg = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [./home.nix];
      };
    };
}
