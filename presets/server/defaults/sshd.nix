{ config, lib, ... }:

{
  services.openssh = {
    enable = true;

    ## overwrite default `AuthorizedKeysFile` locations to only include
    ## `/etc/ssh/authorized_keys.d/%u` and prohibit others like `%h/.ssh/authorized_keys`.
    authorizedKeysFiles = lib.mkForce [
      "/etc/ssh/authorized_keys.d/%u"
    ];

    ## don't automatically add `services.openssh.ports`
    ## to `networking.firewall.allowedTCPPorts`
    openFirewall = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIAezsP3Y2nFa+YubXIvgaHRuSohJUdj3ctzoqvzcwwwgAAAABHNzaDo="
  ];

  ## expose configured ssh port on any interface
  networking.firewall.allowedTCPPorts = config.services.openssh.ports;
}
