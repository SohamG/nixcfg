{
  pkgs,
  nixpkgs,
  modulesPath,
  config,
  ...
}@inp:

{
  security.ipa = {
    enable = true;

    server = "ipa.sohamg.xyz";
    realm = "SOHAMG.XYZ";
    ipaHostname = "thonker.sohamg.xyz";

    domain = "sohamg.xyz";

    certificate = pkgs.fetchurl {
      url = https://ipa.sohamg.xyz/ipa/config/ca.crt;
      hash = "sha256-D5jRL3fvO4zDSfw69hjX6OHx5cQCxqWakah2rmJTzH4=";
    };

    basedn = "dc=sohamg,dc=xyz";
  };



}
