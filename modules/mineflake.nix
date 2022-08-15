{ lib, pkgs, config, ... }:

with lib; let
  cfg = config.minecraft;

  mkConfigDerivation = name: server-name: option:
    let
      default = {
        version = server-name;
        phases = [ "buildPhase" "installPhase" ];
        pname = "minecraft-config-${name}";
        installPhase = "chmod 744 $out";
      };
    in
    (
      # yaml compatible with json format
      if option.type == "yaml" || option.type == "json" then
        pkgs.stdenv.mkDerivation
          (default // {
            # We use "bsHSCeMDDECFe1eo" string as a EOF marker, cause it harder to collision with
            buildPhase = ''
              cat <<bsHSCeMDDECFe1eo > $out
              ${builtins.toJSON option.data}
              bsHSCeMDDECFe1eo
            '';
          })
      else if option.type == "raw" then
        pkgs.stdenv.mkDerivation
          (default // {
            buildPhase = ''
              cat <<bsHSCeMDDECFe1eo > $out
              ${option.data.raw}
              bsHSCeMDDECFe1eo
            '';
          })
      else
        pkgs.stdenv.mkDerivation (default // {
          buildPhase = ''
            cat <<bsHSCeMDDECFe1eo > $out
            none
            bsHSCeMDDECFe1eo
          '';
        })
    );

  mkConfigs = server: server-name: configs:
    let ders = mapAttrs (name: option: mkConfigDerivation name server-name option) configs; in
    (
      toString (map
        (key: ''
          # Link "${key}" config file
          rm -f "${server.datadir}/data/${key}"
          cp "${getAttr key ders}" "${server.datadir}/data/${key}"
          # TODO: replace env variables in config
          # substitute \$\{server.envfile\} \$\{server.datadir\}/data/\$\{ke0\y}
        '')
        (attrNames ders))
    );

  linkComplex = package: base:
    "# Link ${package.pname}-${package.version} complex struct\n" +
    toString (
      map
        (key: ''
          rm -f "${base}/${key}"
          ln -sf "${package}/${getAttr key package.meta.struct}" "${base}/${key}"
        '')
        (attrNames package.meta.struct)
    );

  linkResult = package: base: ext:
    ''
      # Link ${package.pname}-${package.version} result
      ln -sf ${package} "${base}/${package.pname}-${package.version}-${package.hash}${ext}"
    '';


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
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            If enabled, Nix-defined minecraft servers will be created from minecraft.servers.
          '';
        };

        groups = mkOption {
          type = types.attrsOf permissionGroup;
          default = { };
        };

        users = mkOption {
          type = types.attrsOf permissionGroup;
          default = { };
        };

        package = mkOption {
          type = types.package;
          default = pkgs.callPackage ../pkgs/spigot/luckperms { };
          example = "pkgs.spigot.luckperms";
          description = "Plugin package.";
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
          default = { };
          description = "Config derivations.";
        };

        permissions = mkOption {
          type = permissionSubmodule;
          default = { };
          description = "Permissions (LP) settings.";
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
        eula_drv = mkConfigDerivation "eula.txt" "default" {
          type = "raw";
          data = {
            raw = "eula=true";
          };
        };
        obj = builtins.mapAttrs
          (name: server:
            let
              configs =
                if server.permissions.enable then {
                  "plugins/LuckPerms/groups.yml" = {
                    type = "yaml";
                    data = server.permissions.groups;
                  };
                } // {
                  "plugins/LuckPerms/users.yml" = {
                    type = "yaml";
                    data = server.permissions.users;
                  };
                } else { } //
                  server.configs;
              plugins = server.plugins ++
                (if server.permissions.enable then [ server.permissions.package ] else [ ]);
            in
            {
              name = "minecraft-${name}";
              value = {
                restartIfChanged = true;
                wantedBy = [ "multi-user.target" ];
                wants = [ "minecraft-${name}-prepare.service" "network-online.target" ];
                after = [ "minecraft-${name}-prepare.service" "network-online.target" ];
                description = "Launch ${name} mineflake server configuration.";
                serviceConfig = {
                  Type = "simple";
                  ProtectHome = true;
                  ProtectSystem = true;
                  # TODO: rootless
                  # User = "minecraft-${name}";
                  # Group = "minecraft-${name}";
                  User = "root";
                  SyslogIdentifier = "minecraft-${name}";
                  WorkingDirectory = "${server.datadir}/data";
                };
                preStart = ''
                  # Generated by mineflake. Do not edit this file.

                  # Create required directories
                  mkdir -p "${server.datadir}/data/plugins"
                  mkdir -p "${server.datadir}/data/world"
                  mkdir -p "${server.datadir}/data/world_nether"
                  mkdir -p "${server.datadir}/data/world_the_end"

                  # Change directory to server data
                  cd "${server.datadir}/data"

                  # eula.txt generation
                  rm -f "${server.datadir}/data/eula.txt"
                  ln -sf "${eula_drv}" "${server.datadir}/data/eula.txt"

                  # Remove old plugin symlinks
                  rm -rf "${server.datadir}/data/plugins/*.jar"

                  ${toString (map (
                    plugin:
                      ''
                        # Create directories for ${plugin.pname}-${plugin.version}
                        mkdir -p ${toString (map (folder: "\"" + server.datadir + "/data/" + folder + "\"") plugin.meta.folders)}
                      ''
                    ) plugins)}

                  ${toString (map (
                    plugin: if plugin.meta.type == "result" then
                      linkSimple plugin server.datadir + "/data/plugins" ".jar"
                      else if plugin.meta.type == "complex" then
                      (linkComplex plugin (server.datadir + "/data")) +
                      ''ln -sf "${plugin}/result" "${server.datadir}/data/plugins/${plugin.pname}-${plugin.version}-${plugin.hash}.jar"''
                      else "# Unsupported ${plugin.pname}-${plugin.version} plugin type ${plugin.meta.type}") plugins)}

                  ${mkConfigs server name configs}

                  ${if length server.package.meta.folders >= 1 then
                    ''mkdir -p ${toString (map (folder: "\"" + server.datadir + "/data/" + folder + "\"") server.package.meta.folders)}'' else ""}

                  # Link server core for easier debug and local launch
                  rm -f "${server.datadir}/data/server-*.jar"
                  ln -sf "${server.package}/result" "${server.datadir}/data/server-${server.package.pname}-${server.package.version}-${server.package.hash}.jar"

                  ${if (server.package.meta.type == "complex") then
                    linkComplex server.package (server.datadir + "/data")
                    else ""}
                '';
                script = ''
                  # Generated by mineflake. Do not edit this file.

                  # Change directory to server data
                  cd "${server.datadir}/data"

                  # Launch ${server.package.pname}-${server.package.version} for ${name} server
                  ${server.jre}/bin/java -jar ${server.package}/result ${builtins.toString (builtins.map (x: "\""+x+"\"") server.opts)}
                '';
              };
            })
          cfg.servers;
        obj_prepare = builtins.mapAttrs
          (name: server:
            {
              name = "minecraft-${name}-prepare";
              value = {
                wantedBy = [ "multi-user.target" ];
                wants = [ "network-online.target" ];
                after = [ "network-online.target" ];
                description = "Prepare ${name} server folder.";
                serviceConfig = {
                  User = "root";
                  Type = "oneshot";
                  RemainAfterExit = "yes";
                  SyslogIdentifier = "minecraft-${name}-prepare";
                };
                script = ''
                  # Generated by mineflake. Do not edit this file.

                  # Create base dir
                  mkdir -p "${server.datadir}/data"

                  # Give rights to folder
                  chown -R minecraft-${name}:minecraft-${name} "${server.datadir}"
                  chmod -R 777 "${server.datadir}"
                '';
              };
            })
          cfg.servers;
      in
      builtins.listToAttrs (map (key: getAttr key obj) (attrNames obj)) // builtins.listToAttrs (map (key: getAttr key obj_prepare) (attrNames obj_prepare));

    users.users =
      let
        obj = builtins.mapAttrs
          (name: server:
            {
              name = "minecraft-${name}";
              value = {
                createHome = true;
                isSystemUser = true;
                home = server.datadir;
                group = "minecraft-${name}";
                description = "System account that runs ${name} mineflake server configuration.";
              };
            })
          cfg.servers;
      in
      builtins.listToAttrs (map (key: getAttr key obj) (attrNames obj));

    users.groups =
      let
        obj = builtins.mapAttrs
          (name: server:
            {
              name = "minecraft-${name}";
              value = {
                name = "minecraft-${name}";
                members = [ "minecraft-${name}" ];
              };
            })
          cfg.servers;
      in
      builtins.listToAttrs (map (key: getAttr key obj) (attrNames obj));
  };
}
