{
  pkgs,
  nixpkgs,
  modulesPath,
  config,
  ...
}@inp:

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
in
{

  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    #  ./freeipa.nix
    ./dav-sync.nix
  ];

  security.sudo = {
    enable = true;
    extraConfig = ''
      %wheel ALL=(ALL) NOPASSWD: ${pkgs.systemd}/bin/systemctl
    '';
  };

  age.secrets = {
    nebula-key = {
      file = ../secrets/nebula-key.age;
      path = "/etc/nebula-host.key";
      owner = "nebula-mesh";
      group = "nebula-mesh";
      mode = "750";
    };

    nebula-crt = {
      file = ../secrets/nebula-crt.age;
      path = "/etc/nebula-host.crt";
      owner = "nebula-mesh";
      group = "nebula-mesh";
      mode = "750";
    };

    nebula-ca = {
      file = ../secrets/nebula-bundle.age;
      path = "/etc/nebula-ca.crt";
      owner = "nebula-mesh";
      group = "nebula-mesh";
      mode = "750";
    };
    openvpn-cfg = {
      file = ../secrets/openvpn-cfg.age;
      owner = "root";
      group = "root";
      mode = "750";
    };
  };

  specialisation."default-kernel" = {
    inheritParentConfig = true;
    configuration = {
      environment.etc."specialisation".text = "default-kernel";
      system.nixos.tags = [ "default-kernel" ];
      boot = {
        kernelPackages = pkgs.lib.mkForce pkgs.linuxKernel.packages.linux_6_12;
      };
    };
  };

  systemd.services.nebula-dns = {
    enable = true;
    script = ''
      resolvectl domain nebula.mesh ~sohamg.xyz
      resolvectl dns nebula.mesh 0.6.9.2
    '';
    after = [ "nebula@mesh.service" ];
    description = "Set domain and DNS with resolved for nebula";
  };

  services.nebula.networks.mesh = {

    enable = true;
    # TODO Use agenix
    package = inp.packages.nebula-nightly;

    ca = config.age.secrets.nebula-ca.path;
    cert = config.age.secrets.nebula-crt.path;
    key = config.age.secrets.nebula-key.path;

    settings.listen.host = "[::]";

    settings.handshakes = {
      retries = 20;
      try_interval=150;
    };

    relays = [ "0.6.9.2" "0.6.9.1" ];

    settings.pki.initiating_version = 2;
    settings.punchy = {
      punch = true;
      respond = true;
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
      # "0.6.9.3" = [ "teapot.cs.uic.edu:4242" ];
      "0.6.9.1" = [ "sohamg.xyz:4242" ];
     # "0.6.9.7" = [ "131.193.48.56:4242" ];
      "fd8c:5016:9b22::1" = [ "sohamg.xyz:4242" ];
    };
    lighthouses = [
      # "0.6.9.3"
      "0.6.9.1"
    ];
  };

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
      systemd = {
        enable = true;
        package = pkgs.systemd.override { withTpm2Tss = true; };
        tpm2 = {
          enable = true;
        };
      };
    };

    # psmouse.proto=bare
    # kernel param to make trackpoint be a mouse.
    # kernelParams = ["psmouse.proto=bare"];
    kernelPackages = pkgs.lib.mkDefault pkgs.linuxKernel.packages.linux_xanmod_latest;
    extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback.out
      # digimend.out # Digimend is unmaintained.
    ];
    kernelModules = [
      "v4l2loopback"
      "snd-loop" # "digimend"
      "kvm-intel"
      "snd_seq_midi"
    ];
    plymouth.enable = true;
    plymouth.theme = "breeze";
  }; # boot

  # Make imperative nixpkgs be same as the flake.

  environment.etc."nix/path/nixpkgs".source = inp.nixpkgs-stable;
  environment.etc."nix/path/nixpkgs-unstable".source = inp.nixpkgs-unstable;

  networking.hostName = "thonker";
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };

  # Set your time zone.
  # time.timeZone = "America/Chicago";
  # time.timeZone = "Asia/Kolkata";
  # time.timeZone = "America/New_
  time.timeZone = pkgs.lib.mkForce null; 

  services.automatic-timezoned.enable = true;


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

  security.krb5 = {
    enable = true;
    settings = {
      libdefaults = {
        dns_lookup_kdc = true;
        dns_lookup_realm = true;
        default_realm = "SOHAMG.XYZ";
      };
      realms = {
        "SOHAMG.XYZ" = {
          admin_server = "ipa.sohamg.xyz";
          default_domain = "sohamg.xyz";
        };
      };
    };
  };

  xdg.portal.enable = true;
  xdg.portal.wlr.enable = false;
  xdg.portal.extraPortals = with pkgs; [ kdePackages.xdg-desktop-portal-kde ];
  hardware.amdgpu.opencl.enable = true;
  services = {
    openvpn.servers."ACM" = {
      config = "config ${config.age.secrets.openvpn-cfg.path}";
      autoStart = true;
      updateResolvConf = false;
      up = ''
        resolvectl dns tun0 $nameserver
        resolvectl domain tun0 ~$domain
      '';
      down = ''
        resolvectl reset tun0
      '';

    };

    openvpn.restartAfterSleep = true;
    fwupd.enable = true;
    gvfs.enable = true;
    tailscale = {
      enable = false;
      useRoutingFeatures = "client";
    };
    ollama = {
      enable = false;
      acceleration = "rocm";
      environmentVariables = {
        HCC_AMDGPU_TARGET = "amdgcn-amd-amdhsa--gfx902:xnack+"; # used to be necessary, but doesn't seem to anymore
      };
    };

    # Run a local dns resolver because the default linux/glibc resolver
    # ie /etc/resolv.conf is actually bad. So point it at the stub resolver
    # which does the actual resolving.
    # Try to resolve nebula hostnames before trying to go out into the internet.
    # ResolveUnicastSinglelabel allows DNS-ing undotted single words.
    resolved = {
      enable = true;
      dnssec = "allow-downgrade";
      extraConfig = ''
        DNS=0.6.9.1:53%nebula.mesh 0.6.9.3:53%nebula.mesh
        Cache=no-negative
        DNSSEC=false
        ResolveUnicastSingleLabel=true
      '';
    };
    acpid.enable = false;
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
      enable = false;
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
    xserver.enable = false;

    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;

    # Configure keymap in X11
    xserver.xkb.layout = "us";

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
      publish = {
        workstation = true;
        addresses = true;
      };
    };

    # https://github.com/linrunner/TLP/issues/436
    tlp.enable = false;
    tlp.settings = {
      RUNTIME_PM_BLACKLIST = "06:00.3 06:00.4";
      # CPU Settings
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Set CPU frequency to 1.4 GHz (1400000 kHz) on battery
      CPU_MIN_FREQ_ON_BAT = "1400000";
      CPU_MAX_FREQ_ON_BAT = "1400000";
    };
    power-profiles-daemon.enable = true;

    zerotierone = {
      enable = false;
    };
    # fprintd = {
    #   enable = true;
    # };

    guix = {
      enable = false;
      extraArgs = [
        "--substitute-urls=https://ci.guix.gnu.org https://bordeaux.guix.gnu.org https://substitutes.nonguix.org"
      ];
    };
  }; # services

  security.rtkit.enable = true;
  security.tpm2 = {
    enable = true;
    abrmd.enable = true;
    pkcs11.enable = true;
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General.Experimental = true;
    };
  };

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
      "incus-admin"
    ];
    # Good luck hackers ;)
    hashedPassword = "$6$dvC5IljJhXvXqZmW$Rgi..E83VMTLTUNp3CWlwoy1mdU7RdETUCeZOg7SvWdHSnxBnH3vPHenmyqr2wBl42dKFaAj74Hcz1LYvQl9z.";
    packages = with pkgs; [
      firefox
      neovim
    ];
    subUidRanges = [
      {
        count = 65536;
        startUid = 100000;
      }
      {
        count = 65536;
        startUid = 200000;
      }
    ];
    subGidRanges = [
      {
        count = 65536;
        startGid = 100000;
      }
      {
        count = 65536;
        startGid = 200000;
      }
    ];
  };

  users.users.root = {
    subUidRanges = [
      {
        count = 1;
        startUid = 200000;
      }
    ];
    subGidRanges = [
      {
        count = 1;
        startGid = 200000;
      }
    ];
  };

  users.extraUsers.rclone = {
    isNormalUser = false;
    isSystemUser = true;
    extraGroups = [ "sohamg" ];
    packages = with pkgs; [
      rclone
      vim
    ];

  };
  users.users.rclone.group = "rclone";
  users.groups.rclone = { };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  documentation.doc.enable = true;
  documentation.info.enable = true;
  documentation.nixos.enable = true;
  environment.extraOutputsToInstall = [
    "doc"
    "info"
  ];
  environment.systemPackages =
    with pkgs;
    [
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
      kdePackages.xdg-desktop-portal-kde
      corefonts
      btrfs-progs
      pinentry-qt
      kwalletcli
      #zerotierone
      kdePackages.xwaylandvideobridge
      xorg.xkbcomp
      keyd
      texliveFull
      inp.packages.nebula-nightly
      kdePackages.krfb
    ]
    ++ [
      pkgsU.sbctl
      pkgsU.tpm2-tools
      pkgsU.tpm2-tss
    ];
  documentation.dev.enable = true;
  environment.sessionVariables = rec {
    # Firefox wayland
    MOZ_ENABLE_WAYLAND = "1";

    # ZSH Vim Mode
    VI_MODE_SET_CURSOR = "true";

    PATH = [
      "\${HOME}/.local/bin"
      "/var/lib/flatpak/exports/bin"
      "~/.local/share/flatpak/exports/bin"
    ];

    XDG_DATA_DIRS = [
      "/var/lib/flatpak/exports/share"
      "/home/sohamg/.local/share/flatpak/exports/share"
    ];
  };
  programs.nh = {
    enable = true;
  };
  programs.command-not-found.enable = true;
  programs.mosh.enable = true;
  programs.ccache.enable = true;
  programs.thunderbird.enable = true;
  # programs.ryzen-ppd = {
  #   package = inp.pkgs-fork.ryzen-ppd;
  #   enable = true;
  # };
  hardware.cpu.amd.ryzen-smu.enable = true;
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
    settings = {
      default-cache-ttl = 6000;
      max-cache-ttl = 6000;
    };
  };
  programs.kdeconnect.enable = true;
  services.pcscd.enable = true;
  programs.nix-ld.enable = true;
  # List services that you want to enable:
  programs.ssh.startAgent = true;
  programs.ssh.package = pkgs.openssh_gssapi;
  programs.ssh.extraConfig = ''
    AddKeysToAgent yes
    EnableSSHKeysign yes
  '';
  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = [ "sohamg" ];

  virtualisation.lxc = {
    lxcfs.enable = false;
    enable = true;
    # systemConfig = ''
    # lxc.id_map = u 0 100000 65536
    # lxc.id_map = g 0 100000 65536
    # lxc.network.type = veth
    # lxc.network.link = lxcbr0
    # lxc.network.flags = up
    # lxc.network.hwaddr = 00:16:3e:xx:xx:xx
    # '';

    # lxc.net.0.veth.mode = bridge
    # lxc.net.0.link = lxcbr0
    # lxc.net.0.flags = up
    defaultConfig = ''
      lxc.include = ${pkgs.lxcfs}/share/lxc/config/common.conf.d/00-lxcfs.conf
      lxc.net.0.type = none
    '';
    usernetConfig = ''
      sohamg veth lxcbr0 1000
    '';
  };
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    extraPackages = with pkgs; [
      netavark
      aardvark-dns
    ];
  };
  # virtualisation.tpm.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.swtpm.enable = true;
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "sohamg" ];

  # Shell config
  programs.zsh.enable = true;
  users.users.sohamg.shell = pkgs.zsh;
  programs.zsh.autosuggestions.enable = true;
  programs.zsh.syntaxHighlighting.enable = true;
  programs.zsh.shellAliases = {
    nixre = "sudo nixos-rebuild switch --flake .#thonker --impure";
  };

  programs.virt-manager.enable = true;

  systemd.user.services.gvfsd = {
    description = "Gvfs";
    partOf = [ "graphical-session.target" ]; # Ensure the service starts after graphical target is active.
    serviceConfig = {
      ExecStart = "${pkgs.gvfs}/libexec/gvfsd"; # Replace with the command to start your service.
      Restart = "always"; # Restart policy (optional).
      Type = "dbus";
      BusName = "org.gtk.vfs.Daemon";
      Slice = "session.slice";
    };
  };

  nixpkgs.config.allowUnfree = true;
  # environment.etc."nix/nix.custom.conf" = {
  #   enable = true;
  #   text = ''
  #     builders-use-substitutes = true
  #     lazy-trees = true
  #     trusted-users = [ "sohamg" "root" ]
  #   '';
  # };
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

    package = pkgs.lix;
    nixPath = [ "/etc/nix/path" ];
    registry = {
      # nixpkgs.flake = inp.nixpkgs;
      nixpkgs.to = {
        type = "github";
        owner = "nixos";
        repo = "nixpkgs";
        ref = "25.05";
      };

      # nixpkgs.to = {
      #   type = "path";
      #   path = "/etc/nix/path/nixpkgs";
      # };
    };
    buildMachines = [
      {
        hostName = "yamlnix";
        system = "x86_64-linux";
        protocol = "ssh-ng";
        # if the builder supports building for multiple architectures,
        # replace the previous line by, e.g.
        # systems = ["x86_64-linux" "aarch64-linux"];
        maxJobs = 16;
        # speedFactor = 2;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        mandatoryFeatures = [ ];
      }
    ];
    distributedBuilds = true;
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  fonts.fontconfig = {
    defaultFonts.serif = [
      "DejaVu Serif"
      "Noto Color Emoji"
    ];
    defaultFonts.sansSerif = [
      "DejaVu Sans"
      "Noto Sans"
      "Noto Color Emoji"
    ];
  };

  fonts.packages = with pkgs; [ corefonts ];


  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
    # Fix run0
    systemd-run0 = { };
  };

  security.pam.u2f = {
    settings.cue = true;
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


  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
    enableRootSlice = true;
  };
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 8080 ];
  networking.firewall.allowedUDPPorts = [ 8080 ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;
  networking.firewall = {
    trustedInterfaces = [ "nebula.mesh" ];
  };
  networking.nftables.enable = true;

  # networking.networkmanager.insertNameservers = [ "192.168.0.100" ];

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
