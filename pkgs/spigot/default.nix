{ pkgs, ... }:

with pkgs; {
  # Servers
  paper = callPackage ./servers/paper { };

  # Plugins
  luckperms = callPackage ./plugins/luckperms { };
  coreprotect = callPackage ./plugins/coreprotect { };
}
