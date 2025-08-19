#!/bin/bash

# 最简单的部署脚本 - 只需要Python

echo "=========================================="
echo "  文档扫描器 - 超简单部署"
echo "  只需要Python，无需Docker、无需Nginx"
echo "=========================================="

# 检查Python
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "❌ 未找到Python，正在安装..."
    if command -v yum &> /dev/null; then
        yum install -y python3
        PYTHON_CMD="python3"
    elif command -v apt &> /dev/null; then
        apt update && apt install -y python3
        PYTHON_CMD="python3"
    else
        echo "❌ 无法自动安装Python，请手动安装"
        exit 1
    fi
fi

echo "✅ 使用Python: $PYTHON_CMD"

# 创建网站目录
WEB_DIR="/var/www/document-scanner"
mkdir -p $WEB_DIR

# 复制项目文件
echo "📁 复制项目文件..."
if [ -f "index.html" ]; then
    cp -r ./* $WEB_DIR/
elif [ -d "document-scanner" ]; then
    cp -r document-scanner/* $WEB_DIR/
elif [ -f "/tmp/document-scanner.tar.gz" ]; then
    cd /tmp
    tar -xzf document-scanner.tar.gz
    cp -r document-scanner/* $WEB_DIR/
else
    echo "❌ 未找到项目文件，创建示例文件..."
    cat > $WEB_DIR/index.html << 'HTML_EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>文档扫描器</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f0f0f0; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        .header { text-align: center; color: #333; margin-bottom: 30px; }
        .status { background: #e8f5e8; padding: 20px; border-radius: 8px; text-align: center; }
        .btn { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; margin: 5px; }
        .btn:hover { background: #0056b3; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎉 文档扫描器</h1>
            <p>部署成功！服务器运行正常</p>
        </div>
        <div class="status">
            <h3>✅ 系统状态</h3>
            <p>Python HTTP服务器运行中</p>
            <p>部署时间: <span id="time"></span></p>
        </div>
        <div style="text-align: center; margin-top: 20px;">
            <button class="btn" onclick="location.reload()">刷新页面</button>
            <button class="btn" onclick="testConnection()">测试连接</button>
        </div>
    </div>
    <script>
        document.getElementById('time').textContent = new Date().toLocaleString();
        function testConnection() {
            alert('连接测试成功！✅\n服务器响应正常');
        }
    </script>
</body>
</html>
HTML_EOF
fi

echo "✅ 项目文件准备完成"

# 创建启动脚本
cat > $WEB_DIR/start-server.py << 'PYTHON_EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os
import sys

PORT = 80
WEB_DIR = "/var/www/document-scanner"

class MyHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)
    
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

if __name__ == "__main__":
    try:
        os.chdir(WEB_DIR)
        with socketserver.TCPServer(("", PORT), MyHandler) as httpd:
            print(f"✅ 服务器启动成功！")
            print(f"📁 网站目录: {WEB_DIR}")
            print(f"🌐 访问地址: http://localhost:{PORT}")
            print(f"🌐 公网地址: http://YOUR_SERVER_IP:{PORT}")
            print(f"⌨️  按 Ctrl+C 停止服务器")
            print("-" * 50)
            httpd.serve_forever()
    except PermissionError:
        print("❌ 权限不足，请使用sudo运行")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n🛑 服务器已停止")
        sys.exit(0)
    except Exception as e:
        print(f"❌ 启动失败: {e}")
        sys.exit(1)
PYTHON_EOF

chmod +x $WEB_DIR/start-server.py

# 创建系统服务（可选）
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

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# 配置防火墙
echo "🔥 配置防火墙..."
if command -v firewall-cmd &> /dev/null; then
    systemctl start firewalld 2>/dev/null || true
    firewall-cmd --permanent --add-port=80/tcp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
elif command -v ufw &> /dev/null; then
    ufw allow 80 2>/dev/null || true
fi

# 启动服务
echo "🚀 启动服务..."
systemctl daemon-reload
systemctl enable document-scanner
systemctl start document-scanner

# 等待启动
sleep 3

# 检查状态
if systemctl is-active --quiet document-scanner; then
    echo "✅ 服务启动成功！"
else
    echo "⚠️ 服务可能未正常启动，尝试手动启动..."
    cd $WEB_DIR
    nohup $PYTHON_CMD start-server.py > server.log 2>&1 &
    echo "🔄 后台启动完成"
fi

# 获取服务器IP
SERVER_IP=$(curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_SERVER_IP")

echo
echo "=========================================="
echo "🎉 部署完成！"
echo "=========================================="
echo
echo "🌐 访问地址: http://$SERVER_IP"
echo "📁 网站目录: $WEB_DIR"
echo "📝 日志文件: $WEB_DIR/server.log"
echo
echo "🛠️ 管理命令:"
echo "  systemctl status document-scanner   # 查看状态"
echo "  systemctl restart document-scanner  # 重启服务"
echo "  systemctl stop document-scanner     # 停止服务"
echo "  tail -f $WEB_DIR/server.log        # 查看日志"
echo
echo "🎯 手动启动命令:"
echo "  cd $WEB_DIR && python3 start-server.py"
echo
echo "✅ 部署完成！请访问 http://$SERVER_IP 查看网站"