{ lib, fetchurl, stdenv, ... }:

let
  mcVersion = "1.18.2";
  buildNum = "313";
  hash = "sha256-wotk0Pu1wKomj83nMCyzzPZ+Y9RkQUbfeWjRGaSt7lE=";
  mojang_dep = fetchurl {
    url = "https://ipfs.io/ipfs/bafybeidd64amhqeqkrtm6udjyhlu7lero7fakzeunqha7oywwibeogluqq/mojang_1.18.2.jar";
    hash = "sha256-V76dHjWqkc/fokattjoOoRqUYIHgRk0IvD02ZRcYo0M=";
  };
in
stdenv.mkDerivation {
  inherit hash;

  pname = "paper";
  version = "${mcVersion}r${buildNum}";
  src = fetchurl {
    url = "https://papermc.io/api/v2/projects/paper/versions/${mcVersion}/builds/${buildNum}/downloads/paper-${mcVersion}-${buildNum}.jar";
    hash = hash;
  };

  preferLocalBuild = true;

  dontUnpack = true;
  dontConfigure = true;

  installPhase = ''
    mkdir -p $out
    install -Dm444 $src $out/result
    install -Dm444 ${mojang_dep} $out/mojang.jar
  '';

  meta = with lib; {
    description = "High-performance Minecraft Server";
    homepage = "https://papermc.io/";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
    type = "complex";
    struct = {
      "cache/mojang_1.18.2.jar" = "mojang.jar";
    };
    folders = [
      "cache"
    ];
  };
}
