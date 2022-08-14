{
  description = "Minecraft server in Nix";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    {
      nixosModules.mineflake = import ./modules/mineflake.nix;
      nixosModule = self.nixosModules.mineflake;

      # We do not use nixpkgs overlays for several reasons:
      #   1. They do not have access to the config variable
      #   2. Plugins are specific, you don't need to compile
      #      them yourself, just download the jar and that's it.
      # So we make our own add-on which can solve our problems.
      minepkgs = import ./pkgs;
    };
}
