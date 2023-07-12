## Scaleway "stardust" compute instance
## https://www.scaleway.com/en/stardust-instances/
{ pkgs, modulesPath, ... }:

## Scaleway's IPv6 isn't static. Wtf.
## They may or may not change on a reboot -- without notice.
## See https://feature-request.scaleway.com/posts/209/truly-static-ipv6
## and https://feature-request.scaleway.com/posts/198/slaac-or-dhcpv6-support-for-ipv6-address-assignment
let
  subnet = "2001:db8:";
in
{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  networking.interfaces.eth0.ipv6.addresses = [{
    address = "${subnet}:1";
    prefixLength = 64;
  }];

  networking.useDHCP = false;

  networking.defaultGateway6 = {
    address = "${subnet}:";
    interface = "eth0";
  };

  boot = {
    kernelParams = [
      "console=ttyS0,115200"
      "panic=10"
      "boot.panic_on_fail"
    ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "noatime"
        "compress-force=zstd"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
  };

  environment.systemPackages = with pkgs; [
    rclone
    s3cmd
    zx
  ];

  services.qemuGuest.enable = true;

  system.stateVersion = "22.05";
}
