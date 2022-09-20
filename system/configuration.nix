# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:

let
  my-nix-switch = pkgs.writeShellScriptBin "my-nix-switch" ''
    sudo nixos-rebuild switch --flake /home/sohamg/nixcfg#
  '';
  emx = with pkgs;
      ((emacsPackagesFor emacsPgtk).emacsWithPackages
        (epkgs: [ epkgs.vterm ]));

  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
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

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  services = {

    # Enable SSD FS Trim for SSD Goodness
    fstrim.enable = true;
    # Enable the X11 windowing system.
    xserver.enable = true;
    xserver.videoDrivers = [ "nvidia" ];

    # Enable the GNOME Desktop Environment.
    xserver.displayManager.gdm.enable = true;
    xserver.desktopManager.gnome.enable = true;

    # Try KDE LOL
    #xserver.displayManager.sddm.enable = true;
    #xserver.desktopManager.plasma5.enable = true;

    # Configure keymap in X11
    xserver.layout = "us";

    # Enable CUPS to print documents.
    printing.enable = true;

    xserver.libinput.enable = true;

    # Enable the OpenSSH daemon.
    openssh.enable = true;
    udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    flatpak.enable = true;
    #emacs.enable = true;
    emacs.defaultEditor = true;
    emacs.package = emx;

    avahi = {
      enable = true;
      nssmdns = true;
      publish = { workstation = true; };
    };

    # tlp.enable = true;
    power-profiles-daemon.enable = true;
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  hardware.nvidia.prime = {
    offload.enable = true;

    intelBusId = "PCI:00:02:0";

    nvidiaBusId = "PCI:01:00:0";
  };

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
    packages = with pkgs; [ firefox neovim emx ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    gnomeExtensions.appindicator
    gnomeExtensions.gsconnect
    rclone
    psmisc
    sqlite
    networkmanager-openvpn
    my-nix-switch

    pkgs.linuxKernel.packages.linux_5_15.v4l2loopback
    nvidia-offload
  ];

  environment.sessionVariables = rec {
    # Firefox wayland
    MOZ_ENABLE_WAYLAND = "1";

    # ZSH Vim Mode
    VI_MODE_SET_CURSOR = "true";

    PATH = [ "\${HOME}/.local/bin" ];
  };
  programs.command-not-found.enable = true;
  qt5.style = "adwaita-dark";
  qt5.platformTheme = "gnome";
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "gtk2";
    #  enableSSHSupport = true;
  };
  programs.kdeconnect.enable = false;
  services.pcscd.enable = true;

  # List services that you want to enable:

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

  systemd.services.rcloneNextCloud = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    description = "Auto Mount cloud.sohamg.xyz";
    enable = true;
    serviceConfig = {
      User = "sohamg";
      # ExecStartPre = "/run/current-system/sw/bin/mkdir /home/sohamg/SyncNext";
      ExecStart =
        "${pkgs.rclone}/bin/rclone mount vpsnc: /home/sohamg/SyncNext";
      ExecStop = "${pkgs.psmisc}/bin/killall rclone";
      Environment = [ "PATH=/run/wrappers/bin/:$PATH" ];
    };
  };
  nixpkgs.config.allowUnfree = true;
  nix = {
    package = pkgs.nixFlakes;
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

