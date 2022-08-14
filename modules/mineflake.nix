{ lib, pkgs, config, ... }:

with lib; let
  cfg = config.minecraft;

  mkConfigDerivation = name: server-name: option: (
    # TODO: Add different config types handling
    pkgs.stdenv.mkDerivation {
      pname = "minecraft-config-${name}";
      version = server-name;
      phases = [ "installPhase" ];
      installPhase = ''
        cat <<EOF > $out
        ${builtins.toJSON option.data}
        EOF
      '';
    }
  );

  mkConfigs = server: server-name:
    let ders = mapAttrs (name: option: mkConfigDerivation name server-name option) server.configs; in
    (
      toString (map
        (key: ''
          # Link "${key}" config file
          rm -f ${server.datadir}/${key}
          ln -sf ${getAttr key ders} ${server.datadir}/${key}
        '')
        (attrNames ders))
    );

  configSubmodule = types.submodule
    ({ ... }: {
      options = {
        type = mkOption {
          type = types.enum [ "yaml" ];
          default = "yaml";
          description = "Config type.";
        };

        data = mkOption {
          type = types.anything;
          description = "Config contents.";
        };
      };
    }) // {
    description = "Config submodule";
  };

  serverSubmodule = types.submodule
    ({ ... }: {
      options = {
        datadir = mkOption {
          type = types.path;
          # TODO: add default value based on ${name}
          description = "Server data directory.";
        };

        opts = mkOption {
          type = types.listOf types.str;
          default = [ "nogui" ];
          description = "Server launch options.";
        };

        configs = mkOption {
          type = types.attrsOf configSubmodule;
          description = "Config derivations.";
        };

        eula = mkOption {
          type = types.bool;
          default = true;
          description = "Accept minecraft EULA?";
        };

        jre = mkOption {
          type = types.package;
          default = pkgs.jre;
          description = "Java package.";
        };

        plugins = mkOption {
          type = types.listOf types.package;
          description = "Plugins to install.";
        };

        package = mkOption {
          type = types.package;
          default = pkgs.callPackage ../pkgs/spigot/paper { };
          example = "pkgs.spigot.paper";
          description = "Server package.";
        };
      };
    }) // {
    description = "Server submodule";
  };
in
{
  options.minecraft = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If enabled, Nix-defined minecraft servers will be created from minecraft.servers.
      '';
    };

    servers = mkOption {
      type = types.attrsOf serverSubmodule;
      description = ''
        List of server submodules to create.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services =
      let
        obj = builtins.mapAttrs
          (name: server:
            {
              name = "minecraft-${name}";
              value = {
                description = "Launch \"${name}\" mineflake server configuration.";
                wants = [ "network-online.target" ];
                after = [ "network-online.target" ];
                wantedBy = [ "multi-user.target" ];
                restartIfChanged = true;
                serviceConfig = {
                  Type = "simple";
                  SyslogIdentifier = "minecraft-${name}";
                };
                script = ''
                  # Generated by mineflake. Do not edit this file.

                  # Create required directories
                  mkdir -p ${server.datadir}
                  mkdir -p ${server.datadir}/plugins

                  # eula.txt generation
                  if [ ! -f "${server.datadir}/eula.txt" ]; then
                    echo "# Generated by mineflake. Do not edit this file." > "${server.datadir}/eula.txt"
                    echo "eula=${toString server.eula}" >> "${server.datadir}/eula.txt"
                  fi

                  # Remove old plugin symlinks
                  rm -rf "${server.datadir}/plugins/*.jar"

                  ${builtins.toString ( builtins.map (
                    plugin:
                      ''
                        # Link plugin ${plugin.pname} ${plugin.version}
                        ln -sf ${plugin}/result "${server.datadir}/plugins/${plugin.pname}-${plugin.version}-${plugin.hash}.jar"
                      '' + "\n"
                    ) server.plugins)}

                  ${mkConfigs server name}

                  # Launch ${server.package.pname} ${server.package.version}
                  ${server.jre}/bin/java -jar ${server.package}/result ${builtins.toString (builtins.map (x: "\""+x+"\"") server.opts)}
                '';
              };
            })
          cfg.servers;
      in
      builtins.listToAttrs (map (key: getAttr key obj) (attrNames obj));
  };
}
