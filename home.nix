{config, pkgs, ...}: 
let
  emx = with pkgs;
      ((emacsPackagesFor emacsPgtk).emacsWithPackages
        (epkgs: [ epkgs.vterm ]));
in
{
  home.username = "sohamg";
  home.homeDirectory = "/home/sohamg";
  home.packages = with pkgs; [ zsh emx vim flameshot ];
  home.stateVersion = "22.05";
  programs.home-manager.enable = true;
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  services.emacs.enable = true;
  services.flameshot.enable = true;
  programs.vscode.enable = true;
  programs.vscode.package = pkgs.vscode.fhs;
  programs.emacs.package = emx;
}
