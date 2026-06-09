#!/bin/bash

# 调用 rockchip_armv8 通用的自定义脚本
SHELL_FOLDER=$(dirname $(readlink -f "$0"))
/bin/bash "$SHELL_FOLDER/../rockchip_armv8/diy.sh"

# 创建首开机脚本以设定网络配置、旁路由模式、网口和IP/DNS等
mkdir -p files/etc/uci-defaults
cat << 'EOF' > files/etc/uci-defaults/99-custom-settings
#!/bin/sh

# 1. 旁路由IP与网络设置：默认后台192.168.2.250，默认网关192.168.2.1，DNS为114.114.114.114
uci set network.lan.ipaddr='192.168.2.250'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.gateway='192.168.2.1'
uci set network.lan.dns='114.114.114.114'

# IPv6 支持与通告设置
uci set network.lan.ipv6='1'

# 2. 绑定网口：WAN 设置为 eth1 物理网口，LAN 设置为 eth0 物理网口
uci set network.lan.device='eth0'
uci set network.wan.device='eth1'

# 3. 旁路由模式需要关闭自身DHCP服务 (由主路由分发DHCP)
uci set dhcp.lan.ignore='1'

# 保存生效
uci commit network
uci commit dhcp

exit 0
EOF
chmod +x files/etc/uci-defaults/99-custom-settings
