let
  thonker = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKTdM+j357oG4+58wUtPp60mo4j0IZ90RUFCQVELJ5YX root@thonker";
  yamlmaster = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOm7cVyjZVTQJZ4dvMWEnKPjOmuBusRfhRGXuHrJgl8E";
  dell = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIASvTlzNvyCWTbt35aygUtACDjQtMNb5GmErfom4C+32";
in
{
  "nebula-key.age".publicKeys = [ thonker ];
  "nebula-crt.age".publicKeys = [ thonker ];
  "nebula-ca.age".publicKeys = [ thonker ];

  "openvpn-cfg.age".publicKeys = [ thonker ];

  "rke2-agent-token.age".publicKeys = [ yamlmaster ];

  "nebula-dell-key.age".publicKeys = [ dell ];
  "nebula-dell-crt.age".publicKeys = [ dell ];
  "nebula-dell-ca.age".publicKeys= [ dell ];
}
