{ ... }:

{

  home.username = "sohamg";
  home.homeDirectory = "/home/sohamg";

  home.packages = with pkgs; [
    zsh
    emacs
    vim
  ];


  programs.home-manager.enable = true;
}
