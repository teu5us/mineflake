{ pkgs, ... }:

let ipfs = import ../utils.nix {}; in
{
  name = "LuckPerms";
  version = "5.4.41";
  src = ipfs.fetchIPFS "bafybeidiedvh7kgkp3zdn6fdra54glvudkqvr2eohivn6mkbdeedjlvz3y/LuckPerms-Bukkit-5.4.41.jar" "";
}
