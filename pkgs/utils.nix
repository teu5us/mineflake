{ config, lib, ... }:

{
  fetchIPFS = path: sha256: (
    if config.minecraft.useLocalIPFS then
      builtins.fetchurl {
        url = config.minecraft.localGateway + path;
        sha256 = sha256;
      }
    else
      builtins.fetchurl {
        url = config.minecraft.publicGateway + path;
        sha256 = sha256;
      }
  );
}
