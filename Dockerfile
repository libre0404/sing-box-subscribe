FROM python:3.11-slim

# 环境变量
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    APP_USER=appuser \
    APP_HOME=/app

# 安装基础依赖（根据需要裁剪）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

# 创建非 root 用户和工作目录
RUN useradd -m -d ${APP_HOME} ${APP_USER}
WORKDIR ${APP_HOME}

# 拷贝依赖和代码
COPY requirements.txt ${APP_HOME}/
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY . ${APP_HOME}

# 权限
RUN chown -R ${APP_USER}:${APP_USER} ${APP_HOME}
USER ${APP_USER}

# 暴露端口（与你的 api/app.py 使用的端口一致）
EXPOSE 5000

# 启动命令
CMD ["python", "api/app.py"]
