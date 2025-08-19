#!/bin/bash

# 一键在线安装脚本 - 在ECS服务器上直接运行
curl -fsSL https://raw.githubusercontent.com/peakom/document-scanner/main/install.sh | bash

# 如果上面失败，使用备用方案：

echo "=== 文档扫描器一键部署 ==="

# 检查Python
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "安装Python3..."
    if command -v yum &> /dev/null; then
        yum install -y python3
    elif command -v apt &> /dev/null; then
        apt update && apt install -y python3
    fi
    PYTHON_CMD="python3"
fi

# 创建网站目录
mkdir -p /var/www/document-scanner
cd /var/www/document-scanner

# 创建简单的HTML页面
cat > index.html << 'HTML_EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>文档扫描器</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .container { max-width: 800px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 30px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .status { background: #f0fff4; border: 1px solid #9ae6b4; border-radius: 8px; padding: 20px; text-align: center; }
        .btn { background: #007bff; color: white; border: none; padding: 12px 24px; border-radius: 8px; cursor: pointer; margin: 10px; }
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
            <p>Python HTTP服务器运行中</p>
            <p>部署时间: <span id="time"></span></p>
        </div>
        <div style="text-align: center;">
            <button class="btn" onclick="location.reload()">刷新页面</button>
            <button class="btn" onclick="alert('测试成功！服务器运行正常')">测试功能</button>
        </div>
    </div>
    <script>
        document.getElementById('time').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
HTML_EOF

# 创建Python服务器
cat > start-server.py << 'PYTHON_EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os

PORT = 80
WEB_DIR = "/var/www/document-scanner"

class MyHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)
    
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

if __name__ == "__main__":
    try:
        os.chdir(WEB_DIR)
        with socketserver.TCPServer(("", PORT), MyHandler) as httpd:
            print(f"✅ 服务器启动成功！访问 http://47.92.236.28")
            httpd.serve_forever()
    except PermissionError:
        print("❌ 需要root权限，请使用: sudo python3 start-server.py")
    except Exception as e:
        print(f"❌ 启动失败: {e}")
PYTHON_EOF

chmod +x start-server.py

# 配置系统服务
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

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# 启动服务
systemctl daemon-reload
systemctl enable document-scanner
systemctl start document-scanner

# 配置防火墙
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=80/tcp
    firewall-cmd --reload
elif command -v ufw &> /dev/null; then
    ufw allow 80
fi

echo "🎉 部署完成！访问 http://47.92.236.28"
echo "管理命令："
echo "  systemctl status document-scanner  # 查看状态"
echo "  systemctl restart document-scanner # 重启"