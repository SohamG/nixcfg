{ config, pkgs, ... }@inp:

{

  age.secrets = {
    agent-token = {
      file = ../secrets/rke2-agent-token.age;
    };
  };

  services.rke2 = {
    enable = false;
  };
  services.k3s = {
    enable = true;
    serverAddr = "https://0.6.9.1:6443";
    role = "agent";
    # extraFlags = "--node-external-ip=0.6.9.2";
    tokenFile = config.age.secrets.agent-token.path;
    # nodeName = "yamlmaster";
  };

  # Longhorn has FHS paths
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];

  environment.systemPackages = [ pkgs.nfs-utils ];

  services.openiscsi = {
    enable = true;
    name = "${config.networking.hostName}-initiatorhost";
  };

}
