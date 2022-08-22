{ lib, pkgs, config, ... }:

with lib; let
  cfg = config.minecraft;

  spigot = pkgs.callPackage ../pkgs/spigot { };

  eula-file = mkConfigFile {
    type = "raw";
    data = {
      raw = "eula=true";
    };
  };

  mkConfigFile = option: (
    # yaml compatible with json format
    if option.type == "yaml" || option.type == "json" then
      (builtins.toFile "config.${option.type}" (builtins.toJSON option.data))
    else if option.type == "raw" then
      (builtins.toFile "config.${option.type}" option.data.raw)
    else
      (builtins.toFile "none.txt" "Impossible")
  );

  mkConfigs = server: server-name: configs:
    let ders = mapAttrs (name: option: mkConfigFile option) configs; in
    (
      concatStringsSep "\n" (map
        # TODO: replace env variables in config
        # substitute ${server.envfile} ${server.datadir}/${key}
        (key: ''
          echo 'Create "${key}" config file'
          rm -f "${server.datadir}/${key}"
          cp "${getAttr key ders}" "${server.datadir}/${key}"
          chmod 440 "${server.datadir}/${key}"
        '')
        (attrNames ders))
    );

  mkConfig = type: data: { inherit type data; };

  getName = package: "${package.pname}-${package.version}";

  linkComplex = package: base:
    concatStringsSep "\n" (
      map
        (key: ''
          echo 'Link "${key}" for ${getName package}'
          rm -f "${base}/${key}"
          ln -sf "${package}/${getAttr key package.meta.struct}" "${base}/${key}"'')
        (attrNames package.meta.struct));

  linkResult = package: base: ext:
    ''
      echo "Link ${getName package} result"
      ln -sf "${package}" "${base}/${getName package}${ext}"
    '';

  boolToString = val: if val then "true" else "false";

  # {some=data; foo=bar} -> [data bar]
  attrValsToList = attrs: map (key: getAttr key attrs) (attrNames attrs);

  attrListToAttr = list: builtins.listToAttrs (attrValsToList list);

  # OPTIONS

  configSubmodule = types.submodule
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
    }) // {
    description = "Config submodule";
  };

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

  permissionSubmodule = types.submodule
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
    }) // {
    description = "Config submodule";
  };

  rconSubmodule = types.submodule
    ({ ... }: {
      options = {
        enable = mkEnableOption "Enable rcon";

        port = mkOption {
          type = types.port;
          default = 25575;
          description = "rcon port.";
        };

        password = mkOption {
          type = types.str;
          default = "";
          description = "rcon password.";
        };

        broadcast-to-ops = mkEnableOption "broadcast-rcon-to-ops";
      };
    });

  querySubmodule = types.submodule
    ({ ... }: {
      options = {
        enable = mkEnableOption "Enable query";

        port = mkOption {
          type = types.port;
          default = 25565;
          description = "query port.";
        };
      };
    });

  propertiesSubmodule = types.submodule
    ({ ... }: {
      options = {
        rcon = mkOption {
          type = rconSubmodule;
          default = { };
          description = "Server rcon settings.";
        };

        query = mkOption {
          type = rconSubmodule;
          default = { };
          description = "Server query settings.";
        };

        seed = mkOption {
          type = types.str;
          default = "";
          description = "Server seed.";
        };

        motd = mkOption {
          type = types.str;
          default = "";
          description = "Server motd.";
        };

        gamemode = mkOption {
          type = types.enum [ "survival" "creative" "spectator" ];
          default = "survival";
          description = "Server seed.";
        };

        difficulty = mkOption {
          # TODO: fill
          type = types.enum [ "easy" "hard" ];
          default = "survival";
          description = "Server seed.";
        };

        max-world-size = mkOption {
          type = types.int;
          default = "";
          description = "fill.";
        };

        online-mode = mkEnableOption "online-mode";

        enable-command-block = mkEnableOption "enable-command-block";

        enable-query = mkEnableOption "enable-query";

        pvp = mkEnableOption "pvp";

        allow-flight = mkEnableOption "fill";

        spawn-animals = mkOption {
          type = types.bool;
          default = true;
          description = "fill.";
        };

        spawn-monsters = mkOption {
          type = types.bool;
          default = true;
          description = "fill.";
        };
      };
    });

  serverSubmodule = types.submodule
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
          type = types.attrsOf configSubmodule;
          default = { };
          description = "Config derivations.";
        };

        permissions = mkOption {
          type = permissionSubmodule;
          default = { };
          description = "Permissions (LP) settings.";
        };

        properties = mkOption {
          type = propertiesSubmodule;
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
    }) // {
    description = "Server submodule";
  };
in
{
  options.minecraft = {
    enable = mkEnableOption "If enabled, Nix-defined minecraft servers will be created from minecraft.servers.";

    servers = mkOption {
      type = types.attrsOf serverSubmodule;
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
                "plugins/LuckPerms/groups.yml" = mkConfig "yaml" server.permissions.groups;
                "plugins/LuckPerms/users.yml" = mkConfig "yaml" server.permissions.users;
              } else { }) //
              # Disable metrics
              ({
                "plugins/bStats/config.yml" = mkConfig "yaml" {
                  enabled = false;
                  serverUuid = "00000000-0000-0000-0000-000000000000";
                  logFailedRequests = false;
                };
              }) //
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
                    echo "Create directories for core ${getName server.package}..."
                    ${if length server.package.meta.folders >= 1 then
                      ''mkdir -p ${toString (map (folder: "\"" + server.datadir + "/" + folder + "\"") server.package.meta.folders)}'' else ""}
                    ${concatStringsSep "\n" (map (
                      plugin:
                        if length plugin.meta.folders >= 1 then
                        ''
                          echo "Create directories for ${getName plugin}..."
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
                        (linkResult plugin (server.datadir + "/plugins") ".jar")
                        else if plugin.meta.type == "complex" then
                        (linkComplex plugin (server.datadir)) + "\n" +
                        ''ln -sf "${plugin}/result" "${server.datadir}/plugins/${getName plugin}.jar"'' + "\n"
                        else "echo 'Unsupported ${getName plugin} plugin type ${plugin.meta.type}!'") plugins)}
                    ${if (server.package.meta.type == "complex") then
                      (linkComplex server.package (server.datadir))
                      else ""}
                    ${mkConfigs server name configs}
                    echo "Link server core for easier debug and local launch..."
                    rm -f "${server.datadir}/server-*.jar"
                    ln -sf "${server.package}/result" "${server.datadir}/server-${getName server.package}.jar"
                  '';
                  script = ''
                    # Generated by mineflake. Do not edit this file.
                    echo 'Change directory to server data'
                    cd "${server.datadir}"
                    echo "Hello from mineflake!"
                    echo "Core: ${getName server.package}"
                    echo "Opts: ${builtins.toString (builtins.map (x: "'"+x+"'") server.opts)}"
                    echo "Plugins: ${builtins.toString (builtins.map (x: "'"+x.pname+"-"+x.version+"'") plugins)}"
                    echo "Launch ${getName server.package} for ${name} server..."
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
    attrListToAttr server-containers
  );
}
