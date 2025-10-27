{ pkgs, ... }:

{
  services.syncthing = {
    enable = true;
    user = "sohamg";
    group = "users";
    dataDir = "/home/sohamg/";
    openDefaultPorts = true;
  };
}
