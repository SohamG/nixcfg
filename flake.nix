{
  description = "Soham's Personal Nix Config!";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs@{ nixpkgs, home-manager, ...}:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./system/configuration.nix
            home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.sohamg = {
                home.username = "sohamg";
                home.homeDirectory = "/home/sohamg";
                home.packages = with pkgs; [
                  zsh
                  emacs
                  vim
                ];
                home.stateVersion = "22.05";
                programs.home-manager.enable = true;
              };
            }
         ];
      };
    };
}
