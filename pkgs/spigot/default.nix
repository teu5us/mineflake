{ pkgs, ... }:

with pkgs; {
  # Servers
  paper = callPackage ./paper { };

  # Plugins
  luckperms = callPackage ./luckperms { };
}
