{ lib
, pkgs
, config
, ...
}:

with lib; let

  utils = import ./utils.nix { inherit lib; };
  properties = import ./properties.nix { inherit lib; };

  cfg = config.minecraft;

  spigot = pkgs.callPackage ../pkgs/spigot { };

  eula-file = utils.mkConfigFile {
    type = "raw";
    data = {
      raw = "eula=true";
    };
  };

  # OPTIONS
  permissionNode = types.submodule
    ({ ... }: {
      options = {
        server = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
      };
    }) // {
    description = "Permission node context";
  };

  permissionGroup = types.attrsOf permissionNode;
in
{
  options.minecraft = {
    enable = mkEnableOption "If enabled, Nix-defined minecraft servers will be created from minecraft.servers.";

    servers = mkOption {
      type = types.attrsOf (types.submodule
        ({ name, ... }: {
          options = {
            datadir = mkOption {
              type = types.path;
              default = "/var/lib/minecraft";
              description = "Server data directory.";
            };

            opts = mkOption {
              type = types.listOf types.str;
              default = [ "nogui" ];
              description = "Server launch options.";
            };

            configs = mkOption {
              type = types.attrsOf (types.submodule
                ({ ... }: {
                  options = {
                    type = mkOption {
                      type = types.enum [ "yaml" "json" "raw" ];
                      default = "yaml";
                      description = "Config type.";
                    };

                    data = mkOption {
                      type = types.anything;
                      description = "Config contents.";
                    };
                  };
                }));
              default = { };
              description = "Config derivations.";
            };

            permissions = mkOption {
              type = (types.submodule
                ({ ... }: {
                  options = {
                    enable = mkEnableOption "If enabled, Nix-defined minecraft servers will be created from minecraft.servers.";

                    groups = mkOption {
                      type = types.attrsOf permissionGroup;
                    };

                    users = mkOption {
                      type = types.attrsOf permissionGroup;
                    };

                    package = mkOption {
                      type = types.package;
                      default = spigot.luckperms;
                      example = "pkgs.spigot.luckperms";
                      description = "Plugin package.";
                    };
                  };
                }));
              default = { };
              description = "Permissions (LP) settings.";
            };

            properties = mkOption {
              type = properties.submodule;
              default = { };
              description = "Server settings.";
            };

            jre = mkOption {
              type = types.package;
              default = pkgs.jre;
              description = "Java package.";
            };

            plugins = mkOption {
              type = types.listOf types.package;
              default = [ ];
              description = "Plugins to install.";
            };

            package = mkOption {
              type = types.package;
              default = spigot.paper;
              example = "pkgs.spigot.paper";
              description = "Server package.";
            };
          };
        }));
      description = ''
        List of server submodules to create.
      '';
    };
  };

  config.containers = mkIf cfg.enable (
    let
      server-containers = builtins.mapAttrs
        (name: server:
          let
            configs =
              (if server.permissions.enable then {
                "plugins/LuckPerms/groups.yml" = utils.mkConfig "yaml" server.permissions.groups;
                "plugins/LuckPerms/users.yml" = utils.mkConfig "yaml" server.permissions.users;
              } else { }) //
              # Disable metrics
              ({
                "plugins/bStats/config.yml" = utils.mkConfig "yaml" {
                  enabled = false;
                  serverUuid = "00000000-0000-0000-0000-000000000000";
                  logFailedRequests = false;
                };
              }) //
              (properties.generator server.properties) //
              server.configs;
            pre_plugins = server.plugins ++
              (if server.permissions.enable then [ server.permissions.package ] else [ ]);
            # Add plugin depedencies to plugin list
            # TODO: add support for nested depedencies
            plugins = unique (pre_plugins ++
              (flatten (map (x: x.meta.deps) pre_plugins)));
          in
          {
            name = "mf-${name}";
            value = {
              autoStart = true;
              privateNetwork = true;
              # TODO: add options
              hostAddress = "192.168.100.10";
              localAddress = "192.168.100.11";
              config = { config, pkgs, ... }: {
                systemd.services.minecraft = {
                  restartIfChanged = true;
                  wantedBy = [ "multi-user.target" ];
                  wants = [ "network-online.target" ];
                  after = [ "network-online.target" ];
                  description = "${name} mineflake server configuration.";
                  serviceConfig = {
                    Type = "simple";
                    User = "minecraft";
                    Group = "minecraft";
                    SyslogIdentifier = "minecraft";
                    WorkingDirectory = "${server.datadir}";
                  };
                  preStart = ''
                    # Generated by mineflake. Do not edit this file.
                    echo "Create required directories..."
                    mkdir -p "${server.datadir}/plugins" "${server.datadir}/world" \
                              "${server.datadir}/world_nether" "${server.datadir}/world_the_end" \
                              "${server.datadir}/plugins/bStats"
                    echo "Create directories for core ${utils.getName server.package}..."
                    ${if length server.package.meta.folders >= 1 then
                      ''mkdir -p ${toString (map (folder: "\"" + server.datadir + "/" + folder + "\"") server.package.meta.folders)}'' else ""}
                    ${concatStringsSep "\n" (map (
                      plugin:
                        if length plugin.meta.folders >= 1 then
                        ''
                          echo "Create directories for ${utils.getName plugin}..."
                          mkdir -p ${toString (map (folder: "\"" + server.datadir + "/" + folder + "\"") plugin.meta.folders)}
                        '' else ""
                      ) plugins)}
                    echo "Change directory to server data..."
                    cd "${server.datadir}/"
                    echo "eula.txt generation..."
                    rm -f "${server.datadir}/eula.txt"
                    ln -sf "${eula-file}" "${server.datadir}/eula.txt"
                    echo "Remove old plugin symlinks..."
                    rm -rf "${server.datadir}/plugins/*.jar"
                    ${concatStringsSep "\n" (map (
                      plugin: if plugin.meta.type == "result" then
                        (utils.linkResult plugin (server.datadir + "/plugins") ".jar")
                        else if plugin.meta.type == "complex" then
                        (utils.linkComplex plugin (server.datadir)) + "\n" +
                        ''ln -sf "${plugin}/result" "${server.datadir}/plugins/${utils.getName plugin}.jar"'' + "\n"
                        else "echo 'Unsupported ${utils.getName plugin} plugin type ${plugin.meta.type}!'") plugins)}
                    ${if (server.package.meta.type == "complex") then
                      (utils.linkComplex server.package (server.datadir))
                      else ""}
                    ${utils.mkConfigs server name configs}
                    echo "Link server core for easier debug and local launch..."
                    rm -f "${server.datadir}/server-*.jar"
                    ln -sf "${server.package}/result" "${server.datadir}/server-${utils.getName server.package}.jar"
                  '';
                  script = ''
                    # Generated by mineflake. Do not edit this file.
                    echo 'Change directory to server data'
                    cd "${server.datadir}"
                    echo "Hello from mineflake!"
                    echo "Core: ${utils.getName server.package}"
                    echo "Opts: ${builtins.toString (builtins.map (x: "'"+x+"'") server.opts)}"
                    echo "Plugins: ${builtins.toString (builtins.map (x: "'"+x.pname+"-"+x.version+"'") plugins)}"
                    echo "Launch ${utils.getName server.package} for ${name} server..."
                    ${server.jre}/bin/java -jar ${server.package}/result ${builtins.toString (builtins.map (x: "\""+x+"\"") server.opts)}
                  '';
                };

                users = {
                  users.minecraft = {
                    createHome = true;
                    isSystemUser = true;
                    home = server.datadir;
                    group = "minecraft";
                    description = "System account that runs ${name} mineflake server configuration.";
                  };
                  groups.minecraft = { };
                };

                system.stateVersion = "22.05";
              };
            };
          })
        cfg.servers; in
    builtins.listToAttrs (map (key: getAttr key server-containers) (attrNames server-containers))
  );
}
