{ config, pkgs, lib, redacted, ... }:

let
  acmedns-snippet = domain: ''
    tls {
      dns acmedns ${config.deployment.keys."caddy_acmedns_${domain}.json".path}
      propagation_timeout -1
    }
  '';
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

        @X-Clacks-Overhead header X-Clacks-Overhead *
        header @X-Clacks-Overhead X-Clacks-Overhead {http.request.header.X-Clacks-Overhead}

        handle_path /.well-known/security.txt {
          respond `${lib.readFile ./security.txt}`
        }
      }

      geklautecloud.de *.geklautecloud.de {
        import defaults
        ${acmedns-snippet "geklautecloud.de"}

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
        ${acmedns-snippet "geklaute.cloud"}

        @geklaute.cloud host geklaute.cloud
        handle @geklaute.cloud {
          @forbidden {
            path /.htaccess /.user.ini
            path /3rdparty*
            path /AUTHORS /COPYING /README
            path /build*
            path /config*
            path /console.php
            path /data*
            path /lib*
            path /occ*
            path /templates*
            path /tests*
          }
          redir @forbidden https://geklaute.cloud/login

          file_server
          root * ${config.services.nextcloud.package}
          php_fastcgi unix/${config.services.phpfpm.pools.nextcloud.socket} {
            ## hide index.php from uri
            env front_controller_active true

            header_down Strict-Transport-Security "max-age=15552000;"
          }

          rewrite /.well-known/carddav /remote.php/dav
          rewrite /.well-known/caldav /remote.php/dav
        }

        @rss.geklaute.cloud host rss.geklaute.cloud
        handle @rss.geklaute.cloud {
          reverse_proxy unix/${config.services.miniflux.config.LISTEN_ADDR}
        }

        @hedgedoc.geklaute.cloud host hedgedoc.geklaute.cloud
        handle @hedgedoc.geklaute.cloud {
          reverse_proxy unix/${config.services.hedgedoc.settings.path}
        }

        @git.geklaute.cloud host git.geklaute.cloud
        handle @git.geklaute.cloud {
          reverse_proxy unix/${config.services.forgejo.settings.server.HTTP_ADDR}
        }

        @up.geklaute.cloud host up.geklaute.cloud
        handle @up.geklaute.cloud {
          reverse_proxy 127.0.0.3:3001
        }

        @acme-dns-api.geklaute.cloud host acme-dns-api.geklaute.cloud
        handle @acme-dns-api.geklaute.cloud {
          respond / "Refer to https://github.com/joohoi/acme-dns for details."
          reverse_proxy ${with config.services.acme-dns.settings.api; "${ip}:${port}"}
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

        ${redacted.caddyfile-sections."geklaute.cloud"}

        handle {
          redir https://geklaute.cloud{uri}
        }
      }

      gkcl.de *.gkcl.de {
        import defaults
        ${acmedns-snippet "gkcl.de"}

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
        ${acmedns-snippet "indeednotjames.com"}

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
        ${acmedns-snippet "indeednotjames.com"}

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
          reverse_proxy ${config.services.matrix-sliding-sync.settings.SYNCV3_BINDADDR}
        }

        handle {
          redir https://github.com/emilylange
        }
      }

      emilylange.de *.emilylange.de {
        import defaults
        ${acmedns-snippet "emilylange.de"}

        redir https://github.com/emilylange
      }

      emily.town *.emily.town {
        import defaults
        ${acmedns-snippet "emily.town"}

        # punycode for "krümel"
        @xn--krmel-lva host xn--krmel-lva.emily.town
        handle @xn--krmel-lva {
          respond `hope you don't mind the punycode subdomain.

      still work-in-progess, feel free to come back some time in the future.

      anyhowwwwww...
      in case you happen to need the current time of this server:

      {time.now.http}` 200
        }

        handle {
          redir https://xn--krmel-lva.emily.town
        }
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

  deployment.keys = builtins.listToAttrs (map
    (e: lib.nameValuePair "caddy_acmedns_${e}.json" {
      user = config.services.caddy.user;
      destDir = "/";
      ## curl -X POST https://acme-dns-api.geklaute.cloud/register | jq '.+ { server_url: "https://acme-dns-api.geklaute.cloud" }'
      keyCommand = [ "bw" "--nointeraction" "get" "notes" "gkcl/caddy_acmedns_${e}.json" ];
    }) [
    "emily.town"
    "emilylange.de"
    "geklaute.cloud"
    "geklautecloud.de"
    "gkcl.de"
    "indeednotjames.com"
  ]);

}
