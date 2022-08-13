{ lib, pkgs, config, ... }:

with lib; let
  cfg = config.services.minecraft;

  pluginSubmodule = types.submodule ({ ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = "Plugin name.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.tmux;
        description = "Plugin package.";
      };
    };
  }) // {
    description = "Plugin submodule. Contains plugin package and it meta-info.";
  };

  serverSubmodule = types.submodule ({ ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = "Server name.";
      };

      plugins = mkOption {
        type = types.listOf pluginSubmodule;
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
  options.services.minecraft = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If enabled, Nix-defined minecraft servers will be created from
        services.minecraft.servers.
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
        name = "minecraft-${server.name}";
        value = {
          description = "Launch ${server.name} Minecraft server.";
          script = ''echo "hello world!"'';
        };
      }) cfg.servers);
  };
}
