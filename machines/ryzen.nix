{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    kernelModules = [ "kvm-amd" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" ];
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
        "noatime"
        "compress-force=zstd"
        "subvol=nixos/@"
      ];
    };

    "/home" = {
      device = "/dev/disk/by-label/BTRFS";
      fsType = "btrfs";
      options = [
        "noatime"
        "compress-force=zstd"
        "subvol=nixos/@home"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/EFIBOOT";
      fsType = "vfat";
    };
  };

  services.fstrim.enable = true;

  hardware.cpu.amd.updateMicrocode = true;

  programs.corectrl = {
    enable = true;
    gpuOverclock.enable = true;
  };

  networking.hostName = "ryzen";
  system.stateVersion = "21.11";
}
