{ config, nodes, pkgs, lib, ... }:

let
  altraInternal = lib.head (lib.splitString "/" (lib.head nodes.altra.config.networking.wireguard.interfaces.internal.ips));
in
{
  services.caddy = {
    enable = true;
    package = pkgs.callPackage ../../../packages/caddy { };
    configFile = pkgs.writeTextDir "Caddyfile" ''
      {
        grace_period 10s
      }

      (defaults) {
        encode zstd gzip
        header Strict-Transport-Security "max-age=31536000; includeSubDomains"
        header X-Powered-By "trans rights are human rights"

        tls {
          dns cloudflare {env.CF_API_TOKEN}
        }

        handle_path /.well-known/security.txt {
          respond `${lib.readFile ./security.txt}`
        }
      }

      geklautecloud.de *.geklautecloud.de {
        import defaults

        @matrix.geklautecloud.de host matrix.geklautecloud.de
        handle @matrix.geklautecloud.de {
          handle_path /.well-known/matrix/* {
            header Content-Type application/json
            respond /server `{ "m.server": "matrix.geklautecloud.de:443" }`
            respond 404
          }
          reverse_proxy [::1]:28008
        }

        handle {
          redir https://git.geklaute.cloud{uri}
        }
      }

      geklaute.cloud *.geklaute.cloud {
        import defaults

        @geklaute.cloud host geklaute.cloud
        handle @geklaute.cloud {
          reverse_proxy https://${altraInternal}:443 {
            header_up Host "geklaute.cloud"
            transport http {
              tls_server_name "geklaute.cloud"
              ## TODO: remove `tls_insecure_skip_verify`
              tls_insecure_skip_verify
            }
          }
        }

        @rss.geklaute.cloud host rss.geklaute.cloud
        handle @rss.geklaute.cloud {
          reverse_proxy unix/${config.services.miniflux.config.LISTEN_ADDR}
        }

        @git.geklaute.cloud host git.geklaute.cloud
        handle @git.geklaute.cloud {
          reverse_proxy unix/${config.services.forgejo.settings.server.HTTP_ADDR}
        }

        @drone.geklaute.cloud host drone.geklaute.cloud
        handle @drone.geklaute.cloud {
          reverse_proxy ${config.systemd.services.drone-server.environment.DRONE_SERVER_PORT}
        }

        @up.geklaute.cloud host up.geklaute.cloud
        handle @up.geklaute.cloud {
          reverse_proxy 127.0.0.3:3001
        }

        @ip.geklaute.cloud host ip.geklaute.cloud
        handle @ip.geklaute.cloud {
          respond {http.request.remote.host}
        }

        @vaultwarden.geklaute.cloud host vaultwarden.geklaute.cloud
        handle @vaultwarden.geklaute.cloud {
          redir /admin* /
          reverse_proxy 127.0.0.1:3080
        }

        @ntfy.geklaute.cloud host ntfy.geklaute.cloud
        handle @ntfy.geklaute.cloud {
          reverse_proxy unix/${config.services.ntfy-sh.settings.listen-unix}
        }

        handle {
          redir https://geklaute.cloud{uri}
        }
      }

      gkcl.de *.gkcl.de {
        import defaults

        @gkcl.de host gkcl.de
        handle @gkcl.de {
          redir https://geklaute.cloud{uri}
        }

        @wildcard_.gkcl.de host *.gkcl.de
        handle @wildcard_.gkcl.de {
          redir https://{http.request.host.labels.2}.geklaute.cloud{uri}
        }

        handle {
          abort
        }
      }

      indeednotjames.com {
        import defaults

        handle_path /.well-known/matrix/* {
          header Content-Type application/json
          header Access-Control-Allow-Origin *

          respond /client `${builtins.toJSON {
            "m.homeserver".base_url = "https://mx-synapse.indeednotjames.com";
            "org.matrix.msc3575.proxy".url = "https://mx-sliding-sync.indeednotjames.com";
          }}`

          respond /server `${builtins.toJSON {
            "m.server" = "mx-synapse.indeednotjames.com:443";
          }}`

          respond 404
        }

        handle {
          redir https://github.com/emilylange
        }
      }

      *.indeednotjames.com {
        import defaults

        @git host git.indeednotjames.com
        handle @git {
          redir https://git.geklaute.cloud{uri}
        }

        @mx-synapse host mx-synapse.indeednotjames.com
        handle @mx-synapse {
          reverse_proxy [::1]:18008
        }

        @mx-sliding-sync host mx-sliding-sync.indeednotjames.com
        handle @mx-sliding-sync {
          reverse_proxy ${config.services.matrix-synapse.sliding-sync.settings.SYNCV3_BINDADDR}
        }

        handle {
          redir https://github.com/emilylange
        }
      }

      emilylange.de *.emilylange.de {
        import defaults

        redir https://github.com/emilylange
      }
    '' + /Caddyfile;
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];

    allowedUDPPorts = [
      443
    ];
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile = config.deployment.keys."caddy_additional_env".path;

  deployment.keys."caddy_additional_env" = {
    user = config.services.caddy.user;
    destDir = "/";
    ## ```env
    ## CF_API_TOKEN=
    ## ```
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/caddy_additional_env" ];
  };
}
