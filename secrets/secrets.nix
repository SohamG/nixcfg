let
  thonker = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKTdM+j357oG4+58wUtPp60mo4j0IZ90RUFCQVELJ5YX root@thonker";
  yamlmaster = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOm7cVyjZVTQJZ4dvMWEnKPjOmuBusRfhRGXuHrJgl8E";
in
{
  "nebula-key.age".publicKeys = [ thonker ];
  "nebula-crt.age".publicKeys = [ thonker ];
  "nebula-ca.age".publicKeys = [ thonker ];

  "openvpn-cfg.age".publicKeys = [ thonker ];

  "nebula-yamlmaster-key.age".publicKeys = [ yamlmaster ];
  "nebula-yamlmaster-crt.age".publicKeys = [ yamlmaster ];
  "nebula-yamlmaster-ca.age".publicKeys= [ yamlmaster ];
}
