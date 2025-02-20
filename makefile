system: t495/thinkpad.nix
	sudo nixos-rebuild switch --flake .#thonker --impure -j8
	touch system

home: home.nix
	nix run .# -- --flake .#sohamg switch -j 8 -b backup 
	touch home

up: flake-update system home

flake-update:
	nix flake update

.PHONY: up flake-update
