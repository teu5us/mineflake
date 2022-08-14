{ lib, pkgs, config, ... }:

with lib; let
  cfg = config.minecraft;

  serverSubmodule = types.submodule ({ ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = "Server name.";
      };

      datadir = mkOption {
        type = types.path;
        description = "Server data directory.";
      };

      plugins = mkOption {
        type = types.listOf types.package;
        description = "Plugins to install.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.tmux;
        example = "paper";
        description = "Server package.";
      };
    };
  }) // {
    description = "Server submodule";
  }; in
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
    systemd.services =  builtins.listToAttrs (builtins.map (server:
      {
        name = "minecraft-prepare-${server.name}";
        value = {
          description = "Launch ${server.name} Minecraft server.";
          script = ''
            # Create required directories
            mkdir -p ${server.datadir}
            mkdir -p ${server.datadir}/plugins

            # Link plugins
          '' + builtins.toString (builtins.map
              (plugin: "ln -sf ${plugin}/result ${server.datadir}/plugins/${plugin.pname}-${plugin.version}-${plugin.hash}.jar\n") server.plugins);
        };
      }) cfg.servers);
  };
}
