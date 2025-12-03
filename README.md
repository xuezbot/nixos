# NixOS 家庭服务器配置

本仓库包含一份用于家庭服务器的 NixOS 配置，功能包括用于容器管理的 Podman、用于图形化管理的 Portainer 以及作为反向代理的 Caddy。

## 功能特性

- **操作系统**: NixOS (基于 Flake)
- **容器引擎**: Podman (兼容 Docker)
- **容器管理**: Portainer (可通过 `pd.home.lan` 访问)
- **反向代理**: Caddy
  - `home.lan`: 欢迎页面
  - `pd.home.lan`: Portainer
  - `*.home.lan`: 泛域名占位符
- **远程访问**: 已启用 SSH

## 安装指南

1.  **克隆仓库** 到 `/etc/nixos` (或创建软链接):
    ```bash
    git clone https://github.com/yourusername/nixos-config.git /etc/nixos
    ```

2.  **生成硬件配置**:
    如果是全新安装，请生成针对您硬件的配置文件:
    ```bash
    nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
    ```
    *注意: 仓库中包含的 `hardware-configuration.nix` 仅为占位符。*

3.  **应用配置**:
    ```bash
    nixos-rebuild switch --flake .#nixos-server
    ```

4.  **DNS 设置**:
    确保您的本地 DNS 或客户端 `hosts` 文件将 `home.lan`、`pd.home.lan` 以及其他子域名指向服务器的 IP 地址。

## 自定义

- **用户**: 编辑 `configuration.nix` 以设置您的用户名和 SSH 密钥。
- **时区/语言**: 如果不在 Asia/Shanghai (中国标准时间)，请在 `configuration.nix` 中进行调整。
