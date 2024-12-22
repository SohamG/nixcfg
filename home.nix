{config, pkgs, lib, ...}@inputs: 
let
  optimizeWithFlag = pkg: flag:
  pkg.overrideAttrs (attrs: {
    NIX_CFLAGS_COMPILE = (attrs.NIX_CFLAGS_COMPILE or "") + " ${flag}";
  });
  
  optimizeWithFlags = pkg: flags: pkgs.lib.foldl' (pkg: flag: optimizeWithFlag pkg flag) pkg flags;

  emx-opt = optimizeWithFlags pkgs.emacs-pgtk [ "-O3" "-march=native" "-mtune=native" "-fPIC" ];
  emx = with pkgs;
      ((emacsPackagesFor emx-opt).emacsWithPackages
        (epkgs: [ epkgs.vterm ]));
  # emx = with pkgs;emacs29-pgtk;
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
    fira fira-code
    unzip btrfs-progs
    squashfsTools
    qdirstat keepassxc
    unzip intel-gpu-tools
    zotero thunderbird-bin
    partition-manager
    python310
    openssl
    kubectl kubernetes-helm
     screen
    pandoc file # vagrant
    pass-wayland
    roswell
    zerotierone
    inetutils pciutils dnsutils
    texliveFull mupdf imagemagick
    aspell aspellDicts.en aspellDicts.en-science aspellDicts.en-computers
    yadm konsave restic graphviz via poppler_utils
    noto-fonts-color-emoji wezterm zsh-powerlevel10k 
  ];
  # bug
  manual.manpages.enable=false;
  home.stateVersion = "22.05";
  programs.home-manager.enable = true;
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  services.emacs.enable = false;
  services.emacs.defaultEditor = true;
  services.flameshot.enable = true;
  programs.vscode.enable = true;
  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;
  programs.vscode.package = pkgs.vscode.fhs;
  programs.emacs.package = emx;
  programs.go.enable = true;
  home.sessionVariables = {
    RESTIC_REPOSITORY="sftp:rsync.net:restic";
    RESTIC_PASSWORD_FILE="$HOME/restic.key";
    EDITOR="emacsclient -r";
  };
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

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };
  

  nix = {
    package = pkgs.nixVersions.nix_2_23;
    nixPath = [ "/etc/nix/path"];
    registry = {
      # nixpkgs.to = {
      #   type = "path";
      #   path = pkgs.path;
      # };
      # nixpkgs.to = {
      #   type = "path";
      #   path = "/etc/nix/path/nixpkgs";
      # };
      nixpkgs.flake=inputs.nixpkgs;
    };
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
