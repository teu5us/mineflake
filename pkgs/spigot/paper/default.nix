{ lib, pkgs, ... }:

let
  mcVersion = "1.18.2";
  buildNum = "313";
  hash = "sha256-wotk0Pu1wKomj83nMCyzzPZ+Y9RkQUbfeWjRGaSt7lE=";
in
pkgs.stdenv.mkDerivation {
  inherit hash;

  pname = "paper";
  version = "${mcVersion}r${buildNum}";
  src = pkgs.fetchurl {
    url = "https://papermc.io/api/v2/projects/paper/versions/${mcVersion}/builds/${buildNum}/downloads/paper-${mcVersion}-${buildNum}.jar";
    hash = hash;
  };

  type = "result";

  preferLocalBuild = true;

  dontUnpack = true;
  dontConfigure = true;

  installPhase = ''
    mkdir -p $out
    install -Dm444 $src $out/result
  '';

  meta = with lib; {
    description = "High-performance Minecraft Server";
    homepage = "https://papermc.io/";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
}
