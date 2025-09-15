{ pkgs, ... }@inp:

{

  services = {
    davfs2.enable = true;
    davfs2.settings = {
      globalSection = {
        cache_size = 500;
        gui_optimize = 1;
        use_locks = 0;
        # lock_timeout = 300;
        file_refresh = 60;
        dir_refresh = 60;
        # allow_cookie = 1;
        buf_size = 256;
        debug = "locks";
      };
    };
  };

  # environment.etc."davfs2/secrets" = {
  #   source = config.age.secrets.davfs.path;
  # };
  systemd.automounts = [
    {
      description = "Stalwart automount";
      where = "/mnt/dav";
      wantedBy = [ "multi-user.target" ];
    }
  ];
  systemd.mounts = [
    {
      description = "Stalwart Dav";
      requires = ["network-online.target"];
      what = "https://mail.loveyaml.org/dav/file/sohamg";
      where = "/mnt/dav";
      type = "davfs";
      mountConfig = {
        TimeoutSec = "30s";
        Options = "uid=sohamg,gid=users,rw";
      };
    }
  ];

  environment.etc."unison/dav.prf" = {
    enable = true;
    text = ''
    root = /home/sohamg/Nextcloud
    root = /mnt/dav
    auto = true
    batch = true
    prefer = newer
    repeat = watch+500
    unicode = false
    dontchmod = false
    ignorecase = false
    copyonconflict = true
    ignore = Name .#*
    '';

  };
  systemd.services.unison = {
    enable = true;
    wantedBy = ["multi-user.target"];
    requires = ["mnt-dav.mount"];
    after = ["mnt-dav.mount"];
    unitConfig = {
      BindsTo = ["mnt-dav.mount"];
      RequiresMountsFor="/mnt/dav";
      AssertFileNotEmpty="/etc/unison/dav.prf";
    };

    serviceConfig = {
      User="root";
      Group="root";
      ExecStart = "${pkgs.unison}/bin/unison dav";
      Environment = "UNISON=/etc/unison";
      ProtectSystem = "full";
      ReadWritePaths="/mnt/dav /home/sohamg/Nextcloud /etc/unison";
      RestrictSUIDSGID = true;
    };
  };


}
