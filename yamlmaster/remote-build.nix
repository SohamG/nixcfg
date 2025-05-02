{ config, pkgs, ...}@inp:

{

  users.users.nix-remote = {
    isNormalUser = true;
    createHome = true;
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPuQlZL9zjEh6dyptYfLQ7AFrlmLP6gINRyLLG/XoLBs sohamg@nixos"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGLVH1pSWWqtQ0gCWuCHYqfvptIK4mp1529PWb6iGmBU remote-nix-builder"
      ];
    };
    group = "nix-remote";
  };

  users.groups.nix-remote = {};
  nix.settings.trusted-users = [ "nix-remote" ];

}
