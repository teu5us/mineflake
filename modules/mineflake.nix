{ lib, pkgs, config, ... }:

with lib; let
  cfg = config.minecraft;

  serverSubmodule = types.submodule
    ({ ... }: {
      options = {
        name = mkOption {
          type = types.str;
          description = "Server name.";
        };

        datadir = mkOption {
          type = types.path;
          description = "Server data directory.";
        };

        opts = mkOption {
          type = types.listOf types.str;
          default = [ "nogui" ];
          description = "Server launch options.";
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
      type = types.listOf serverSubmodule;
      description = ''
        List of server submodules to create.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services = builtins.listToAttrs
      (builtins.map
        (server:
          {
            name = "minecraft-prepare-${server.name}";
            value = {
              description = "Prepare for ${server.name} Minecraft server start.";
              restartIfChanged = true;
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = "yes";
                SyslogIdentifier = "minecraft-prepare-${server.name}";
              };
              script = ''
                # Create required directories
                mkdir -p ${server.datadir}
                mkdir -p ${server.datadir}/plugins

                # Accept EULA
                echo "eula=true" > ${server.datadir}/eula.txt

                # Remove old symlinks
                rm -rf ${server.datadir}/plugins/*.jar

                # Link plugins
              '' + builtins.toString (builtins.map
                (plugin: "ln -sf ${plugin}/result ${server.datadir}/plugins/${plugin.pname}-${plugin.version}-${plugin.hash}.jar\n")
                server.plugins);
            };
          })
        cfg.servers) //
    builtins.listToAttrs (builtins.map
      (server:
        {
          name = "minecraft-${server.name}";
          value = {
            description = "Launch ${server.name} Minecraft server.";
            wants = [ "minecraft-prepare-${server.name}.service" "network-online.target" ];
            after = [ "minecraft-prepare-${server.name}.service" "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
            reloadIfChanged = true;
            serviceConfig = {
              Type = "simple";
              SyslogIdentifier = "minecraft-${server.name}";
              WorkingDirectory = server.datadir;
            };
            script = ''
              # Launch
              ${server.jre}/bin/java -jar ${server.package}/result ${builtins.toString (builtins.map (x: "\""+x+"\"") server.opts)}
            '';
          };
        })
      cfg.servers);
  };
}
