{ modulesPath, inputs, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  boot = {
    kernelModules = [ "kvm-amd" ];
    loader = {
      systemd-boot.enable = false; ## lanzaboote requires this to be disabled (for now)
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
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
      options = [
        "umask=0077"
      ];
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
