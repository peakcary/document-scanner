#!/bin/bash

# 通用部署脚本 - 自动检测系统类型

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[步骤]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

echo "=================================="
echo "  文档扫描器 - 通用部署脚本"
echo "  自动检测系统类型"
echo "=================================="

# 检测系统类型
print_step "检测系统类型..."

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux系统
    if command -v apt &> /dev/null; then
        OS_TYPE="ubuntu"
        PKG_MANAGER="apt"
        PKG_UPDATE="apt update && apt upgrade -y"
        PKG_INSTALL="apt install -y"
    elif command -v yum &> /dev/null; then
        OS_TYPE="centos"
        PKG_MANAGER="yum"
        PKG_UPDATE="yum update -y"
        PKG_INSTALL="yum install -y"
    elif command -v dnf &> /dev/null; then
        OS_TYPE="fedora"
        PKG_MANAGER="dnf"
        PKG_UPDATE="dnf update -y"
        PKG_INSTALL="dnf install -y"
    else
        print_error "不支持的Linux发行版"
        exit 1
    fi
    print_success "检测到Linux系统: $OS_TYPE"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
    print_warning "检测到macOS系统，使用本地部署模式"
else
    print_error "不支持的操作系统: $OSTYPE"
    exit 1
fi

# 检查是否为root用户（Linux）
if [[ "$OS_TYPE" != "macos" ]] && [[ $EUID -ne 0 ]]; then
    print_error "请使用root用户运行此脚本"
    echo "使用命令: sudo $0"
    exit 1
fi

# macOS本地部署
if [[ "$OS_TYPE" == "macos" ]]; then
    print_step "启动本地开发服务器..."
    
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        print_error "未找到Python，请先安装Python"
        exit 1
    fi
    
    print_success "使用 $PYTHON_CMD 启动HTTP服务器"
    echo ""
    print_success "访问地址: http://localhost:8000"
    echo "按 Ctrl+C 停止服务器"
    echo ""
    
    $PYTHON_CMD -m http.server 8000
    exit 0
fi

# Linux服务器部署
print_step "更新系统包..."
$PKG_UPDATE

# 安装基础软件
print_step "安装基础软件..."
if [[ "$OS_TYPE" == "ubuntu" ]]; then
    $PKG_INSTALL curl wget git unzip software-properties-common
elif [[ "$OS_TYPE" == "centos" ]]; then
    $PKG_INSTALL curl wget git unzip epel-release
elif [[ "$OS_TYPE" == "fedora" ]]; then
    $PKG_INSTALL curl wget git unzip
fi

# 安装Docker
print_step "安装Docker..."
if ! command -v docker &> /dev/null; then
    print_step "下载并安装Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
    systemctl enable docker
    rm get-docker.sh
    print_success "Docker安装完成"
else
    print_success "Docker已安装"
    systemctl start docker 2>/dev/null || true
    systemctl enable docker 2>/dev/null || true
fi

# 安装Docker Compose
print_step "安装Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    print_step "下载Docker Compose..."
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose安装完成"
else
    print_success "Docker Compose已安装"
fi

# 创建部署目录
DEPLOY_PATH="/var/www/document-scanner"
print_step "创建部署目录..."
mkdir -p $DEPLOY_PATH

# 复制文件
print_step "复制应用文件..."
cp -r ./* $DEPLOY_PATH/ 2>/dev/null || cp -r * $DEPLOY_PATH/

# 创建HTTP版nginx配置
print_step "创建nginx配置..."
cat > $DEPLOY_PATH/nginx-simple.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    sendfile on;
    keepalive_timeout 65;
    client_max_body_size 100M;
    
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/javascript
        application/javascript
        application/json;
    
    server {
        listen 80;
        server_name _;
        
        root /usr/share/nginx/html;
        index index.html;
        
        location / {
            try_files $uri $uri/ /index.html;
        }
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        location ~ /\. {
            deny all;
        }
    }
}
EOF

# 创建docker-compose配置
print_step "创建Docker配置..."
cat > $DEPLOY_PATH/docker-compose-simple.yml << 'EOF'
version: '2'

services:
  web:
    image: nginx:alpine
    container_name: document-scanner
    ports:
      - "80:80"
    volumes:
      - ./:/usr/share/nginx/html
      - ./nginx-simple.conf:/etc/nginx/nginx.conf
    restart: unless-stopped
EOF

# 设置权限
print_step "设置文件权限..."
chown -R root:root $DEPLOY_PATH 2>/dev/null || true
chmod -R 755 $DEPLOY_PATH

# 停止旧容器
print_step "停止旧服务..."
cd $DEPLOY_PATH
docker-compose -f docker-compose-simple.yml down 2>/dev/null || true
docker stop document-scanner 2>/dev/null || true
docker rm document-scanner 2>/dev/null || true

# 启动新服务
print_step "启动应用..."
docker-compose -f docker-compose-simple.yml up -d

# 等待服务启动
sleep 5

# 检查服务状态
if docker ps | grep -q document-scanner; then
    print_success "应用启动成功！"
else
    print_error "应用启动失败，查看日志："
    docker-compose -f docker-compose-simple.yml logs
    exit 1
fi

# 配置防火墙
print_step "配置防火墙..."
if command -v firewall-cmd &> /dev/null; then
    # CentOS/RHEL
    systemctl start firewalld 2>/dev/null || true
    firewall-cmd --permanent --add-service=http 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
    print_success "firewalld防火墙已配置"
elif command -v ufw &> /dev/null; then
    # Ubuntu
    ufw --force enable 2>/dev/null || true
    ufw allow 80 2>/dev/null || true
    print_success "ufw防火墙已配置"
fi

# 获取服务器IP
SERVER_IP=$(curl -s ipinfo.io/ip 2>/dev/null || curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")

# 显示结果
echo
echo "=========================================="
print_success "部署完成！"
echo "=========================================="
echo
print_success "访问地址: http://$SERVER_IP"
print_success "本地访问: http://localhost"
echo
print_success "管理命令:"
echo "  查看状态: docker ps"
echo "  查看日志: cd $DEPLOY_PATH && docker-compose -f docker-compose-simple.yml logs -f"
echo "  重启服务: cd $DEPLOY_PATH && docker-compose -f docker-compose-simple.yml restart"
echo "  停止服务: cd $DEPLOY_PATH && docker-compose -f docker-compose-simple.yml down"
echo
print_success "🎉 文档扫描器已成功部署！"
print_success "请在浏览器中访问 http://$SERVER_IP 测试应用"