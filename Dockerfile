FROM python:3.11-slim

# 避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 安装系统服务（不修改只读文件）
RUN apt-get update && apt-get install -y --no-install-recommends \
    systemd systemd-sysv openssh-server curl wget procps net-tools \
    ca-certificates tzdata cron htop iputils-ping dnsutils sudo vim \
    && rm -rf /var/lib/apt/lists/*

# 复制应用代码
COPY . /sing-box-subscribe
WORKDIR /sing-box-subscribe

# 安装 Python 依赖
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# 配置 SSH（只修改 sshd_config）
RUN sed -i 's/#*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "root:changeme123" | chpasswd \
    && mkdir -p /var/run/sshd

# 创建临时 DNS 和时区配置（运行时生效）
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf.dnsmasq \
    && echo "nameserver 8.8.4.4" >> /etc/resolv.conf.dnsmasq \
    && ln -sf /usr/share/zoneinfo/UTC /etc/localtime.default \
    && echo "UTC" > /etc/timezone.default

# 复制 systemd 服务
COPY sing-box-subscribe.service /etc/systemd/system/

# 启用服务
RUN systemctl enable ssh.service cron.service sing-box-subscribe.service

# 暴露端口
EXPOSE 22 5000

# OCI
