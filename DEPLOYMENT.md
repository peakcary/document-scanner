# 阿里云服务器部署指南

## 🚀 一键部署

### 准备工作

1. **购买阿里云服务器**
   - 推荐配置: 2核4G内存，40G硬盘
   - 操作系统: Ubuntu 20.04 LTS
   - 带宽: 5M以上

2. **域名配置**
   - 购买域名并完成备案
   - 添加A记录指向服务器IP
   - 确保域名可以正常解析

3. **服务器基础配置**
   ```bash
   # 连接服务器
   ssh root@your-server-ip
   
   # 更新系统
   apt update && apt upgrade -y
   ```

### 快速部署

1. **上传文件到服务器**
   ```bash
   # 方法1: 使用scp上传
   scp -r document-scanner/ root@your-server-ip:/tmp/
   
   # 方法2: 使用git克隆（如果已上传到git仓库）
   git clone your-repo-url /tmp/document-scanner
   ```

2. **执行一键部署脚本**
   ```bash
   cd /tmp/document-scanner
   chmod +x deploy.sh
   sudo ./deploy.sh
   ```

3. **按提示输入信息**
   - 域名: 例如 `scanner.yourdomain.com`
   - 邮箱: 用于SSL证书申请

4. **等待部署完成**
   - 脚本会自动安装所有依赖
   - 配置SSL证书
   - 启动服务

## 📋 手动部署（详细步骤）

如果自动部署失败，可以按以下步骤手动部署：

### 1. 安装Docker和Docker Compose

```bash
# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl start docker
systemctl enable docker

# 安装Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

### 2. 创建部署目录

```bash
mkdir -p /var/www/document-scanner
cd /var/www/document-scanner
```

### 3. 上传应用文件

将所有应用文件上传到 `/var/www/document-scanner/` 目录

### 4. 配置SSL证书

```bash
# 安装Certbot
apt install -y certbot

# 获取SSL证书
certbot certonly --standalone -d your-domain.com --email your-email@example.com --agree-tos --non-interactive

# 创建SSL目录并复制证书
mkdir -p ssl
cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem
```

### 5. 修改配置文件

```bash
# 修改nginx.conf中的域名
sed -i 's/your-domain.com/your-actual-domain.com/g' nginx.conf
```

### 6. 启动服务

```bash
docker-compose up -d
```

## 🛠️ 管理命令

部署完成后，可以使用以下命令管理应用：

```bash
# 使用管理脚本
scanner-manage start      # 启动应用
scanner-manage stop       # 停止应用
scanner-manage restart    # 重启应用
scanner-manage status     # 查看状态
scanner-manage logs       # 查看日志
scanner-manage update     # 更新应用

# 或使用Docker Compose命令
cd /var/www/document-scanner
docker-compose up -d      # 启动
docker-compose down       # 停止
docker-compose restart    # 重启
docker-compose logs -f    # 查看日志
```

## 🔧 配置说明

### Nginx配置特性

- **HTTPS强制**: 自动将HTTP重定向到HTTPS
- **HTTP/2支持**: 提升页面加载速度
- **Gzip压缩**: 减少传输数据大小
- **安全头**: 添加各种安全响应头
- **静态资源缓存**: 1年缓存期，提升性能

### SSL证书

- **自动申请**: 使用Let's Encrypt免费证书
- **自动续期**: 每天凌晨3点检查并续期
- **A+评级**: 现代SSL/TLS配置

### Docker配置

- **轻量级**: 基于nginx:alpine镜像
- **持久化**: 数据和配置文件持久化存储
- **自动重启**: 容器异常退出自动重启

## 🚨 安全建议

### 1. 服务器安全

```bash
# 配置防火墙
ufw enable
ufw allow ssh
ufw allow 80
ufw allow 443

# 禁用root远程登录（可选）
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
systemctl restart ssh

# 设置自动安全更新
apt install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
```

### 2. 应用安全

- ✅ HTTPS强制加密
- ✅ 安全响应头
- ✅ 静态文件访问控制
- ✅ 敏感文件访问禁止

### 3. 监控建议

```bash
# 查看系统资源使用
htop
df -h
free -h

# 查看Docker容器状态
docker stats
docker logs document-scanner
```

## 🔄 更新部署

### 应用更新

```bash
# 方法1: 使用管理脚本
scanner-manage update

# 方法2: 手动更新
cd /var/www/document-scanner
# 上传新的应用文件
docker-compose down
docker-compose up -d
```

### 系统更新

```bash
# 系统软件更新
apt update && apt upgrade -y

# Docker更新
apt update && apt install docker-ce docker-ce-cli containerd.io
```

## 📊 性能优化

### 1. 服务器优化

```bash
# 增加文件句柄限制
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# 优化内核参数
echo "net.core.somaxconn = 65535" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 65535" >> /etc/sysctl.conf
sysctl -p
```

### 2. Nginx优化

已在nginx.conf中配置:
- Gzip压缩
- 静态资源缓存
- HTTP/2支持
- Keep-alive连接

### 3. 应用优化

- ✅ 图片自动压缩
- ✅ WebWorker后台处理
- ✅ 静态资源CDN加速（可选）

## 🆘 故障排除

### 常见问题

1. **SSL证书申请失败**
   ```bash
   # 检查域名解析
   nslookup your-domain.com
   
   # 检查80端口是否被占用
   netstat -tulpn | grep :80
   
   # 手动申请证书
   certbot certonly --standalone -d your-domain.com
   ```

2. **Docker容器启动失败**
   ```bash
   # 查看错误日志
   docker-compose logs
   
   # 检查配置文件
   nginx -t -c /var/www/document-scanner/nginx.conf
   ```

3. **访问403/404错误**
   ```bash
   # 检查文件权限
   ls -la /var/www/document-scanner/
   chown -R www-data:www-data /var/www/document-scanner/
   ```

4. **性能问题**
   ```bash
   # 查看系统资源
   htop
   docker stats
   
   # 查看访问日志
   tail -f /var/log/nginx/access.log
   ```

### 日志查看

```bash
# Nginx访问日志
tail -f /var/log/nginx/access.log

# Nginx错误日志
tail -f /var/log/nginx/error.log

# Docker容器日志
docker logs -f document-scanner

# 系统日志
journalctl -u docker -f
```

## 📞 技术支持

如果遇到部署问题，请提供以下信息：

1. 服务器配置和操作系统版本
2. 错误日志内容
3. 域名和DNS配置
4. 执行的具体命令

## 🎯 部署检查清单

- [ ] 服务器配置满足要求
- [ ] 域名解析正确
- [ ] 80/443端口开放
- [ ] SSL证书申请成功
- [ ] Docker服务正常运行
- [ ] 应用可以正常访问
- [ ] HTTPS重定向正常
- [ ] 静态资源加载正常
- [ ] 图片上传和处理功能正常
- [ ] PDF生成和下载功能正常