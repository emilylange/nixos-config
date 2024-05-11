{ modulesPath, inputs, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.nixos-hardware.nixosModules.framework-11th-gen-intel
  ];

  boot = {
    kernelModules = [ "kvm-intel" ];
    loader = {
      systemd-boot.enable = false; ## lanzaboote requires this to be disabled (for now)
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    initrd = {
      availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
      luks.devices."btrfs" = {
        device = "/dev/disk/by-label/BTRFSCRYPT";
        allowDiscards = true;
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/BTRFS";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "noatime"
        "compress-force=zstd"
      ];
    };

    "/home" = {
      device = "/dev/disk/by-label/BTRFS";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "noatime"
        "compress-force=zstd"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/EFIBOOT";
      fsType = "vfat";
      options = [
        "umask=0077"
      ];
    };
  };

  services.fstrim.enable = true;
  services.fwupd.extraRemotes = [ "lvfs-testing" ];

  powerManagement.cpuFreqGovernor = "powersave";
  hardware.cpu.intel.updateMicrocode = true;

  hardware.framework.enableKmod = false;

  networking.hostName = "frameless";
  system.stateVersion = "22.05";
}
