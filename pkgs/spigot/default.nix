{ pkgs, ... }:

with pkgs; {
  luckperms = callPackage ./luckperms.nix {};
}
