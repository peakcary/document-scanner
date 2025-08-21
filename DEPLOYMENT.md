# 文档扫描器部署指南

## 🚀 快速部署

### 1. 环境要求

**服务器要求:**
- Linux/Unix 系统 (推荐 Ubuntu 18.04+)
- Python 3.6+ 
- SSH 访问权限
- 至少 100MB 磁盘空间

**本地开发环境:**
- Node.js 14+ (用于构建脚本)
- Git (版本控制)
- SSH 客户端或 sshpass

### 2. 一键部署

```bash
# 克隆项目
git clone <your-repo-url>
cd document-scanner

# 安装依赖 (可选)
npm install

# 构建并部署到开发环境
npm run package
npm run deploy

# 部署到生产环境
npm run deploy:prod
```

## 📋 详细部署流程

### 1. 配置部署环境

编辑 `deploy.config.js` 文件：

```javascript
module.exports = {
    production: {
        host: 'your-server.com',
        user: 'deploy',
        keyFile: '~/.ssh/id_rsa', // 推荐使用SSH密钥
        path: '/var/www/document-scanner',
        port: 22,
        url: 'https://your-domain.com',
        restart: 'systemctl restart nginx'
    }
};
```

### 2. SSH 密钥配置 (推荐)

```bash
# 生成SSH密钥
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# 复制公钥到服务器
ssh-copy-id -i ~/.ssh/id_rsa.pub user@your-server.com

# 测试连接
ssh user@your-server.com
```

### 3. 服务器初始化

在目标服务器上：

```bash
# 创建部署目录
sudo mkdir -p /var/www/document-scanner
sudo chown $USER:$USER /var/www/document-scanner

# 安装Python3 (如果没有)
sudo apt update
sudo apt install python3 python3-pip

# 启动Web服务器
cd /var/www/document-scanner
python3 -m http.server 8080 --bind 0.0.0.0
```

### 4. 自动化部署

```bash
# 方式1: 使用npm脚本
npm run deploy              # 部署到开发环境
npm run deploy:prod         # 部署到生产环境

# 方式2: 指定环境
NODE_ENV=staging npm run deploy

# 方式3: 手动部署
npm run package            # 创建部署包
scp document-scanner-latest.tar.gz user@server:/path/
```

## 🔧 高级配置

### 1. Nginx 配置 (可选)

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 2. 系统服务配置

创建 `/etc/systemd/system/document-scanner.service`:

```ini
[Unit]
Description=Document Scanner Web App
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/document-scanner
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 0.0.0.0
Restart=always

[Install]
WantedBy=multi-user.target
```

启用服务：
```bash
sudo systemctl enable document-scanner
sudo systemctl start document-scanner
```

### 3. 防火墙配置

```bash
# Ubuntu/Debian
sudo ufw allow 8080
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

## 📊 监控与维护

### 1. 查看服务状态

```bash
# 检查服务状态
sudo systemctl status document-scanner

# 查看日志
journalctl -u document-scanner -f

# 检查端口占用
netstat -tlnp | grep 8080
```

### 2. 备份策略

```bash
# 自动备份脚本
#!/bin/bash
cd /var/www/document-scanner
tar -czf backup-$(date +%Y%m%d_%H%M%S).tar.gz *
find . -name "backup-*" -mtime +7 -delete  # 删除7天前的备份
```

### 3. 更新流程

```bash
# 本地开发完成后
npm run version patch      # 更新版本号
git push                   # 推送代码
npm run package           # 创建部署包
npm run deploy:prod       # 部署到生产环境
```

## 🐛 故障排查

### 常见问题

**1. 连接被拒绝**
```bash
# 检查SSH连接
ssh -v user@host

# 检查端口是否开放
telnet host 22
```

**2. 权限问题**
```bash
# 检查目录权限
ls -la /var/www/document-scanner

# 修正权限
sudo chown -R www-data:www-data /var/www/document-scanner
```

**3. Python服务无法启动**
```bash
# 检查Python版本
python3 --version

# 手动启动测试
cd /var/www/document-scanner
python3 -m http.server 8080
```

**4. 文件上传失败**
```bash
# 检查磁盘空间
df -h

# 检查网络连接
ping target-server
```

## 🔒 安全建议

1. **使用SSH密钥** 而不是密码认证
2. **定期更新** 服务器和依赖
3. **配置防火墙** 只开放必要端口
4. **使用HTTPS** 在生产环境中
5. **定期备份** 重要数据
6. **监控日志** 异常访问

## 📞 技术支持

如遇部署问题，请检查：
1. 网络连接是否正常
2. 服务器凭据是否正确
3. 目标路径是否存在且有权限
4. 磁盘空间是否充足

更多帮助请参考项目文档或提交Issue。