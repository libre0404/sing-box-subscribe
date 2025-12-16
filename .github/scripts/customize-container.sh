#!/bin/bash
# 容器定制脚本
# 用于在 rootfs 中安装和配置 sing-box-subscribe 相关依赖

set -e

ROOTFS="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*"
    exit 1
}

log "开始容器定制，Rootfs: $ROOTFS"

# 验证 rootfs
if [ ! -d "$ROOTFS/etc" ]; then
    error "无效的 rootfs 路径：$ROOTFS"
fi

log "配置系统环境..."

# 设置时区
sudo chroot "$ROOTFS" bash -c '
    echo "Asia/Shanghai" > /etc/timezone
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
' || warn "时区设置失败"

# 更新包管理器
log "更新包管理器缓存..."
sudo chroot "$ROOTFS" bash -c '
    apt-get update || true
    apt-get install -y apt-utils
' || warn "包管理器更新失败"

# 安装基础工具
log "安装基础工具..."
sudo chroot "$ROOTFS" bash -c '
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common \
        git \
        vim \
        nano \
        htop \
        net-tools \
        iputils-ping \
        dnsutils \
        netcat-openbsd \
        openssh-server \
        openssh-client \
        systemd \
        systemd-sysv \
        openrc || true
' || warn "基础工具安装失败"

# 安装 Docker（可选）
log "安装 Docker..."
sudo chroot "$ROOTFS" bash -c '
    curl -fsSL https://get.docker.com -o get-docker.sh 2>/dev/null && \
    bash get-docker.sh || \
    apt-get install -y docker.io || \
    apt-get install -y docker || true
    
    rm -f get-docker.sh
' || warn "Docker 安装失败"

# 安装 Node.js（用于 Web UI）
log "安装 Node.js..."
sudo chroot "$ROOTFS" bash -c '
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - 2>/dev/null && \
    apt-get install -y nodejs || \
    apt-get install -y nodejs || true
' || warn "Node.js 安装失败"

# 安装 Python 3
log "安装 Python 3..."
sudo chroot "$ROOTFS" bash -c '
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev || true
' || warn "Python 3 安装失败"

# 清理包管理器缓存
log "清理包管理器缓存..."
sudo chroot "$ROOTFS" bash -c '
    apt-get clean
    apt-get autoclean
    apt-get autoremove -y || true
    rm -rf /var/lib/apt/lists/*
    rm -rf /tmp/*
    rm -rf /var/tmp/*
' || warn "清理缓存失败"

# 配置 SSH
log "配置 SSH..."
sudo chroot "$ROOTFS" bash -c '
    mkdir -p /run/sshd
    chmod 0755 /run/sshd
    sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config || true
    sed -i "s/#PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config || true
' || warn "SSH 配置失败"

# 创建初始化脚本
log "创建初始化脚本..."
sudo tee "$ROOTFS/usr/local/bin/init-container.sh" > /dev/null << 'EOF'
#!/bin/bash
# 容器初始化脚本

echo "初始化 sing-box-subscribe 容器..."

# 启动 SSH
service ssh start || systemctl start ssh || true

# 输出网络信息
echo "容器网络信息："
ip addr show

# 初始化日志
echo "[$(date)] 容器初始化完成" >> /var/log/init.log

echo "容器初始化完成，可以使用 SSH 连接"
EOF

sudo chmod +x "$ROOTFS/usr/local/bin/init-container.sh"

# 配置启动脚本
log "配置启动脚本..."
sudo tee "$ROOTFS/etc/rc.local" > /dev/null << 'EOF'
#!/bin/bash
# 容器启动时执行的脚本

/usr/local/bin/init-container.sh

exit 0
EOF

sudo chmod +x "$ROOTFS/etc/rc.local"

# 验证安装
log "验证安装..."
sudo chroot "$ROOTFS" bash -c '
    echo "=== 系统信息 ==="
    lsb_release -a 2>/dev/null || cat /etc/os-release || true
    
    echo ""
    echo "=== 已安装的关键工具 ==="
    echo "curl: $(curl --version 2>/dev/null | head -1 || echo "未安装")"
    echo "git: $(git --version 2>/dev/null || echo "未安装")"
    echo "python3: $(python3 --version 2>/dev/null || echo "未安装")"
    echo "nodejs: $(node --version 2>/dev/null || echo "未安装")"
    echo "docker: $(docker --version 2>/dev/null || echo "未安装")"
' || warn "验证失败"

log "${GREEN}容器定制完成！${NC}"
log "输出的 rootfs 可用于生成 PVE 容器镜像"
