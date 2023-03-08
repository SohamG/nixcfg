#!/usr/bin/env bash

set -xe

nix registry pin nixpkgs github:NixOS/nixpkgs/nixpkgs-unstable

nix flake update

my-nix-switch
