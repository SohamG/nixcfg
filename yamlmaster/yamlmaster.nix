# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }@inp:

{
  imports =
    [ # Include the results of the hardware scan.
      ./yamlmaster-hw.nix
      ./rke2-config.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "yamlmaster"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      builders-use-substitutes = true
    '';
    settings.trusted-users = [
      "root"
      "sohamg"
    ];
    settings.sandbox = true;

    gc = {
      automatic = true;
      dates = "weekly";
      persistent = true;
    };

    #  package = pkgs.nixVersions.nix_2_23;
    nixPath = [ "/etc/nix/path" ];
    registry = {
      # nixpkgs.to = {
      #   type = "path";
      #   path = pkgs.path;
      # };
      nixpkgs.to = {
        type = "path";
        path = pkgs.path;
      };
    };
  };

  environment.etc."nix/path/nixpkgs".source = inp.nixpkgs;
  environment.etc."nix/path/nixpkgs-unstable".source = inp.nixpkgs-unstable;

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  age.secrets = {
    nebula-key = {
      file = ../secrets/nebula-yamlmaster-key.age;
      path = "/etc/nebula-host.key";
      owner = "nebula-mesh";
      group = "nebula-mesh";
      mode = "750";
    };

    nebula-crt = {
      file = ../secrets/nebula-yamlmaster-crt.age;
      path = "/etc/nebula-host.crt";
      owner = "nebula-mesh";
      group = "nebula-mesh";
      mode = "750";
    };

    nebula-ca = {
      file = ../secrets/nebula-yamlmaster-ca.age;
      path = "/etc/nebula-ca.crt";
      owner = "nebula-mesh";
      group = "nebula-mesh";
      mode = "750";
    };
  };

  services.nebula.networks.mesh = {
    ca = config.age.secrets.nebula-ca.path;
    cert = config.age.secrets.nebula-crt.path;
    key = config.age.secrets.nebula-key.path;
    package = inp.packages.nebula-nightly;

    settings.pki.initiating_version = 2;
    enable = true;

    settings.punchy = {
      punch = true;
      respond = true;
    };

    settings.relay = {
      relays = [ "0.6.9.3" "0.6.9.1" ];
      use_relays = true;
    };
    firewall.inbound = [
      {
        host = "any";
        port = "any";
        proto = "any";
      }
    ];

    firewall.outbound = [
      {
        host = "any";
        port = "any";
        proto = "any";
      }
    ];

    isLighthouse = false;
    staticHostMap = {
      "0.6.9.3" = [ "teapot.cs.uic.edu:4242" ];
      "0.6.9.1" = [ "sohamg.xyz:4242" ];
    };
    lighthouses = [ "0.6.9.3" "0.6.9.1" ];
  };


  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = false;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = false;
  services.desktopManager.plasma6.enable = false;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = false;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = false;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.user = {
    isNormalUser = true;
    description = "user";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      # kdePackages.kate
    #  thunderbird
      neovim
    ];
  };

  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = false;
  services.xserver.displayManager.autoLogin.user = false;

  # Install firefox.
  programs.firefox.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
    neovim
    bottom
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
