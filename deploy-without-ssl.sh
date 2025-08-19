#!/bin/bash

# 无Docker版本的部署脚本（使用Python HTTP服务器）

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
echo "  文档扫描器 - Python部署版本"
echo "  无需Docker，使用Python HTTP服务器"
echo "=================================="

# 检测系统类型
print_step "检测系统类型..."
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

# 安装Python和基础工具
print_step "安装Python和基础工具..."
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
    print_success "Python3已安装"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
    print_success "Python已安装"
else
    print_step "安装Python3..."
    $INSTALL_CMD python3
    PYTHON_CMD="python3"
    print_success "Python3安装完成"
fi

# 安装其他必要工具
$INSTALL_CMD curl wget net-tools

# 创建部署目录
DEPLOY_PATH="/var/www/document-scanner"
print_step "创建部署目录..."
mkdir -p $DEPLOY_PATH

# 复制应用文件
print_step "复制应用文件..."
cp -r ./* $DEPLOY_PATH/

# 创建Python HTTP服务器启动脚本
print_step "创建Python服务器脚本..."
cat > $DEPLOY_PATH/start-server.py << 'PYTHON_EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os
import sys
import datetime

PORT = 80
WEB_DIR = "/var/www/document-scanner"

class DocumentScannerHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)
    
    def end_headers(self):
        # 添加安全和缓存头
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('X-Frame-Options', 'SAMEORIGIN')
        self.send_header('X-XSS-Protection', '1; mode=block')
        self.send_header('X-Content-Type-Options', 'nosniff')
        
        # 缓存控制
        if self.path.endswith(('.js', '.css', '.png', '.jpg', '.jpeg', '.gif', '.ico', '.svg')):
            self.send_header('Cache-Control', 'public, max-age=86400')
        else:
            self.send_header('Cache-Control', 'no-cache')
        
        super().end_headers()
    
    def log_message(self, format, *args):
        # 自定义日志格式
        timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] {format % args}")

class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True

if __name__ == "__main__":
    try:
        os.chdir(WEB_DIR)
        with ThreadedTCPServer(("", PORT), DocumentScannerHandler) as httpd:
            print("=" * 60)
            print("🎉 文档扫描器服务器启动成功！")
            print("=" * 60)
            print(f"📁 网站目录: {WEB_DIR}")
            print(f"🌐 本地访问: http://localhost:{PORT}")
            print(f"🌐 公网访问: http://YOUR_SERVER_IP:{PORT}")
            print(f"⏰ 启动时间: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            print("=" * 60)
            print("💡 管理提示:")
            print("  - 按 Ctrl+C 停止服务器")
            print("  - 日志会实时显示在下方")
            print("  - 网站文件位置: /var/www/document-scanner/")
            print("=" * 60)
            httpd.serve_forever()
    except PermissionError:
        print("❌ 权限不足，请使用 sudo 运行")
        print("💡 命令: sudo python3 start-server.py")
        sys.exit(1)
    except OSError as e:
        if "Address already in use" in str(e):
            print("❌ 端口80已被占用")
            print("💡 解决方案:")
            print("   1. 停止占用端口的服务: sudo lsof -ti:80 | xargs sudo kill")
            print("   2. 或更改端口: 编辑脚本中的 PORT 变量")
        else:
            print(f"❌ 网络错误: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n" + "=" * 40)
        print("🛑 服务器已停止")
        print("✅ 感谢使用文档扫描器！")
        print("=" * 40)
        sys.exit(0)
    except Exception as e:
        print(f"❌ 启动失败: {e}")
        sys.exit(1)
PYTHON_EOF

chmod +x $DEPLOY_PATH/start-server.py

# 创建systemd服务文件
print_step "创建系统服务..."
cat > /etc/systemd/system/document-scanner.service << 'SERVICE_EOF'
[Unit]
Description=Document Scanner Web Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/document-scanner
ExecStart=/usr/bin/python3 /var/www/document-scanner/start-server.py
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# 设置权限
print_step "设置文件权限..."
chown -R root:root $DEPLOY_PATH
chmod -R 755 $DEPLOY_PATH

# 配置防火墙
print_step "配置防火墙..."
if command -v firewall-cmd &> /dev/null; then
    # CentOS/RHEL
    systemctl start firewalld 2>/dev/null || true
    firewall-cmd --permanent --add-port=80/tcp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
    print_success "firewalld防火墙已配置"
elif command -v ufw &> /dev/null; then
    # Ubuntu/Debian
    ufw --force enable 2>/dev/null || true
    ufw allow 80 2>/dev/null || true
    print_success "ufw防火墙已配置"
elif command -v iptables &> /dev/null; then
    # 通用iptables
    iptables -I INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
    print_success "iptables防火墙已配置"
else
    print_warning "未检测到防火墙，请手动开放80端口"
fi

# 检查端口占用
print_step "检查端口占用..."
if command -v netstat &> /dev/null && netstat -tuln | grep -q ":80 "; then
    print_warning "端口80已被占用，正在尝试释放..."
    if command -v lsof &> /dev/null; then
        lsof -ti:80 | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
fi

# 启动服务
print_step "启动文档扫描器服务..."
systemctl daemon-reload
systemctl enable document-scanner
systemctl start document-scanner

# 等待服务启动
sleep 5

# 检查服务状态
if systemctl is-active --quiet document-scanner; then
    print_success "服务启动成功！"
    SERVICE_STATUS="运行中"
else
    print_warning "系统服务启动失败，尝试手动启动..."
    cd $DEPLOY_PATH
    nohup $PYTHON_CMD start-server.py > server.log 2>&1 &
    sleep 3
    if pgrep -f "start-server.py" > /dev/null; then
        print_success "手动启动成功！"
        SERVICE_STATUS="手动运行中"
    else
        print_error "启动失败，请检查错误日志"
        SERVICE_STATUS="启动失败"
    fi
fi

# 获取服务器IP
print_step "获取服务器信息..."
SERVER_IP=$(curl -s ipinfo.io/ip 2>/dev/null || curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")

# 测试网站访问
print_step "测试网站访问..."
sleep 2
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    print_success "网站访问测试通过"
    SITE_STATUS="正常"
else
    print_warning "网站访问测试失败，HTTP状态码: $HTTP_STATUS"
    SITE_STATUS="异常"
fi

# 显示部署结果
echo
echo "=========================================="
print_success "🎉 部署完成！"
echo "=========================================="
echo
print_success "📋 部署信息:"
print_success "  🌐 访问地址: http://$SERVER_IP"
print_success "  📁 网站目录: $DEPLOY_PATH"
print_success "  🔧 Python版本: $($PYTHON_CMD --version)"
print_success "  🚀 服务状态: $SERVICE_STATUS"
print_success "  📊 网站状态: $SITE_STATUS"
echo
print_success "🛠️ 管理命令:"
echo "  systemctl status document-scanner    # 查看服务状态"
echo "  systemctl restart document-scanner   # 重启服务"
echo "  systemctl stop document-scanner      # 停止服务"
echo "  systemctl start document-scanner     # 启动服务"
echo "  journalctl -u document-scanner -f    # 查看实时日志"
echo
print_success "🔧 手动管理:"
echo "  cd $DEPLOY_PATH && python3 start-server.py  # 手动启动"
echo "  tail -f $DEPLOY_PATH/server.log              # 查看日志"
echo "  ps aux | grep start-server.py                # 查看进程"
echo
print_success "🎯 下一步:"
echo "  1. 在浏览器访问: http://$SERVER_IP"
echo "  2. 测试所有功能是否正常"
echo "  3. 如需HTTPS，请配置SSL证书"
echo
if [ "$SITE_STATUS" = "正常" ]; then
    print_success "🌟 部署成功！请在浏览器中访问 http://$SERVER_IP 查看应用"
else
    print_warning "⚠️ 部署可能有问题，请检查日志: journalctl -u document-scanner -f"
fi

# 创建快速管理脚本
cat > /usr/local/bin/scanner-admin << 'ADMIN_EOF'
#!/bin/bash

case "$1" in
    start)
        systemctl start document-scanner
        echo "✅ 文档扫描器已启动"
        ;;
    stop)
        systemctl stop document-scanner
        echo "⏹️ 文档扫描器已停止"
        ;;
    restart)
        systemctl restart document-scanner
        echo "🔄 文档扫描器已重启"
        ;;
    status)
        systemctl status document-scanner
        ;;
    logs)
        journalctl -u document-scanner -f
        ;;
    manual)
        cd /var/www/document-scanner
        python3 start-server.py
        ;;
    test)
        curl -I http://localhost/
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|logs|manual|test}"
        echo ""
        echo "命令说明:"
        echo "  start   - 启动服务"
        echo "  stop    - 停止服务"
        echo "  restart - 重启服务"
        echo "  status  - 查看状态"
        echo "  logs    - 查看日志"
        echo "  manual  - 手动启动"
        echo "  test    - 测试连接"
        exit 1
        ;;
esac
ADMIN_EOF

chmod +x /usr/local/bin/scanner-admin
print_success "快速管理命令已创建: scanner-admin"

echo
print_success "🎮 快速管理:"
echo "  scanner-admin start     # 启动"
echo "  scanner-admin status    # 状态"
echo "  scanner-admin logs      # 日志"
echo "  scanner-admin test      # 测试"

print_success "🎉 文档扫描器部署完成！享受使用吧！"