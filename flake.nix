{
  description = "Soham's Personal Nix Config!";

  outputs = { self, nixpkgs }: {

    nixosConfigurations.sg-nix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [ ./configuration.nix ];
    };
  };
}
