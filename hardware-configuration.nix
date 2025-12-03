# 请勿修改此文件！它是由 ‘nixos-generate-config’ 生成的
# 并且可能会被未来的调用覆盖。请改为修改 /etc/nixos/configuration.nix。
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

  swapDevices = [ ];

  # 在每个以太网和无线接口上启用 DHCP。如果使用脚本化网络配置
  # (默认情况)，这是推荐的方法。当使用 systemd-networkd 时，
  # 仍然可以使用此选项，但建议将其与显式的每接口声明
  # `networking.interfaces.<interface>.useDHCP` 结合使用。
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp3s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
