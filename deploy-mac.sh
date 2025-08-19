#!/bin/bash

# Mac本地部署脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[步骤]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

echo "=================================="
echo "  文档扫描器 - Mac本地部署"
echo "  适用于本地开发测试"
echo "=================================="

# 检查Docker
print_step "检查Docker状态..."
if ! command -v docker &> /dev/null; then
    echo "请先安装Docker Desktop for Mac"
    echo "下载地址: https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "请先启动Docker Desktop"
    exit 1
fi

print_success "Docker运行正常"

# 创建兼容的docker-compose配置
print_step "创建Docker配置..."
cat > docker-compose-local.yml << 'EOF'
version: '3.3'

services:
  document-scanner:
    image: nginx:alpine
    container_name: document-scanner-local
    ports:
      - "8080:80"
    volumes:
      - ./:/usr/share/nginx/html
      - ./nginx-local.conf:/etc/nginx/nginx.conf
    restart: unless-stopped
EOF

# 创建本地nginx配置
print_step "创建本地nginx配置..."
cat > nginx-local.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    sendfile on;
    keepalive_timeout 65;
    client_max_body_size 100M;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/js
        text/javascript
        application/javascript
        application/json
        image/svg+xml;
    
    server {
        listen 80;
        server_name localhost;
        
        root /usr/share/nginx/html;
        index index.html;
        
        location / {
            try_files $uri $uri/ /index.html;
            
            location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
            }
        }
        
        location ~ /\. {
            deny all;
        }
    }
}
EOF

# 停止旧容器
print_step "停止旧容器..."
docker-compose -f docker-compose-local.yml down 2>/dev/null || true
docker stop document-scanner-local 2>/dev/null || true
docker rm document-scanner-local 2>/dev/null || true

# 启动服务
print_step "启动应用..."
docker-compose -f docker-compose-local.yml up -d

# 等待服务启动
sleep 5

# 检查服务状态
if docker ps | grep -q document-scanner-local; then
    print_success "应用启动成功！"
    echo
    echo "=========================================="
    print_success "本地部署完成！"
    echo "=========================================="
    echo
    print_success "本地访问地址: http://localhost:8080"
    echo
    echo "管理命令:"
    echo "  查看状态: docker ps"
    echo "  查看日志: docker-compose -f docker-compose-local.yml logs -f"
    echo "  重启应用: docker-compose -f docker-compose-local.yml restart"
    echo "  停止应用: docker-compose -f docker-compose-local.yml down"
    echo
    print_success "请在浏览器中访问 http://localhost:8080 测试应用"
else
    echo "应用启动失败，查看日志："
    docker-compose -f docker-compose-local.yml logs
    exit 1
fi