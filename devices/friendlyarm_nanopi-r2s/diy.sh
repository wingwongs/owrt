#!/bin/bash

# 调用 rockchip_armv8 通用的自定义脚本
SHELL_FOLDER=$(dirname $(readlink -f "$0"))
/bin/bash "$SHELL_FOLDER/../rockchip_armv8/diy.sh"

shopt -s extglob
# 解决 linux-6.12.92 下 953-net-patch-linux-kernel-to-support-shortcut-fe.patch 冲突问题
# 在编译 rockchip_armv8 架构时，直接删除此补丁，因为 SFE 在 6.12 内核中通常需要清理此残留补丁以防冲突
rm -f target/linux/generic/hack-6.12/952-add-net-conntrack-events-support-multiple-registrant.patch
rm -f target/linux/generic/hack-6.12/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
rm -f target/linux/generic/hack-6.12/930-Revert-Revert-Revert-driver-core-Set-fw_devlink-on-b.patch
rm -rf feeds/kiddin9/luci-app-turboacc
rm -rf feeds/kiddin9/shortcut-fe
#sed -i "s/CONFIG_PACKAGE_kmod-shortcut-fe=y/# CONFIG_PACKAGE_kmod-shortcut-fe is not set/" .config

# 创建首开机脚本以设定网络配置、网口和IP/DNS等
mkdir -p files/etc/uci-defaults
cat << 'EOF' > files/etc/uci-defaults/99-custom-settings
#!/bin/sh

# 1. 网络设置：后台默认地址192.168.1.250，默认网关192.168.1.1
uci set network.lan.ipaddr='192.168.1.250'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.gateway='192.168.1.1'
uci set network.lan.dns='114.114.114.114'

# IPv6 支持与通告设置
uci set network.lan.ipv6='1'

# 2. 绑定网口与设置 wan6
# 绑定物理网口：lan -> eth0, wan -> eth1
uci set network.lan.device='eth0'
uci set network.wan.device='eth1'

# 将 wan6 的物理接口也设置为 eth1
# 在 OpenWrt 中，wan6 可能会直接使用 @wan，如果显式设定 device，则设定为 eth1
if uci get network.wan6 >/dev/null 2>&1; then
    uci set network.wan6.device='eth1'
fi

# 3. 设置默认密码为 8890019
# OpenWrt 密码是通过 shadow 文件设置，使用 chpasswd 或 passwd 修改
# 在 uci-defaults 脚本中我们可以直接执行修改命令或将哈希写入 shadow 
# 这里为了可靠性，使用最直接的办法：在开机时通过 chpasswd 修改
echo "root:8890019" | chpasswd

# 保存生效
uci commit network
uci commit dhcp

exit 0
EOF
chmod +x files/etc/uci-defaults/99-custom-settings

# 删除原有的 luci-app-tailscale-community 目录（如果被 feeds 抓取或存在于 package/feeds/kiddin9 中，需在编译diy脚本中清理并重新 clone）
# 由于 kiddin9-packages 内置了 tailscale-community，我们需要确保在 feeds 之后将其替换。
# 在编译过程中，diy.sh 执行时 feeds 已经更新完毕，此时可以强行删除 feeds 里的该 app，并从指定仓库 clone。
# 我们在编译的当前环境把删除并重新拉取的逻辑写在 diy.sh 尾部：
# rm -rf feeds/kiddin9/luci-app-tailscale-community feeds/kiddin9/tailscale
# rm -rf package/feeds/kiddin9/luci-app-tailscale-community package/feeds/kiddin9/tailscale

# git clone --depth=1 https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community package/luci-app-tailscale-community
# 同时确保 tailscale 本体包存在（如果 tailscale 没有了，我们需要从 feeds/packages 或 feeds/kiddin9 重新拉取，或者保留原 feeds/kiddin9 中的 tailscale 本体）
