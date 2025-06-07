#!/bin/bash

# gai.conf 路径
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
    echo "[*] 使用 ping 测试 www.google.com 首选协议："
    
    echo "    -> 尝试 ping -6（IPv6）..."
    if ping -6 -c 1 -W 1 www.google.com &>/dev/null; then
        echo "       IPv6 可达"
    else
        echo "       IPv6 不可达或被屏蔽"
    fi

    echo "    -> 尝试 ping -4（IPv4）..."
    if ping -4 -c 1 -W 1 www.google.com &>/dev/null; then
        echo "       IPv4 可达"
    else
        echo "       IPv4 不可达或被屏蔽"
    fi

    echo "    -> 尝试 ping（自动选择）..."
    if ping -c 1 -W 1 www.google.com | grep -q "bytes from"; then
        proto=$(ping -c 1 -W 1 www.google.com 2>/dev/null | head -n1)
        if echo "$proto" | grep -q "\("; then
            ip=$(echo "$proto" | sed -n 's/.*(\(.*\)).*/\1/p')
            if echo "$ip" | grep -q ":"; then
                echo "       自动选择结果：IPv6"
            else
                echo "       自动选择结果：IPv4"
            fi
        else
            echo "       无法判断协议"
        fi
    else
        echo "       ping 失败，无法检测"
    fi
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
    echo "  test    使用 ping 测试当前解析优先级"
}

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
