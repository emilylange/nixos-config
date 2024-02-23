{ config, pkgs, lib, redacted, ... }:


let
  kv = redacted.kv.global.backups;
  inherit (kv.rclone-ssh-stdin)
    port
    hostname
    ;
  inherit (kv.ssh)
    knownHosts
    ;
in
{
  systemd.services.postgresql.postStart = lib.mkAfter ''
    $PSQL -tAc 'GRANT "pg_read_all_data" TO "postgres-dump-ro";'
  '';

  services.postgresql.ensureUsers = [{
    name = "postgres-dump-ro";
  }];

  systemd.services.postgres-dump-restic = rec {
    after = [ "postgresql.service" "network-online.target" ];
    wants = [ "postgresql.service" "network-online.target" ];
    serviceConfig = {
      User = "postgres-dump-ro";
      StateDirectory = "postgres-dump-ro";
      StateDirectoryMode = "0700";
      CacheDirectory = "postgres-dump-ro";
      CacheDirectoryMode = "0700";
      WorkingDirectory = "%S/postgres-dump-ro";
      DynamicUser = true;
      KillMode = "mixed"; ## solves "Found left-over process 389256 (ssh) in control group while starting unit. Ignoring."
    };

    environment = {
      HOME = "%S/${serviceConfig.StateDirectory}";
      RESTIC_CACHE_DIR = "%C/${serviceConfig.CacheDirectory}";
      RESTIC_PASSWORD_FILE = "password";
      RESTIC_REPOSITORY = "rclone:";
    };

    path = [ config.services.postgresql.package pkgs.pwgen pkgs.restic pkgs.openssh ];

    preStart = ''
      if [ ! -s 'password' ]; then
        pwgen -s 128 1 > password
      fi

      if [ ! -s 'id_ed25519' ]; then
        echo "Generating ssh keypair..."
        ${lib.getExe' pkgs.openssh "ssh-keygen"} -C "" -N "" -t ed25519 -f 'id_ed25519'
        echo "Keypair generated. Public Key:"
        cat id_ed25519.pub

        echo "Exiting unclean, as this new keypair likely needs to be added to some authorized_keys first."
        exit 1
      fi

      restic -o rclone.program='ssh -i id_ed25519 -p${toString port} ${hostname} forced-command' cat config || restic -o rclone.program='ssh -i id_ed25519 -p${toString port} ${hostname} forced-command' init
    '';

    script = ''
      set -o pipefail
      pg_dumpall --clean | restic -o rclone.program='ssh -i id_ed25519 -p${toString port} ${hostname} forced-command' backup --stdin
    '';
  };

  systemd.timers.postgres-dump-restic = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      RandomizedDelaySec = 3600;
      OnCalendar = "03/12:30"; # twice per day
    };
  };

  programs.ssh = { inherit knownHosts; };
}
