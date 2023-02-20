# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:

let
  my-nix-switch = pkgs.writeShellScriptBin "my-nix-switch" ''
    sudo nixos-rebuild switch --flake /home/sohamg/nixcfg# --impure -j6
  '';
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';

  brun = pkgs.writeShellScriptBin "brun" ''
       ${pkgs.bemenu}/bin/bemenu-run -i -l 10

  '';

  runriver = pkgs.writeShellScriptBin "runriver" ''
           XDG_CURRENT_DESKTOP=sway
           XKB_DEFAULT_OPTIONS=ctrl:nocaps dbus-run-session ${pkgs.river}/bin/river
  '';
in {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];
  
  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        systemd-boot.configurationLimit = 5;
        systemd-boot.consoleMode = "auto";
    };
    kernelPackages = pkgs.linuxPackages;
    extraModulePackages = with pkgs.linuxPackages; [ v4l2loopback.out digimend.out];
    kernelModules = [ "v4l2loopback" "snd-loop" "digimend" ];
    plymouth.enable = true;
    plymouth.theme = "breeze";
  };


  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable =
    true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/Chicago";
  # time.timeZone = "Asia/Kolkata";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tt.
  # };

  xdg.portal.enable = true;
  xdg.portal.wlr.enable = true;
  xdg.portal.extraPortals = with pkgs; [xdg-desktop-portal-kde];

  services = {

    # Enable SSD FS Trim for SSD Goodness
    fstrim.enable = true;
    # Enable the X11 windowing system.
    xserver.enable = true;
    # xserver.videoDrivers = [ "nvidia" ];
    xserver.digimend.enable = true;
    # greetd.enable = true;
    # greetd.settings = {
    #   default_session = {
    #     command = "${pkgs.greetd.greetd}/bin/agreety --cmd runriver";
    #   };
    # };
    # Enable the GNOME Desktop Environment.
    # xserver.displayManager.gdm.enable = true;
    # xserver.desktopManager.gnome.enable = true;
    # Try KDE LOL
    xserver.displayManager.sddm.enable = true;
    xserver.desktopManager.plasma5.enable = true;

    # Configure keymap in X11
    xserver.layout = "us";

    # Enable CUPS to print documents.
    printing.enable = true;

    xserver.libinput.enable = true;

    # Enable the OpenSSH daemon.
    openssh.enable = true;
    openssh.settings.PasswordAuthentication = false;
    # udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    flatpak.enable = true;
    #emacs.enable = true;
    emacs.defaultEditor = true;
    # emacs.package = emx;

    avahi = {
      enable = true;
      nssmdns = true;
      publish = { workstation = true; };
    };

    # tlp.enable = true;
    power-profiles-daemon.enable = true;

    davfs2.enable = true;
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # hardware.nvidia.prime = {
  #   offload.enable = true;

  #   intelBusId = "PCI:00:02:0";

  #   nvidiaBusId = "PCI:01:00:0";
  # };

  # Enable touchpad support (enabled default in most desktopManager).

  # Define a user account. Don't forget to set a password with ‘passwd’.

  ####################
  # IMPORTANT ########
  ####################
  # Imperative user management is off, so is `passwd`
  users.mutableUsers = false;

  users.users.sohamg = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "users"
      "audio"
      "video"
      "uucp"
      "docker"
      "networkmanager"
      "dialout"
    ]; # Enable ‘sudo’ for the user.
    # Good luck hackers ;)
    hashedPassword =
      "$6$dvC5IljJhXvXqZmW$Rgi..E83VMTLTUNp3CWlwoy1mdU7RdETUCeZOg7SvWdHSnxBnH3vPHenmyqr2wBl42dKFaAj74Hcz1LYvQl9z.";
    packages = with pkgs; [ firefox neovim ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    # gnomeExtensions.appindicator
    # gnomeExtensions.gsconnect
    rclone
    psmisc
    sqlite
    networkmanager-openvpn
    my-nix-switch
    man-pages
    man-pages-posix
    nvidia-offload
    river
    runriver
    home-manager
    brun
    xdg-desktop-portal-wlr
    xdg-desktop-portal-kde
    corefonts
  ];
  documentation.dev.enable = true;
  environment.sessionVariables = rec {
    # Firefox wayland
    MOZ_ENABLE_WAYLAND = "1";

    # ZSH Vim Mode
    VI_MODE_SET_CURSOR = "true";

    PATH = [ "\${HOME}/.local/bin" "/var/lib/flatpak/exports/bin" "~/.local/share/flatpak/exports/bin"];

    XDG_DATA_DIRS = [ "/var/lib/flatpak/exports/share" "/home/sohamg/.local/share/flatpak/exports/share"];
  };
  programs.command-not-found.enable = true;
  qt.enable = true;
  qt.style = "adwaita-dark";
  qt.platformTheme = "kde";
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "qt";
    #  enableSSHSupport = true;
  };
  programs.kdeconnect.enable = true;
  services.pcscd.enable = true;
  programs.nix-ld.enable = true;
  # List services that you want to enable:
  programs.ssh.startAgent = true;
  virtualisation.docker.enable = true;
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "sohamg" ];

  # Shell config
  programs.zsh.enable = true;
  users.users.sohamg.shell = pkgs.zsh;
  programs.zsh.autosuggestions.enable = true;
  programs.zsh.syntaxHighlighting.enable = true;
  programs.zsh.ohMyZsh = {
    enable = true;
    plugins = [ "git" "man" "fzf" "vi-mode" ];
    theme = "agnoster";
    custom = "~/omz/";
  };
  programs.zsh.shellAliases = { nixre = "sudo nixos-rebuild switch"; };

  # systemd.services.rcloneNextCloud = {
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "network.target" ];
  #   description = "Auto Mount cloud.sohamg.xyz";
  #   enable = true;
  #   serviceConfig = {
  #     User = "sohamg";
  #     # ExecStartPre = "/run/current-system/sw/bin/mkdir /home/sohamg/SyncNext";
  #     ExecStart =
  #       "${pkgs.rclone}/bin/rclone mount vpsnc: /home/sohamg/SyncNext";
  #     ExecStop = "${pkgs.psmisc}/bin/killall rclone";
  #     Environment = [ "PATH=/run/wrappers/bin/:$PATH" ];
  #   };
  # };
  nixpkgs.config.allowUnfree = true;
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    settings.trusted-users = ["root" "sohamg"];
    settings.sandbox = true;
  };

  swapDevices = [{
    device = "/swapfile";
    size = 2048;
  }];

  fonts.fontconfig = {
    defaultFonts.serif = [ "DejaVu Serif" "Noto Color Emoji"];
    defaultFonts.sansSerif = [ "DejaVu Sans" "Noto Sans" "Noto Color Emoji"];
  };

  fonts.fonts = with pkgs; [ corefonts ];

  environment.etc."davfs2/secrets" = {
    text = "${builtins.readFile "/home/sohamg/nixcfg/system/davsecret"}";
    mode = "0600";
  };

  systemd.mounts = [{
    description = "Nextcloud";
    what = "https://cloud.sohamg.xyz/remote.php/dav/files/sohamg/";
    where = "/mnt/nextcloud";
    options = "noauto,user,uid=sohamg,gid=sohamg";
    type = "davfs";
  }];

  systemd.automounts = [{
    description = "Nextcloud auto";
    where = "/mnt/nextcloud";
    wantedBy = ["multi-user.target"];
  }];
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}

