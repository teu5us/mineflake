{ pkgs, ... }:

with pkgs; {
  # Servers
  paper = callPackage ./paper { };

  # Plugins
  # TODO: add to plugins default config declarations
  luckperms = callPackage ./luckperms { };
  coreprotect = callPackage ./coreprotect { };
}
