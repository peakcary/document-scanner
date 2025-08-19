#!/bin/bash

# 无Docker部署脚本 - 直接使用系统服务

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
echo "  文档扫描器 - 传统部署方案"
echo "  直接使用Nginx + 系统服务"
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
    SERVICE_CMD="systemctl"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    UPDATE_CMD="yum update -y"
    INSTALL_CMD="yum install -y"
    SERVICE_CMD="systemctl"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf" 
    UPDATE_CMD="dnf update -y"
    INSTALL_CMD="dnf install -y"
    SERVICE_CMD="systemctl"
else
    print_error "不支持的系统类型"
    exit 1
fi

print_success "检测到包管理器: $PKG_MANAGER"

# 更新系统
print_step "更新系统..."
$UPDATE_CMD

# 安装Nginx
print_step "安装Nginx..."
$INSTALL_CMD nginx

# 启动并启用Nginx
$SERVICE_CMD start nginx
$SERVICE_CMD enable nginx

print_success "Nginx安装并启动完成"

# 创建网站目录
WEB_DIR="/var/www/document-scanner"
print_step "创建网站目录: $WEB_DIR"
mkdir -p $WEB_DIR

# 复制项目文件
print_step "部署项目文件..."
if [ -f "index.html" ]; then
    # 如果在项目目录内执行
    cp -r ./* $WEB_DIR/
elif [ -d "document-scanner" ]; then
    # 如果在父目录执行
    cp -r document-scanner/* $WEB_DIR/
elif [ -f "/tmp/document-scanner.tar.gz" ]; then
    # 如果有上传的压缩包
    cd /tmp
    tar -xzf document-scanner.tar.gz
    cp -r document-scanner/* $WEB_DIR/
else
    print_error "未找到项目文件"
    exit 1
fi

# 设置权限
chown -R nginx:nginx $WEB_DIR 2>/dev/null || chown -R www-data:www-data $WEB_DIR 2>/dev/null || chown -R apache:apache $WEB_DIR 2>/dev/null || true
chmod -R 755 $WEB_DIR

print_success "项目文件部署完成"

# 配置Nginx
print_step "配置Nginx..."

# 创建网站配置文件
cat > /etc/nginx/conf.d/document-scanner.conf << 'NGINX_CONF'
server {
    listen 80;
    server_name _;
    
    root /var/www/document-scanner;
    index index.html;
    
    # 安全设置
    server_tokens off;
    
    # 客户端上传文件大小限制
    client_max_body_size 100M;
    
    # 主要位置块
    location / {
        try_files $uri $uri/ /index.html;
        
        # 安全头
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
    }
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
    }
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json
        image/svg+xml;
    
    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 禁止访问敏感文件
    location ~* \.(env|log|conf|md)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
NGINX_CONF

# 测试Nginx配置
print_step "测试Nginx配置..."
nginx -t

if [ $? -eq 0 ]; then
    print_success "Nginx配置测试通过"
else
    print_error "Nginx配置有误"
    exit 1
fi

# 重新加载Nginx
print_step "重新加载Nginx..."
$SERVICE_CMD reload nginx

# 配置防火墙
print_step "配置防火墙..."
if command -v firewall-cmd &> /dev/null; then
    # CentOS/RHEL/Fedora
    systemctl start firewalld 2>/dev/null || true
    firewall-cmd --permanent --add-service=http 2>/dev/null || true
    firewall-cmd --permanent --add-service=https 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
    print_success "firewalld防火墙已配置"
elif command -v ufw &> /dev/null; then
    # Ubuntu/Debian
    ufw --force enable 2>/dev/null || true
    ufw allow 80 2>/dev/null || true
    ufw allow 443 2>/dev/null || true
    print_success "ufw防火墙已配置"
elif command -v iptables &> /dev/null; then
    # 通用iptables
    iptables -I INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
    print_success "iptables防火墙已配置"
else
    print_warning "未检测到防火墙，请手动开放80和443端口"
fi

# 获取服务器IP
print_step "获取服务器信息..."
SERVER_IP=$(curl -s ipinfo.io/ip 2>/dev/null || curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")

# 检查服务状态
print_step "检查服务状态..."
if $SERVICE_CMD is-active --quiet nginx; then
    print_success "Nginx服务运行正常"
else
    print_error "Nginx服务未正常运行"
    $SERVICE_CMD status nginx
    exit 1
fi

# 测试网站访问
print_step "测试网站访问..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    print_success "网站访问测试通过"
else
    print_warning "网站访问测试失败，HTTP状态码: $HTTP_STATUS"
fi

# 显示结果
echo
echo "=========================================="
print_success "🎉 部署完成！"
echo "=========================================="
echo
print_success "网站信息:"
print_success "  访问地址: http://$SERVER_IP"
print_success "  网站目录: $WEB_DIR"
print_success "  配置文件: /etc/nginx/conf.d/document-scanner.conf"
echo
print_success "管理命令:"
echo "  查看Nginx状态: systemctl status nginx"
echo "  重启Nginx: systemctl restart nginx"
echo "  重新加载配置: systemctl reload nginx"
echo "  查看访问日志: tail -f /var/log/nginx/access.log"
echo "  查看错误日志: tail -f /var/log/nginx/error.log"
echo
print_success "网站功能:"
echo "  ✅ 静态文件服务"
echo "  ✅ Gzip压缩"
echo "  ✅ 缓存优化"
echo "  ✅ 安全配置"
echo "  ✅ 大文件上传支持"
echo
print_success "🌐 请在浏览器中访问 http://$SERVER_IP 查看应用！"

# 创建管理脚本
print_step "创建管理脚本..."
cat > /usr/local/bin/scanner-manage << 'MANAGE_SCRIPT'
#!/bin/bash

case "$1" in
    start)
        systemctl start nginx
        echo "✅ Nginx已启动"
        ;;
    stop)
        systemctl stop nginx
        echo "⏹️ Nginx已停止"
        ;;
    restart)
        systemctl restart nginx
        echo "🔄 Nginx已重启"
        ;;
    reload)
        systemctl reload nginx
        echo "🔄 Nginx配置已重新加载"
        ;;
    status)
        systemctl status nginx
        ;;
    logs)
        echo "访问日志:"
        tail -f /var/log/nginx/access.log
        ;;
    errors)
        echo "错误日志:"
        tail -f /var/log/nginx/error.log
        ;;
    test)
        nginx -t
        ;;
    update)
        echo "更新网站文件..."
        if [ -f "/tmp/document-scanner.tar.gz" ]; then
            cd /tmp
            tar -xzf document-scanner.tar.gz
            cp -r document-scanner/* /var/www/document-scanner/
            systemctl reload nginx
            echo "✅ 更新完成"
        else
            echo "❌ 未找到更新文件"
        fi
        ;;
    *)
        echo "用法: $0 {start|stop|restart|reload|status|logs|errors|test|update}"
        echo ""
        echo "命令说明:"
        echo "  start   - 启动Nginx"
        echo "  stop    - 停止Nginx"
        echo "  restart - 重启Nginx"
        echo "  reload  - 重新加载配置"
        echo "  status  - 查看状态"
        echo "  logs    - 查看访问日志"
        echo "  errors  - 查看错误日志"
        echo "  test    - 测试配置"
        echo "  update  - 更新网站文件"
        exit 1
        ;;
esac
MANAGE_SCRIPT

chmod +x /usr/local/bin/scanner-manage
print_success "管理脚本已创建: scanner-manage"

echo
print_success "🎯 快速管理命令:"
echo "  scanner-manage start    # 启动服务"
echo "  scanner-manage status   # 查看状态"
echo "  scanner-manage logs     # 查看日志"
echo "  scanner-manage restart  # 重启服务"
echo
print_success "部署完成！享受你的文档扫描器吧！ 🚀"