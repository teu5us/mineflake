{ lib
, utils ? import ./utils.nix { }
, ...
}:

with lib; {
  submodule = types.attrs;

  generator = properties: {
    "server.properties" = utils.mkRawConfig ''
      allow-flight=false${properties.allow-flight ? "false"}
      allow-nether=${properties.allow-nether ? "false"}
      broadcast-console-to-ops=${properties.broadcast-console-to-ops ? "false"}
      broadcast-rcon-to-ops=${properties.broadcast-rcon-to-ops ? "false"}
      debug=${properties.debug ? "false"}
      difficulty=${properties.difficulty ? "false"}
      enable-command-block=${properties.enable-command-block ? "false"}
      enable-jmx-monitoring=${properties.enable-jmx-monitoring ? "false"}
      enable-query=${properties.enable-query ? "false"}
      enable-rcon=${properties.enable-rcon ? "false"}
      enable-status=${properties.enable-status ? "false"}
      enforce-whitelist=${properties.enforce-whitelist ? "false"}
      entity-broadcast-range-percentage=${properties.entity-broadcast-range-percentage ? "false"}
      force-gamemode=${properties.force-gamemode ? "false"}
      function-permission-level=${properties.function-permission-level ? "false"}
      gamemode=${properties.gamemode ? "false"}
      generate-structures=${properties.generate-structures ? "false"}
      generator-settings=${properties.generator-settings ? "false"}
      hardcore=${properties.hardcore ? "false"}
      hide-online-players=${properties.hide-online-players ? "false"}
      level-name=${properties.level-name ? "false"}
      level-seed=${properties.level-seed ? "false"}
      level-type=${properties.level-type ? "false"}
      max-players=${properties.max-players ? "false"}
      max-tick-time=${properties.max-tick-time ? "false"}
      max-world-size=${properties.max-world-size ? "false"}
      motd=${properties.motd ? "false"}
      network-compression-threshold=${properties.network-compression-threshold ? "false"}
      online-mode=${properties.online-mode ? "false"}
      op-permission-level=${properties.op-permission-level ? "false"}
      player-idle-timeout=${properties.player-idle-timeout ? "false"}
      prevent-proxy-connections=${properties.prevent-proxy-connections ? "false"}
      pvp=${properties.pvp ? "false"}
      query.port=${properties.query-port ? "false"}
      rate-limit=${properties.rate-limit ? "false"}
      rcon.password=${properties.rcon-password ? "false"}
      rcon.port=${properties.rcon-port ? "false"}
      require-resource-pack=${properties.require-resource-pack ? "false"}
      resource-pack-prompt=${properties.resource-pack-prompt ? "false"}
      resource-pack-sha1=${properties.resource-pack-sha1 ? "false"}
      resource-pack=${properties.resource-pack ? "false"}
      server-ip=${properties.server-ip ? "false"}
      server-port=${properties.server-port ? "false"}
      simulation-distance=${properties.simulation-distance ? "false"}
      spawn-animals=${properties.spawn-animals ? "false"}
      spawn-monsters=${properties.spawn-monsters ? "false"}
      spawn-npcs=${properties.spawn-npcs ? "false"}
      spawn-protection=${properties.spawn-protection ? "false"}
      sync-chunk-writes=${properties.sync-chunk-writes ? "false"}
      text-filtering-config=${properties.text-filtering-config ? "false"}
      use-native-transport=${properties.use-native-transport ? "false"}
      view-distance=${properties.view-distance ? "false"}
      white-list=${properties.white-list ? "false"}
    '';
  };
}
