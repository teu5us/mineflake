{ ... }:

let
  mkConfigFile = option: (
    # yaml compatible with json format
    if option.type == "yaml" || option.type == "json" then
      (builtins.toFile "config.${option.type}" (builtins.toJSON option.data))
    else if option.type == "raw" then
      (builtins.toFile "config.${option.type}" option.data.raw)
    else
      (builtins.toFile "none.txt" "Impossible")
  );

  # {some=data; foo=bar} -> [data bar]
  attrValsToList = attrs: map (key: getAttr key attrs) (attrNames attrs);
in
{
  inherit mkConfigFile attrValsToList;

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

  mkRawConfig = text: mkConfig "raw" { raw = text; };

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

  attrListToAttr = list: builtins.listToAttrs (attrValsToList list);
}
