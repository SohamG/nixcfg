{ pkgs, ... }@inp:

{

  services = {
    davfs2.enable = true;
    davfs2.settings = {
      globalSection = {
        cache_size = 500;
        gui_optimize = 1;
        ignore_dav_header = 1;
        use_locks = 1;
        file_refresh = 60;
        dir_refresh = 60;
        buf_size = 256;
      };
    };
  };

  # environment.etc."davfs2/secrets" = {
  #   source = config.age.secrets.davfs.path;
  # };
  systemd.automounts = [
    {
      description = "Stalwart auto";
      where = "/mnt/dav";
      wantedBy = [ "multi-user.target" ];
    }
  ];
  systemd.mounts = [
    {
      wantedBy = [ "multi-user.target" ];
      enable = true;
      description = "Stalwart Dav";
      what = "https://mail.loveyaml.org/dav/file/sohamg";
      where = "/mnt/dav";
      type = "davfs";
      mountConfig = {
        TimeoutSec = "30s";
        Options = "uid=sohamg,gid=users";
      };
    }
  ];

  environment.etc."unison/dav.prf" = {
    enable = true;
    text = ''
    root = home/sohamg/Nextcloud
    root = mnt/dav
    auto = true
    batch = true
    prefer = newer
    repeat = watch
    unicode = true
    '';

  };
  systemd.services.unison = {
    enable = true;
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    unitConfig = {
      RequiresMountsFor="/mnt/dav";
      AssertFileIsNotEmpty="/etc/unison/dav.prf";
    };

    serviceConfig = {
      ExecStart = "${pkgs.unison}/bin/unison dav";
      Environment = "UNISON=/etc/unison";
      ProtectSystem = "full";
      ReadWritePaths="/mnt/dav /home/sohamg/Nextcloud /etc/unison";
      RestrictSUIDSGID = true;
    };
  };


}
