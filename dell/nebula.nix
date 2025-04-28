{ config, pkgs, ... }@inp:
{
  age.secrets = {
    nebula-key = {
      file = ../secrets/nebula-dell-key.age;
      path = "/etc/nebula-host.key";
      owner = "nebula-mesh";
      group = "nebula-mesh";
      mode = "750";
    };

    nebula-crt = {
      file = ../secrets/nebula-dell-crt.age;
      path = "/etc/nebula-host.crt";
      owner = "nebula-mesh";
      group = "nebula-mesh";
      mode = "750";
    };

    nebula-ca = {
      file = ../secrets/nebula-dell-ca.age;
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
}
