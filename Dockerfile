FROM debian:bookworm-slim

# 避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive

# 安装完整系统服务
RUN apt-get update && apt-get install -y --no-install-recommends \
    systemd systemd-sysv openssh-server curl wget procps net-tools \
    ca-certificates tzdata cron htop iputils-ping dnsutils sudo vim \
    && rm -rf /var/lib/apt/lists/*

# 配置 systemd
RUN systemctl enable ssh cron

# 配置 SSH (允许 root 登录)
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "root:changeme123" | chpasswd

# 时区
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# DNS
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf

# OCI LXC 兼容：使用 systemd 作为入口
CMD ["/lib/systemd/systemd"]
