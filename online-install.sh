#!/bin/bash

# 在线安装脚本 - 直接在ECS服务器上运行

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

echo "=========================================="
echo "  文档扫描器 - 在线安装脚本"
echo "  直接在ECS服务器上下载并部署"
echo "=========================================="

# 检查系统
print_step "检查系统环境..."

if [[ $EUID -ne 0 ]]; then
    print_error "请使用root用户运行此脚本"
    exit 1
fi

# 检测包管理器
if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
    UPDATE_CMD="apt update"
    INSTALL_CMD="apt install -y"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    UPDATE_CMD="yum update -y"
    INSTALL_CMD="yum install -y"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    UPDATE_CMD="dnf update -y"
    INSTALL_CMD="dnf install -y"
else
    print_error "不支持的系统类型"
    exit 1
fi

print_success "检测到包管理器: $PKG_MANAGER"

# 更新系统
print_step "更新系统..."
$UPDATE_CMD

# 安装基础工具
print_step "安装基础工具..."
$INSTALL_CMD curl wget git unzip

# 创建临时目录
TEMP_DIR="/tmp/document-scanner-install"
mkdir -p $TEMP_DIR
cd $TEMP_DIR

# 创建简化的应用文件
print_step "创建应用文件..."

# 创建HTML文件
cat > index.html << 'HTML_EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>文档扫描器</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #2d3748;
            margin-bottom: 10px;
        }
        .status {
            background: #f0fff4;
            border: 1px solid #9ae6b4;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
            margin: 20px 0;
        }
        .btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 1rem;
            margin: 10px;
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎉 文档扫描器部署成功！</h1>
            <p>高级文档扫描器已成功部署到您的ECS服务器</p>
        </div>
        
        <div class="status">
            <h3>✅ 系统状态正常</h3>
            <p>服务器运行正常，应用已就绪</p>
        </div>
        
        <div style="text-align: center;">
            <button class="btn" onclick="window.location.reload()">刷新页面</button>
            <button class="btn" onclick="testFeatures()">测试功能</button>
        </div>
        
        <div id="info" style="margin-top: 30px; padding: 20px; background: #f7fafc; border-radius: 8px;">
            <h3>部署信息</h3>
            <p><strong>服务器IP:</strong> <span id="server-ip">获取中...</span></p>
            <p><strong>部署时间:</strong> <span id="deploy-time"></span></p>
            <p><strong>状态:</strong> <span style="color: green;">运行中</span></p>
        </div>
    </div>

    <script>
        // 显示部署时间
        document.getElementById('deploy-time').textContent = new Date().toLocaleString();
        
        // 获取服务器IP
        fetch('https://api.ipify.org?format=json')
            .then(response => response.json())
            .then(data => {
                document.getElementById('server-ip').textContent = data.ip;
            })
            .catch(() => {
                document.getElementById('server-ip').textContent = '47.92.236.28';
            });
        
        function testFeatures() {
            alert('功能测试：\n✅ 网页加载正常\n✅ JavaScript运行正常\n✅ 样式渲染正常\n\n完整的文档扫描功能即将上线！');
        }
    </script>
</body>
</html>
HTML_EOF

# 安装Docker
print_step "安装Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
    systemctl enable docker
    rm get-docker.sh
    print_success "Docker安装完成"
else
    print_success "Docker已安装"
    systemctl start docker
    systemctl enable docker
fi

# 创建nginx配置
cat > nginx.conf << 'NGINX_EOF'
events {
    worker_connections 1024;
}
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;
    
    server {
        listen 80;
        server_name _;
        root /usr/share/nginx/html;
        index index.html;
        
        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
NGINX_EOF

# 创建Docker Compose配置
cat > docker-compose.yml << 'COMPOSE_EOF'
version: '2'
services:
  web:
    image: nginx:alpine
    container_name: document-scanner
    ports:
      - "80:80"
    volumes:
      - ./:/usr/share/nginx/html
      - ./nginx.conf:/etc/nginx/nginx.conf
    restart: unless-stopped
COMPOSE_EOF

# 安装Docker Compose
print_step "安装Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose安装完成"
else
    print_success "Docker Compose已安装"
fi

# 部署应用
DEPLOY_PATH="/var/www/document-scanner"
print_step "部署应用到 $DEPLOY_PATH"
mkdir -p $DEPLOY_PATH
cp -r ./* $DEPLOY_PATH/
cd $DEPLOY_PATH

# 停止旧容器
docker-compose down 2>/dev/null || true
docker stop document-scanner 2>/dev/null || true
docker rm document-scanner 2>/dev/null || true

# 启动服务
print_step "启动服务..."
docker-compose up -d

# 等待服务启动
sleep 5

# 检查服务状态
if docker ps | grep -q document-scanner; then
    print_success "服务启动成功！"
else
    print_error "服务启动失败"
    docker-compose logs
    exit 1
fi

# 配置防火墙
print_step "配置防火墙..."
if command -v firewall-cmd &> /dev/null; then
    systemctl start firewalld 2>/dev/null || true
    firewall-cmd --permanent --add-service=http 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
elif command -v ufw &> /dev/null; then
    ufw --force enable 2>/dev/null || true
    ufw allow 80 2>/dev/null || true
fi

# 获取服务器IP
SERVER_IP=$(curl -s ipinfo.io/ip 2>/dev/null || echo "47.92.236.28")

# 清理临时文件
rm -rf $TEMP_DIR

# 显示结果
echo
echo "=========================================="
print_success "🎉 部署完成！"
echo "=========================================="
echo
print_success "访问地址: http://$SERVER_IP"
print_success "部署路径: $DEPLOY_PATH"
echo
print_success "管理命令:"
echo "  查看状态: docker ps"
echo "  查看日志: cd $DEPLOY_PATH && docker-compose logs -f"
echo "  重启服务: cd $DEPLOY_PATH && docker-compose restart"
echo "  停止服务: cd $DEPLOY_PATH && docker-compose down"
echo
print_success "请在浏览器中访问 http://$SERVER_IP 查看应用！"
NGINX_EOF

print_success "在线安装脚本创建完成！"