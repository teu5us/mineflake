{ lib, pkgs, ... }:

let
  hash = "sha256-IBRMSPaHYpL+DWOrjXaKKWBgd2MzSKxREDYqBcYPS3A=";
  url = "https://ipfs.io/ipfs/bafybeiev6yvkj7zswarulwhid4jyzawssrqjwnts4fvkjhfzpzjlq27odi/luckperms-spigot.tar.gz";
  src = pkgs.fetchzip {
    url = url;
    hash = hash;
  };
in
pkgs.stdenv.mkDerivation {
  inherit hash src;

  pname = "LuckPerms";
  version = "5.4";

  preferLocalBuild = true;

  dontConfigure = true;

  installPhase = ''
    mkdir -p $out/libs
    install -Dm444 $src/LuckPerms-Bukkit-*.jar $out/result
    install -Dm444 $src/libs/*.jar $out/libs
  '';

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
    type = "complex";
    struct = {
      # Libs mapping
      "plugins/LuckPerms/libs/asm-9.1.jar" = "libs/asm-9.1.jar";
      "plugins/LuckPerms/libs/event-3.0.0.jar" = "libs/event-3.0.0.jar";
      "plugins/LuckPerms/libs/okio-1.17.5.jar" = "libs/okio-1.17.5.jar";
      "plugins/LuckPerms/libs/commodore-2.2.jar" = "libs/commodore-2.2.jar";
      "plugins/LuckPerms/libs/okhttp-3.14.9.jar" = "libs/okhttp-3.14.9.jar";
      "plugins/LuckPerms/libs/caffeine-2.9.0.jar" = "libs/caffeine-2.9.0.jar";
      "plugins/LuckPerms/libs/asm-commons-9.1.jar" = "libs/asm-commons-9.1.jar";
      "plugins/LuckPerms/libs/adventure-4.11.0.jar" = "libs/adventure-4.11.0.jar";
      "plugins/LuckPerms/libs/bytebuddy-1.10.22.jar" = "libs/bytebuddy-1.10.22.jar";
      "plugins/LuckPerms/libs/h2-driver-1.4.199.jar" = "libs/h2-driver-1.4.199.jar";
      "plugins/LuckPerms/libs/jar-relocator-1.4.jar" = "libs/jar-relocator-1.4.jar";
      "plugins/LuckPerms/libs/commodore-file-1.0.jar" = "libs/commodore-file-1.0.jar";
      "plugins/LuckPerms/libs/event-3.0.0-remapped.jar" = "libs/event-3.0.0-remapped.jar";
      "plugins/LuckPerms/libs/okio-1.17.5-remapped.jar" = "libs/okio-1.17.5-remapped.jar";
      "plugins/LuckPerms/libs/commodore-2.2-remapped.jar" = "libs/commodore-2.2-remapped.jar";
      "plugins/LuckPerms/libs/okhttp-3.14.9-remapped.jar" = "libs/okhttp-3.14.9-remapped.jar";
      "plugins/LuckPerms/libs/caffeine-2.9.0-remapped.jar" = "libs/caffeine-2.9.0-remapped.jar";
      "plugins/LuckPerms/libs/adventure-4.11.0-remapped.jar" = "libs/adventure-4.11.0-remapped.jar";
      "plugins/LuckPerms/libs/adventure-platform-4.11.2.jar" = "libs/adventure-platform-4.11.2.jar";
      "plugins/LuckPerms/libs/bytebuddy-1.10.22-remapped.jar" = "libs/bytebuddy-1.10.22-remapped.jar";
      "plugins/LuckPerms/libs/commodore-file-1.0-remapped.jar" = "libs/commodore-file-1.0-remapped.jar";
      "plugins/LuckPerms/libs/adventure-platform-bukkit-4.11.2.jar" = "libs/adventure-platform-bukkit-4.11.2.jar";
      "plugins/LuckPerms/libs/adventure-platform-4.11.2-remapped.jar" = "libs/adventure-platform-4.11.2-remapped.jar";
      "plugins/LuckPerms/libs/adventure-platform-bukkit-4.11.2-remapped.jar" = "libs/adventure-platform-bukkit-4.11.2-remapped.jar";
    };
    folders = [
      "plugins/LuckPerms"
      "plugins/LuckPerms/libs"
    ];
  };
}
