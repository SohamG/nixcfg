{config, pkgs, lib, ...}: 
let
  emx = with pkgs;
      ((emacsPackagesFor emacsPgtk).emacsWithPackages
        (epkgs: [ epkgs.vterm ]));
in
{
  home.username = "sohamg";
  home.homeDirectory = "/home/sohamg";
  home.packages = with pkgs; [
    zsh emx neovim
    flameshot
    gnumake coreutils
    iputils bind ripgrep
    chromium
    fira-code fira-code-symbols
    unzip btrfs-progs
    squashfsTools
    qdirstat keepassxc
    unzip intel-gpu-tools
    zotero thunderbird-bin
    partition-manager
    python310
    openssl
    kubectl kubernetes-helm
    traceroute screen
  ];
  # bug
  manual.manpages.enable=false;
  home.stateVersion = "22.05";
  programs.home-manager.enable = true;
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  services.emacs.enable = false;
  services.flameshot.enable = true;
  programs.vscode.enable = true;
  programs.vscode.package = pkgs.vscode.fhs;
  programs.emacs.package = emx;
  systemd.user.services.myemacs = {
    Unit = {
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${emx}/bin/emacs --fg-daemon";
    };

    Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
  };
}
