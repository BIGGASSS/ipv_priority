#!/bin/bash

# 文件路径
GAI_CONF="/etc/gai.conf"
BACKUP_CONF="/etc/gai.conf.bak"

function check_priority() {
    echo "[*] 当前 IPv6/IPv4 优先级状态："
    if grep -q "^precedence ::ffff:0:0/96 100" "$GAI_CONF"; then
        echo "    -> 当前为 IPv4 优先"
    elif grep -q "^#precedence ::ffff:0:0/96 100" "$GAI_CONF" || ! grep -q "precedence ::ffff:0:0/96 100" "$GAI_CONF"; then
        echo "    -> 当前为 IPv6 优先（或默认）"
    else
        echo "    -> 状态未知，手动检查 $GAI_CONF"
    fi
}

function test_resolution() {
    echo "[*] 检测 getaddrinfo 返回顺序（getent hosts www.google.com）："
    getent hosts www.google.com | head -n 5
}

function set_ipv4_priority() {
    echo "[*] 切换为 IPv4 优先..."
    [ ! -f "$BACKUP_CONF" ] && cp "$GAI_CONF" "$BACKUP_CONF"

    if grep -q "^#precedence ::ffff:0:0/96 100" "$GAI_CONF"; then
        sed -i 's/^#precedence ::ffff:0:0\/96 100/precedence ::ffff:0:0\/96 100/' "$GAI_CONF"
    elif ! grep -q "precedence ::ffff:0:0/96 100" "$GAI_CONF"; then
        echo "precedence ::ffff:0:0/96 100" >> "$GAI_CONF"
    fi

    echo "    -> 已设置为 IPv4 优先"
}

function set_ipv6_priority() {
    echo "[*] 切换为 IPv6 优先..."
    [ ! -f "$BACKUP_CONF" ] && cp "$GAI_CONF" "$BACKUP_CONF"
    sed -i 's/^precedence ::ffff:0:0\/96 100/#precedence ::ffff:0:0\/96 100/' "$GAI_CONF"
    echo "    -> 已设置为 IPv6 优先"
}

function usage() {
    echo "用法: $0 [check|ipv4|ipv6|test]"
    echo "  check   显示当前优先级配置"
    echo "  ipv4    设置为 IPv4 优先"
    echo "  ipv6    设置为 IPv6 优先"
    echo "  test    测试当前解析优先级"
}

# 主流程
case "$1" in
    check)
        check_priority
        ;;
    ipv4)
        set_ipv4_priority
        ;;
    ipv6)
        set_ipv6_priority
        ;;
    test)
        test_resolution
        ;;
    *)
        usage
        ;;
esac
