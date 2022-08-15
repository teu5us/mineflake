{ lib, pkgs, ... }:

let
  hash = "sha256-ZI9o+WXwtBVXE+hiDDZS8vufIArOdGtVkScq58DJsTg=";
  url = "https://download.luckperms.net/1449/bukkit/loader/LuckPerms-Bukkit-5.4.41.jar";
in
pkgs.stdenv.mkDerivation {
  inherit hash;

  pname = "LuckPerms";
  version = "5.4";
  src = pkgs.fetchurl {
    url = url;
    hash = hash;
  };

  type = "result";

  preferLocalBuild = true;

  dontUnpack = true;
  dontConfigure = true;

  installPhase = "install -Dm444 $src $out";

  meta = with lib; {
    description = "A permissions plugin for Minecraft servers";
    longDescription = ''
      LuckPerms is a permissions plugin for Minecraft servers. It allows server admins to control what features
      players can use by creating groups and assigning permissions.

      It is:
        fast - written with performance and scalability in mind.
        reliable - trusted by thousands of server admins, and the largest of server networks.
        easy to use - setup permissions using commands, directly in config files, or using the web editor.
        flexible - supports a variety of data storage options, and works on lots of different server types.
        extensive - a plethora of customization options and settings which can be changed to suit your server.
        free - available for download and usage at no cost, and permissively licensed so it can remain free forever.
    '';
    homepage = "https://luckperms.net/";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
