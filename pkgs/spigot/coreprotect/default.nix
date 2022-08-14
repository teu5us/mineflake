{ lib, pkgs, ... }:

let
  hash = "sha256-BPMbYJ0ePhxT6ZqqBsoQ6mvfUXLJS/WvjM8QiwvEuXc=";
  version = "21.2";
  url = "https://github.com/PlayPro/CoreProtect/releases/download/v${version}/CoreProtect-${version}.jar";
in
pkgs.stdenv.mkDerivation {
  inherit hash version;

  pname = "CoreProtect";
  src = pkgs.fetchurl {
    url = url;
    hash = hash;
  };

  type = "result";

  preferLocalBuild = true;

  dontUnpack = true;
  dontConfigure = true;

  installPhase = ''
    mkdir $out
    install -Dm444 $src $out/result
  '';

  meta = with lib; {
    description = "CoreProtect is a blazing fast data logging and anti-griefing tool for Minecraft servers";
    longDescription = ''
      CoreProtect is a fast, efficient, data logging and anti-griefing tool. Rollback and restore any amount of damage. Designed with large servers in mind, CoreProtect will record and manage data without impacting your server performance.
    '';
    homepage = "https://www.spigotmc.org/resources/coreprotect.8631/";
    # TODO: find artistik license
    license = licenses.mit;
    platforms = platforms.all;
  };
}
