# 🔒 安全部署配置指南

## ⚡ 快速开始

### 1. 创建本地配置文件

```bash
# 复制配置模板
cp .env.example .env.local

# 编辑配置文件
nano .env.local
```

### 2. 填入您的服务器信息

```bash
# 开发环境配置
DEV_HOST=your-server-ip
DEV_USER=root
DEV_PASSWORD=your-password
DEV_PATH=/var/www/document-scanner
DEV_PORT=22
DEV_URL=http://your-server-ip:8080
```

### 3. 立即部署

```bash
npm run deploy
```

## 🔐 多环境配置

### 开发环境 (`npm run deploy`)
```bash
DEV_HOST=47.92.236.28
DEV_USER=root  
DEV_PASSWORD=your-dev-password
DEV_PATH=/var/www/document-scanner
```

### 生产环境 (`npm run deploy:prod`)
```bash
PROD_HOST=production-server.com
PROD_USER=deploy
PROD_PASSWORD=your-prod-password
# 或使用SSH密钥
PROD_KEY_FILE=/path/to/ssh/key
PROD_PATH=/var/www/document-scanner
PROD_URL=https://your-domain.com
```

## 🛡️ 安全最佳实践

### 1. 使用SSH密钥 (推荐)

生成SSH密钥：
```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
ssh-copy-id user@your-server.com
```

配置文件中使用密钥：
```bash
DEV_KEY_FILE=/Users/yourusername/.ssh/id_rsa
# DEV_PASSWORD=  # 注释掉密码，使用密钥认证
```

### 2. 文件权限设置

```bash
# 设置配置文件权限
chmod 600 .env.local
chmod 600 ~/.ssh/id_rsa
```

### 3. 环境隔离

- **开发环境**: `.env.local` (不提交到Git)  
- **生产环境**: 服务器上设置环境变量
- **CI/CD**: 使用加密的环境变量

## 📁 配置文件说明

### `.env.local` (本地配置)
- 包含当前开发服务器信息
- **不会被Git跟踪**
- 优先级最高

### `.env.example` (模板文件) 
- 配置文件模板
- **会被Git跟踪**
- 不包含真实密码

### `deploy.config.js` (部署脚本)
- 从环境变量读取配置
- 支持多环境部署
- **会被Git跟踪**

## 🚀 部署命令

```bash
# 开发环境部署
npm run deploy

# 生产环境部署  
npm run deploy:prod

# 测试环境部署
NODE_ENV=staging npm run deploy

# 查看当前配置（调试用）
node -e "require('./deploy.config.js'); console.log('DEV_HOST:', process.env.DEV_HOST)"
```

## 🔍 故障排查

### 1. 配置检查
```bash
# 检查环境变量是否加载
echo $DEV_HOST

# 查看配置文件
cat .env.local
```

### 2. 连接测试
```bash
# 测试SSH连接
ssh user@host

# 测试密钥认证
ssh -i ~/.ssh/id_rsa user@host
```

### 3. 常见错误
- **权限被拒绝**: 检查SSH密钥或密码
- **连接超时**: 检查服务器IP和端口
- **路径不存在**: 确认目标目录存在

## 📋 换服务器步骤

1. **修改配置**
   ```bash
   nano .env.local
   # 更新DEV_HOST、DEV_USER等信息
   ```

2. **测试连接**
   ```bash
   ssh $DEV_USER@$DEV_HOST
   ```

3. **一键部署**
   ```bash
   npm run deploy
   ```

## ✅ 安全检查清单

- [ ] 配置文件权限设置为600
- [ ] 使用SSH密钥而不是密码
- [ ] .env.local已添加到.gitignore
- [ ] 生产环境使用独立的用户账号
- [ ] 定期更新SSH密钥和密码
- [ ] 启用服务器防火墙

**现在您的服务器信息是安全的！** 🔒