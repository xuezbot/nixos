{ config, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  # 允许非特权用户(如 sakuya) 绑定 80/443 端口
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;
  security.sudo.wheelNeedsPassword = false;

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
    hashedPassword = "!"; 
  };

  users.users.sakuya = {
    isNormalUser = true;
    uid = 1000; # 固定 UID 以便映射 Socket
    description = "Sakuya";
    extraGroups = [ "networkmanager" "wheel" "podman" ]; 
    hashedPassword = "!"; 
    # 强烈建议尽早配置 SSH Key，配置好后把 PasswordAuthentication 关掉
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9E1CjvIxH9dndDMOgbRQN6b3dmcGFVaipNFlOHLlX/" ]; 
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
  updatenix = ''
    # 1. 解决 Git 安全目录报错
    sudo git config --global --add safe.directory /etc/nixos
    
    # 2. 判断是否存在 Git 仓库
    if [ ! -d /etc/nixos/.git ]; then
        echo "⚠️  未检测到仓库，正在执行暴力重置..."
        sudo rm -rf /etc/nixos
        # 重新克隆
        sudo git clone https://github.com/xuezbot/nixos /etc/nixos
    fi

    # 3. 进入目录并强制同步
    cd /etc/nixos
    echo "🔄 正在强制同步远程配置..."
    # 丢弃本地所有修改（包括 flake.lock），防止冲突
    sudo git reset --hard HEAD
    # 拉取最新代码
    sudo git pull

    # 4. 虚拟机保命措施：检查硬件配置
    # 如果远程仓库里没放 hardware-configuration.nix，这里会自动生成一个
    # 防止你更新完重启后进不去系统
    if [ ! -f hardware-configuration.nix ]; then
        echo "🔧 生成硬件配置..."
        sudo nixos-generate-config --show-hardware-config | sudo tee hardware-configuration.nix > /dev/null
    fi

    # 5. 开始构建
    echo "🚀 开始构建系统..."
    sudo nixos-rebuild switch --flake .#nixos-server
  '';
};

  # --- 服务配置 ---
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false; 
    };
  };
  systemd.services.mount-disk-script = {
    description = "Run user defined mount script";
    # 随系统启动
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    before = [ "systemd-user-sessions.service" "podman.service" "podman.socket" ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";      
      ExecStart = "${pkgs.bash}/bin/bash /home/sakuya/podman/mount_disk.sh";
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

  systemd.tmpfiles.rules = [
    "f /var/lib/systemd/linger/sakuya 0644 root root -"
  ];

  # --- 系统状态版本 ---
  system.stateVersion = "25.11"; 
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}