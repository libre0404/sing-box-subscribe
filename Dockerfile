FROM python:3.11-slim

# 避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 安装系统依赖 + Python 环境
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

# 配置 SSH (root 登录)
RUN sed -i 's/#*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "root:changeme123" | chpasswd \
    && mkdir -p /var/run/sshd

# 时区 + DNS
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && echo "UTC" > /etc/timezone \
    && echo "nameserver 8.8.8.8" > /etc/resolv.conf

# 启用服务
RUN systemctl enable ssh cron

# 暴露端口
EXPOSE 22 5000

# OCI LXC 兼容：systemd 启动（自动运行您的 Python app）
CMD ["/lib/systemd/systemd"]
