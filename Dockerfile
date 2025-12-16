FROM debian:bookworm-slim

# 避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive

# 创建临时 resolv.conf
RUN echo "nameserver 8.8.8.8" > /tmp/resolv.conf \
    && echo "nameserver 8.8.4.4" >> /tmp/resolv.conf

# 安装完整系统服务
RUN apt-get update && apt-get install -y --no-install-recommends \
    systemd systemd-sysv openssh-server curl wget procps net-tools \
    ca-certificates tzdata cron htop iputils-ping dnsutils sudo vim \
    && rm -rf /var/lib/apt/lists/*

# 配置 SSH (允许 root 登录)
RUN sed -i 's/#*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "root:changeme123" | chpasswd \
    && mkdir -p /var/run/sshd

# 时区配置
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && echo "UTC" > /etc/timezone

# 启用服务
RUN systemctl enable ssh cron

# 清理临时文件
RUN rm -rf /tmp/resolv.conf /var/tmp/* /tmp/*

# 暴露 SSH 端口
EXPOSE 22

# OCI LXC 兼容：systemd 作为 PID 1
CMD ["/lib/systemd/systemd"]
