{
  description = "Minecraft server in Nix";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    {
      nixosModules.mineflake = import ./modules/mineflake.nix;
      nixosModule = self.nixosModules.mineflake;
    };
}
