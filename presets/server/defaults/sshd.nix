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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSwUs8u9mp2DMJN2bQsjTjOYWwEy7mskFrGyvdGTM1S"
  ];

  ## expose configured ssh port on any interface
  networking.firewall.allowedTCPPorts = config.services.openssh.ports;
}
