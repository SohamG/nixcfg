# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, nixpkgs, modulesPath, ... }@inp:

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

  pkgsU = import inp.nixpkgs-unstable {
    system = pkgs.system;
  };
in {
  
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
        # systemd-boot.enable = pkgs.lib.mkForce false;
        systemd-boot.enable = pkgs.lib.mkForce false;
        efi.canTouchEfiVariables = true;
        systemd-boot.configurationLimit = 5;
        systemd-boot.consoleMode = "auto";
    };

    lanzaboote = {
        enable = true;
        pkiBundle = "/etc/secureboot";
    };

    initrd = {
      systemd={
        enable = true;
        enableTpm2 = true;
      };
    };
    # psmouse.proto=bare
    # kernel param to make trackpoint be a mouse.
    # kernelParams = ["psmouse.proto=bare"];
    kernelPackages = pkgsU.linuxPackages;
    extraModulePackages = with pkgsU.linuxPackages; [ v4l2loopback.out digimend.out ];
    kernelModules = [ "v4l2loopback" "snd-loop" "digimend" "kvm-intel" "snd_seq_midi"];
    plymouth.enable = true;
    plymouth.theme = "breeze";
  };

  # Make imperative nixpkgs be same as the flake.

  environment.etc."nix/path/nixpkgs".source = nixpkgs;
  environment.etc."nix/path/nixpkgs-unstable".source = inp.nixpkgs-unstable;

  networking.hostName = "thonker"; # Define your hostname.
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
    tailscale = {
      enable = true;
      useRoutingFeatures="client";
    };
    resolved.enable = true;
    acpid.enable = true;
    # acpid.handlers = {
    #   ac-power = {
    #     event = "ac_adapter/*";
    #     action=''
    #     vals=($1)  # space separated string to array of multiple values
    #     case ''${vals[3]} in
    #         00000000)
    #             echo unplugged >> /tmp/acpi.log
    #             ${pkgs.intel-gpu-tools}/bin/intel_gpu_frequency -m ||
    #             echo "unplug error" >> /tmp/acpi.log &&
    #             echo "set intel gpu freq max"
    #             ;;
    #         00000001)
    #             echo plugged in >> /tmp/acpi.log
    #             ${pkgs.intel-gpu-tools}/bin/intel_gpu_frequency -d ||
    #             echo "unplug error" >> /tmp/acpi.log &&
    #             echo "set intel gpu freq defaults"
    #             ;;
    #         *)
    #             echo unknown >> /tmp/acpi.log
    #             ;;
    #     esac
    #     '';
    #   };
  # };

    keyd = {
      enable = true;
      keyboards.default.settings = {
        main = {
          capslock = "overload(control, control)";
          leftshift = "noop";
        };
      };
    };
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
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;

    # Configure keymap in X11
    xserver.xkb.layout = "us";

    # xkb_keymap {
    #     xkb_keycodes { include "evdev+aliases(qwerty)" };
    #     xkb_types { include "complete" };
    #     xkb_compat { include "complete" };
    #     xkb_symbols {
    #         include "pc+us"
    #         key <LFSH> { [ NoSymbol ] };
    #     };
    #     xkb_geometry { include "pc(pc105)" };
    # };

    xserver.xkb.extraLayouts."noShift" = {
      compatFile = pkgs.writeText "noshift_compat" ''
                 xkb_compat "noShift" { include "complete" };
      '';
      keycodesFile = pkgs.writeText "noshift_keycodes" ''
                 xkb_keycodes "noShift" { include "evdev+aliases(qwerty)" };
      '';
      typesFile = pkgs.writeText "noshift_types" ''
                 xkb_types "noShift" { include "complete" };
      '';
      symbolsFile = pkgs.writeText "noshift_symbols" ''
                 xkb_symbols "noShift" {
                            include "pc+us"
                            key <LFSH> { [ NoSymbol ]};
                 };
      '';
      geometryFile = pkgs.writeText "noshift_compat" ''
                 xkb_geometry "noShift" { include "pc(pc105)" };
      '';
      description = "Disable left shift";
      languages = ["eng"];

    };

    # Enable CUPS to print documents.
    printing.enable = true;

    libinput.enable = true;

    # Enable the OpenSSH daemon.
    openssh.enable = true;
    # openssh.settings.PasswordAuthentication = false;
    # udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    udev.packages = with pkgs; [ yubikey-personalization ];

    # Combat trackpoint drift.
    udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="TPPS/2 Elan TrackPoint", ATTR{device/drift_time}="30"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="01e0", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';
    
    flatpak.enable = true;
    #emacs.enable = true;
    # emacs.defaultEditor = true;
    # emacs.package = emx;

    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = { workstation = true; };
    };

    # https://github.com/linrunner/TLP/issues/436
    tlp.enable = true;
    tlp.settings = {
      RUNTIME_PM_BLACKLIST="06:00.3 06:00.4";
      # CPU Settings
      CPU_SCALING_GOVERNOR_ON_BAT="powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT="power";
  
      # Radeon GPU Settings
      RADEON_POWER_PROFILE_ON_BAT="low";
      RADEON_DPM_PERF_LEVEL_ON_BAT="low";
  
      # Wi-Fi Power Saving
      WIFI_PWR_ON_BAT="5";
  
      # PCIe ASPM
      PCIE_ASPM_ON_BAT="performance";
  
      # USB Autosuspend
      USB_AUTOSUSPEND="1";
  
      # SATA Link Power Management
      SATA_LINKPWR_ON_BAT="min_power";
  
      # Runtime Power Management for PCI Devices
      RUNTIME_PM_ON_BAT="auto";
      RUNTIME_PM_DRIVER_BLACKLIST="amdgpu nouveau nvidia";
  
      # Audio Power Saving
      SOUND_POWER_SAVE_ON_BAT="1";
      # Set CPU frequency to 1.4 GHz (1400000 kHz) on battery
      CPU_MIN_FREQ_ON_BAT="1400000";
      CPU_MAX_FREQ_ON_BAT="1400000";
    };
    power-profiles-daemon.enable = false;

    davfs2.enable = true;
    davfs2.settings = {
      globalSection = {
        cache_size = 500;
        gui_optimize = 1;
        ignore_dav_header = 1;
        use_locks = 0;
        file_refresh = 60;
        dir_refresh = 60;
        buf_size = 256;
      };
    };
    zerotierone = {
      enable = true;
    };
    # fprintd = {
    #   enable = true;
    # };

    guix = {
        enable = true;
        extraArgs = ["--substitute-urls=https://ci.guix.gnu.org https://bordeaux.guix.gnu.org https://substitutes.nonguix.org"];
    };
  }; # services



  # powerManagement.enable = true;
  # Enable sound.
  # sound.enable = true;

  security.rtkit.enable = true;
  security.tpm2 = {
    enable = true;
    abrmd.enable = true;
    pkcs11.enable=true;
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
  };

  # hardware.pulseaudio.enable = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General.Experimental = true;
    };
  };
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
      "qemu-libvirtd "
      "libvirtd"
      "gamemode"
      "tss"
    ]; # Enable ‘sudo’ for the user.
    # Good luck hackers ;)
    hashedPassword =
      "$6$dvC5IljJhXvXqZmW$Rgi..E83VMTLTUNp3CWlwoy1mdU7RdETUCeZOg7SvWdHSnxBnH3vPHenmyqr2wBl42dKFaAj74Hcz1LYvQl9z.";
    packages = with pkgs; [ firefox neovim ];
  };

  users.extraUsers.rclone = {
    isNormalUser = false;
    isSystemUser = true;
    extraGroups = [ "sohamg" ];
    packages = with pkgs; [ rclone vim ];

  };
  users.users.rclone.group = "rclone";
  users.groups.rclone = {};

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    sshfs
    # gnomeExtensions.appindicator
    # gnomeExtensions.gsconnect
    psmisc
    networkmanager-openvpn
    my-nix-switch
    man-pages
    man-pages-posix
    nvidia-offload
    home-manager
    brun
    xdg-desktop-portal-kde
    corefonts
    btrfs-progs
    pinentry-qt
    kwalletcli
    zerotierone
    xwaylandvideobridge
    xorg.xkbcomp
    keyd
    texliveFull
  ] ++ [ pkgsU.sbctl pkgsU.tpm2-tools pkgsU.tpm2-tss ];
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

  programs.steam.enable = true;
  programs.gamemode.enable = true;
  # qt.enable = true;
  # qt.style = "adwaita-dark";
  # qt.platformTheme = "kde";
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    # pinentryFlavor = "qt";
    pinentryPackage = pkgs.pinentry-qt;
    #  enableSSHSupport = true;
    settings={
      default-cache-ttl = 6000;
      max-cache-ttl = 6000;
    };
  };
  programs.kdeconnect.enable = true;
  services.pcscd.enable = true;
  programs.nix-ld.enable = true;
  # List services that you want to enable:
  programs.ssh.startAgent = true;
  programs.ssh.extraConfig = ''
  AddKeysToAgent yes
  EnableSSHKeysign yes
  '';
  virtualisation.docker.enable = false;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  virtualisation.libvirtd.enable = true;
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "sohamg" ];

  # Shell config
  programs.zsh.enable = true;
  users.users.sohamg.shell = pkgs.zsh;
  programs.zsh.autosuggestions.enable = true;
  programs.zsh.syntaxHighlighting.enable = true;
  # programs.zsh.ohMyZsh = {
  #   enable = true;
  #   plugins = [ "git" "man" "fzf" "vi-mode" ];
  #   theme = "candy";
  #   custom = "$HOME/omz/";
  # };
  programs.zsh.shellAliases = { nixre = "sudo nixos-rebuild switch --flake .#thonker --impure"; };

  programs.virt-manager.enable = true;

  # systemd.services.rcloneNextCloud = {
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "network.target" ];
  #   description = "Auto Mount cloud.sohamg.xyz";
  #   enable = true;
  #   serviceConfig = {
  #     User = "rclone";
  #     ExecStartPre = "/run/current-system/sw/bin/mkdir -p /home/rclone/data";
  #     ExecStart = ''${pkgs.rclone}/bin/rclone \
  #     --config="/home/sohamg/.config/rclone/rclone.conf" \
  #     mount vpsnc: /home/rclone/data \
  #     '';
  #     ExecStop = "${pkgs.psmisc}/bin/killall rclone";
  #     Environment = [ "PATH=/run/wrappers/bin/:$PATH" ];
  #   };
  # };
  nixpkgs.config.allowUnfree = true;
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    settings.trusted-users = ["root" "sohamg"];
    settings.sandbox = true;

    package = pkgs.nixVersions.nix_2_23;
    nixPath = [ "/etc/nix/path"];
    registry = {
      # nixpkgs.to = {
      #   type = "path";
      #   path = pkgs.path;
      # };
      nixpkgs.to = {
        type = "path";
        path = "/etc/nix/path/nixpkgs";
      };
    };
  };

  swapDevices = [{
    device = "/swapfile";
    size = 2048;
  }];

  fonts.fontconfig = {
    defaultFonts.serif = [ "DejaVu Serif" "Noto Color Emoji"];
    defaultFonts.sansSerif = [ "DejaVu Sans" "Noto Sans" "Noto Color Emoji"];
  };

  fonts.packages = with pkgs; [ corefonts ];

 environment.etc."davfs2/secrets" = {
  text = "${builtins.readFile "/home/sohamg/nixcfg/t495/davsecret"}";
  mode = "0600";
 };


 security.pam.services = {
   login.u2fAuth = true;
   sudo.u2fAuth = true;
 };

 security.pam.u2f = {
   cue = true;
   enable = true;
   control = "sufficient";
 };

  # systemd.user.timers."filesync" = {
  #   wantedBy = [ "timers.target" ];
  #   wants = ["network.target"];
  #   timerConfig = {
  #     OnCalendar="*-*-* *:*:30";
  #     Unit="filesync.service"
  #   };
  # };

  systemd.mounts = [{
    description = "Nextcloud";
    what = "https://cloud.sohamg.xyz/remote.php/dav/files/sohamg/";
    # what = "root@sohamg.xyz:/sftp"
    where = "/mnt/nextcloud";
    type = "davfs";
    mountConfig = {
      TimeoutSec="30s";
      Options = "uid=sohamg,gid=users";
    };
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
  networking.firewall.enable = true;
  networking.firewall = {
trustedInterfaces = [ "tailscale0" ];
  };
  networking.interfaces.tailscale0.useDHCP = false;
  networking.nftables.enable = true;


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
  system.stateVersion = "23.11"; # Did you read the comment?

}

