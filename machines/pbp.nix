{ lib, inputs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.pine64-pinebook-pro
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "pinebookpro-ap6256-firmware"
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "usbhid" "usb_storage" ];
      kernelParams = [
        "console=tty0"
        "panic=10"
      ];
      luks.devices."btrfs".device = "/dev/disk/by-label/BTRFSCRYPT";
    };

    loader = {
      ## extlinux boot loader
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  powerManagement.cpuFreqGovernor = "ondemand";
  networking.firewall.enable = false;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/BTRFS";
      fsType = "btrfs";
      options = [ "subvol=nixos/@" "noatime" "compress-force=zstd" ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/EFIBOOT";
      fsType = "vfat";
      options = [
        "umask=0077"
      ];
    };
  };

  ## https://wiki.pine64.org/index.php/Pinebook_Pro#OpenGL_3.3_support
  environment.variables.PAN_MESA_DEBUG = "gl3";

  ## "don't suspend when closing the lid"
  ## This somehow doesn't seem to work on this hardware and I have no idea why :(
  services.logind.lidSwitch = "lock";

  nixpkgs.system = "aarch64-linux";
  system.stateVersion = "22.05";
}
