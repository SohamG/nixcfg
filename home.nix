{config, pkgs, lib, packages,...}@inputs: 
let
  optimizeWithFlag = pkg: flag:
  pkg.overrideAttrs (attrs: {
    NIX_CFLAGS_COMPILE = (attrs.NIX_CFLAGS_COMPILE or "") + " ${flag}";
  });
  
  optimizeWithFlags = pkg: flags: pkgs.lib.foldl' (pkg: flag: optimizeWithFlag pkg flag) pkg flags;

  emx-opt = optimizeWithFlags pkgs.emacs-pgtk [ "-O3" "-march=znver1" "-mtune=znver1" "-fPIC" ];
  emx-opt-xwidgets = (emx-opt.override { withXwidgets = true; }).overrideAttrs (old: { buildInputs = old.buildInputs ++ [ pkgs.webkitgtk_4_0 ];});
  custom-emx = packages.custom-emacs;
  emx = with pkgs;
      ((emacsPackagesFor custom-emx).emacsWithPackages
        (epkgs: [ epkgs.vterm epkgs.treesit-grammars.with-all-grammars]));
  # emx = with pkgs;emacs29-pgtk;
in
{
  home.enableNixpkgsReleaseCheck = false;
  home.username = "sohamg";
  home.homeDirectory = "/home/sohamg";
  home.extraOutputsToInstall = [ "doc" "info" "man" ];
  home.packages = with pkgs; [
    zsh emx neovim
    gnumake coreutils
    iputils bind ripgrep
    unzip btrfs-progs
    keepassxc
    openssl
    kubectl kubernetes-helm
    screen
    pandoc file # vagrant
    pass-wayland
    inetutils pciutils dnsutils
    texliveFull mupdf imagemagick
    aspell aspellDicts.en aspellDicts.en-science aspellDicts.en-computers
    yadm konsave restic graphviz via poppler_utils
    noto-fonts-color-emoji zsh-powerlevel10k 
    bottom inter nixfmt-rfc-style nmap rustup wireshark rclone gcc.info
  ] ++ [ packages.ghostty ];
  # bug
  manual.manpages.enable=false;
  home.stateVersion = "22.05";
  programs.home-manager.enable = true;
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  services.emacs.enable = false;
  services.emacs.defaultEditor = true;
  programs.vscode.enable = true;
  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;
  programs.vscode.package = pkgs.vscode.fhs;
  programs.emacs.package = emx;
  programs.go.enable = true;
  home = {
    sessionVariables = {
      RESTIC_REPOSITORY="sftp:rsync.net:restic";
      RESTIC_PASSWORD_FILE="$HOME/restic.key";
      EDITOR="emacsclient -r";
      INFOPATH="$\{HOME}/.local/share/info:$\{INFOPATH}";
    };
    # file.".zshenv" = {
    #   enable = true;
    #   source = config.lib.file.mkOutOfStoreSymlink "/home/sohamg/nix-profile/etc/profile/hm-session-vars.sh";
    #   target = ".zshenv";
    # };
  };
  systemd.user.tmpfiles.rules = [
    "L+ /home/sohamg/.zshenv - - - - /home/sohamg/.nix-profile/etc/profile.d/hm-session-vars.sh"
  ];
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

  # dconf.settings = {
  #   "org/virt-manager/virt-manager/connections" = {
  #     autoconnect = ["qemu:///system"];
  #     uris = ["qemu:///system"];
  #   };
  # };
  

  nix = {
    package = pkgs.nixVersions.latest;
    nixPath = [ "/etc/nix/path"];
  };

}
  # Email

#  programs.mbsync.enable = true;
#  programs.msmtp.enable = true;
#  programs.notmuch = {
#    enable = true;
#  };
#  accounts.email = {
#    accounts.gmail = {
#      flavor = "gmail.com";
#      address = "sohamg2@gmail.com";
#      imap.host = "imap.gmail.com";
#      mbsync = {
#        enable = true;
#        create = "maildir";
#        extraConfig.channel = {
#          MaxMessages = 1000;
#          ExpireUnread = "yes";
#          # Patterns = "* !allmail !sentmail";
#        };
#      };
#      notmuch.enable = true;
#      primary = true;
#      realName = "Soham S Gumaste";
#      passwordCommand = "pass show emacsemail";
#      userName = "sohamg2@gmail.com";
#      msmtp.enable = true;
#    };
#  };

#  systemd.user.timers."mailsync" = {
#    # enable = true;
#    Unit.Description = "Run service to fetch email";
#    Install.WantedBy = [ "timers.target" ];
#    Install.Wants = ["network.target"];
#    Timer.OnCalendar="*-*-* *:30:*";
#    Timer.Unit="mailsync.service";
#  };

#  systemd.user.services."mailsync" = {
#    Service.ExecStartPre = "${pkgs.isync}/bin/mbsync -a";
#    Service.ExecStart = "${pkgs.mu}/bin/mu index";
#  };
