#!/bin/sh
# immortalwrt 首次启动脚本 /etc/uci-defaults/99-custom.sh

LOGFILE="/tmp/custom-init.log"

# 设置防火墙允许内网流量
uci set firewall.@zone[1].input='ACCEPT'

# 设置 DHCP 域名映射解决安卓 TV 网络问题
uci add dhcp domain
uci set "dhcp.@domain[-1].name=time.android.com"
uci set "dhcp.@domain[-1].ip=203.107.6.88"

# 设置 LAN IP 地址
uci set network.lan.ipaddr='192.168.8.1'
echo "set 192.168.8.1 at $(date)" >> $LOGFILE

# 设置 root 密码
echo -e "1234qwer\n1234qwer" | passwd root

# 读取 PPPoE 设置（由 build.sh 写入）
SETTINGS_FILE="/etc/config/pppoe-settings"
if [ -f "$SETTINGS_FILE" ]; then
    . "$SETTINGS_FILE"
    echo "print enable_pppoe value=== $enable_pppoe" >> $LOGFILE
    if [ "$enable_pppoe" = "yes" ]; then
        echo "PPPoE is enabled at $(date)" >> $LOGFILE
        uci set network.wan.proto='pppoe'                
        uci set network.wan.username=$pppoe_account     
        uci set network.wan.password=$pppoe_password     
        uci set network.wan.peerdns='1'                  
        uci set network.wan.auto='1' 
        echo "PPPoE configuration completed successfully." >> $LOGFILE
    else
        echo "PPPoE is not enabled. Skipping configuration." >> $LOGFILE
    fi
else
    echo "PPPoE settings file not found. Skipping." >> $LOGFILE
fi

# 设置所有网口可访问 ttyd 网页终端
uci delete ttyd.@ttyd[0].interface

# 设置所有网口可 SSH 连接
uci set dropbear.@dropbear[0].Interface=''

# 配置 2.4G WiFi（默认禁用）
uci set wireless.@wifi-iface[0].ssid='YYDS'
uci set wireless.@wifi-iface[0].encryption='psk2'
uci set wireless.@wifi-iface[0].key='1234qwer'
uci set wireless.@wifi-iface[0].disabled='1'  # 禁用
uci set wireless.radio0.channel='auto'
uci set wireless.radio0.bandwidth='20'

# 配置 5G WiFi（默认启用）
uci set wireless.@wifi-iface[1].ssid='DTSJ'
uci set wireless.@wifi-iface[1].encryption='psk2'
uci set wireless.@wifi-iface[1].key='yang6789'
uci set wireless.@wifi-iface[1].disabled='0'
uci set wireless.radio1.channel='auto'
uci set wireless.radio1.bandwidth='160'

# 添加 OpenClash 自动更新任务（每天凌晨4点）
cron_job="0 4 * * * /usr/bin/curl -sSL -4 https://testingcf.jsdelivr.net/gh/dotowin/Custom_OpenClash_Rules@refs/heads/main/shell/install_openclash_dev_update.sh | /bin/sh > /dev/null 2>&1"
grep -qF "$cron_job" /etc/crontabs/root || echo "$cron_job" >> /etc/crontabs/root

uci commit

exit 0

