system: t495/thinkpad.nix
	sudo nixos-rebuild switch --flake .#thonker --impure -j8
	touch system

home: home.nix
	nix run .# -- --flake .#sohamg switch -j 8 -b backup 
	touch home

up: flake-update system home

flake-update:
	nix flake update

yamlmaster: yamlmaster/*
	nixos-rebuild switch --flake .#yamlmaster --target-host "root@yamlmaster.sohamg.xyz" --build-host "root@yamlmaster.sohamg.xyz"
	touch yamlmaster

dell: dell/*
	nixos-rebuild switch --flake .#nixos --target-host "root@0.6.9.6" --build-host "root@0.6.9.6"
	touch dell

.PHONY: up flake-update
