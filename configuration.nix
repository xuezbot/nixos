{ config, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  # 允许非特权用户(如 sakuya) 绑定 80/443 端口
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;

  # --- 引导与内核 ---
  boot.loader.systemd-boot.enable = false;  # 关掉 UEFI 引导
  boot.loader.grub.enable = true;           # 开启 GRUB
  boot.loader.grub.device = "/dev/sda";     # 安装到硬盘 MBR
  boot.loader.grub.useOSProber = true;

  # --- 网络设置 ---
  networking.hostName = "nixos-server"; # 对应 flake.nix 里的名字，最好保持一致
  networking.networkmanager.enable = false; # 禁用 NetworkManager 以使用静态 IP
  networking.enableIPv6 = true;

  # 静态 IP 配置 (适配 Proxmox)
  networking.defaultGateway = "10.0.1.3";
  networking.nameservers = [ "10.0.1.3" ];
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "10.0.1.8";
    prefixLength = 24;
  }];
  
  networking.firewall.allowedTCPPorts = [ 80 443 22 ]; 

  # --- QEMU Guest Agent ---
  services.qemuGuest.enable = true;

  # --- 时区与语言 ---
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  # --- 用户管理 ---
  # Root 密码建议只用于紧急救援
  users.users.root = {
    initialPassword = "1234"; 
  };

  users.users.sakuya = {
    isNormalUser = true;
    uid = 1000; # 固定 UID 以便映射 Socket
    description = "Sakuya";
    extraGroups = [ "networkmanager" "wheel" "podman" ]; 
    initialPassword = "1234"; 
    # 强烈建议尽早配置 SSH Key，配置好后把 PasswordAuthentication 关掉
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ]; 
  };

  # --- 系统软件包 ---
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    htop         # 推荐装个 htop 看负载
    podman-compose
    distrobox
  ];

  environment.shellAliases = {
    # 以后你想更新系统，只需要输入 "updatenix" 回车
    updatenix = "cd /etc/nixos && git pull && sudo nixos-rebuild switch --flake .#nixos-server";
  };

  # --- 服务配置 ---
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true; 
    };
  };

  # --- 虚拟化 (Podman) ---
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers.backend = "podman";
  };

  # 确保 /home/sakuya/podman 目录存在
  # 1. 开启 Linger (为了让 sakuya 的 Rootless 容器在后台一直跑)
  systemd.tmpfiles.rules = [
    "f /var/lib/systemd/linger/sakuya 0644 root root -"
  ];

  # --- 系统状态版本 ---
  system.stateVersion = "25.11"; 
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}