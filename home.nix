{config, pkgs, lib, ...}: 
let
  # emx = with pkgs;
  #     ((emacsPackagesFor pkgs.emacs-pgtk).emacsWithPackages
  #       (epkgs: [ epkgs.elpaPackages.vterm ]));
  emx = with pkgs;emacs-pgtk;
in
{
  home.enableNixpkgsReleaseCheck = false;
  home.username = "sohamg";
  home.homeDirectory = "/home/sohamg";
  home.packages = with pkgs; [
    zsh emx neovim
    flameshot
    gnumake coreutils
    iputils bind ripgrep
    chromium
    fira-code fira-code-symbols fira
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
    pandoc file vagrant
    pass-wayland
    roswell
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
  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;
  programs.vscode.package = pkgs.vscode.fhs;
  programs.emacs.package = emx;
  programs.go.enable = true;
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
  # Email

  programs.mbsync.enable = true;
  programs.msmtp.enable = true;
  programs.notmuch = {
    enable = true;
  };
  accounts.email = {
    accounts.gmail = {
      flavor = "gmail.com";
      address = "sohamg2@gmail.com";
      imap.host = "imap.gmail.com";
      mbsync = {
        enable = true;
        create = "maildir";
        extraConfig.channel = {
          MaxMessages = 1000;
          ExpireUnread = "yes";
          # Patterns = "* !allmail !sentmail";
        };
      };
      notmuch.enable = true;
      primary = true;
      realName = "Soham S Gumaste";
      passwordCommand = "pass show emacsemail";
      userName = "sohamg2@gmail.com";
      msmtp.enable = true;
    };
  };

  systemd.user.timers."mailsync" = {
    # enable = true;
    Unit.Description = "Run service to fetch email";
    Install.WantedBy = [ "timers.target" ];
    Install.Wants = ["network.target"];
    Timer.OnCalendar="*-*-* *:30:*";
    Timer.Unit="mailsync.service";
  };

  systemd.user.services."mailsync" = {
    Service.ExecStartPre = "${pkgs.isync}/bin/mbsync -a";
    Service.ExecStart = "${pkgs.mu}/bin/mu index";
  };
}
