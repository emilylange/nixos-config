{ nodes, pkgs, lib, ... }:

with lib;

let
  getKeyCommand = config: filename: config.deployment.keys.${baseNameOf filename}.keyCommand;
  json = (mapAttrs
    (name: node:
      let cfg = node.config; in
      (mapAttrs
        (_: backup:
          (mapAttrs
            (providerName: provider: {
              repository = provider.repository;
              keyCommand = concatStringsSep " " (getKeyCommand cfg provider.secrets.sshKey);
            })
            backup.providers)
        )
        cfg.backups)
    )
    nodes);
in

pkgs.writeTextFile {
  name = "generate-config-for-backups.mjs";
  executable = true;
  text = ''
    #!${pkgs.zx.out}/bin/zx
    const json = JSON.parse(`${builtins.toJSON json}`);
    const destinations = {};

    for (const [nodeName, nodeCfg] of Object.entries(json)) {
      for (const [backupName, backupCfg] of Object.entries(nodeCfg)) {
        for (const [providerName, providerCfg] of Object.entries(backupCfg)) {
          const repoSplit = providerCfg.repository.split("/");

          const dest = repoSplit[2];
          if (!destinations[dest]) destinations[dest] = "";

          let publicKey = await getPublicKeyFromCommand(
            providerCfg.keyCommand,
            `''${nodeName}_''${backupName}_''${providerName}`
          );

          if (providerName === "borg") {
            const path = repoSplit.slice(3).join("/");
            publicKey = `command="borg serve --append-only --restrict-to-path ''${path}" ''${publicKey}`;
          }

          destinations[dest] += publicKey + "\n";
        }
      }
    }

    for (const [name, keys] of Object.entries(destinations)) {
      console.log(`''${"*".repeat(10)} ''${name} ''${"*".repeat(10)}`);
      console.log(keys);
    }

    async function getPublicKeyFromCommand(cmd, comment) {
      const rawPublic = await $`ssh-keygen -yf /dev/stdin <<< $(''${cmd.split(" ")})`;
      const splitPublic = rawPublic.toString().replace("\n", "").split(" ");
      splitPublic[2] = comment;
      return splitPublic.join(" ");
    }
  '';
}
