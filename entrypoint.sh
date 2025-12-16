#!/bin/bash
# 运行时配置（解决 Docker build 只读问题）

# 设置 DNS（覆盖只读 resolv.conf）
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

# 设置时区
cp /etc/localtime.default /etc/localtime
cp /etc/timezone.default /etc/timezone

# 启动 systemd
exec /lib/systemd/systemd
