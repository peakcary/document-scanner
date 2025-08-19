# 🔄 手动代码同步指南

## 问题：服务器代码和本地代码不一致

## 🎯 解决方案：手动完整同步

### 方案1：使用打包文件手动同步（推荐）

#### 第1步：本地创建代码包
在你的本地Mac上执行：
```bash
cd /Users/peakom/document-scanner

# 创建完整代码包（排除.git目录）
tar --exclude='.git' --exclude='*.tar.gz' --exclude='.DS_Store' -czf document-scanner-latest.tar.gz .

# 检查包的内容
tar -tzf document-scanner-latest.tar.gz | head -10
```

#### 第2步：上传到服务器
```bash
# 使用scp上传（需要输入服务器密码）
scp document-scanner-latest.tar.gz root@47.92.236.28:/tmp/
```

#### 第3步：服务器端同步代码
SSH到服务器执行：
```bash
# 登录服务器
ssh root@47.92.236.28

# 进入项目目录
cd /var/www/document-scanner

# 停止现有服务
pkill -f "python3 -m http.server" 2>/dev/null || true

# 创建备份
cp -r . ../document-scanner-backup-$(date +%Y%m%d_%H%M%S)

# 清空当前目录（保留.git）
find . -maxdepth 1 -not -name '.' -not -name '.git' -exec rm -rf {} \;

# 解压新代码
tar -xzf /tmp/document-scanner-latest.tar.gz

# 设置权限
chmod +x *.sh
chmod 644 *.html *.css *.js

# 修复Git兼容性
sed -i 's/git stash push -m/git stash save/g' *.sh

# 启动服务
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &

# 验证服务
sleep 3
ps aux | grep python3
curl -I http://localhost:8080
```

### 方案2：逐个文件同步

如果上传大文件有问题，可以逐个同步关键文件：

```bash
# 在本地，逐个上传关键文件
scp index.html root@47.92.236.28:/var/www/document-scanner/
scp *.sh root@47.92.236.28:/var/www/document-scanner/
scp -r css/ root@47.92.236.28:/var/www/document-scanner/
scp -r js/ root@47.92.236.28:/var/www/document-scanner/
```

### 方案3：GitHub拉取（如果网络OK）

```bash
# 在服务器上
ssh root@47.92.236.28
cd /var/www/document-scanner

# 强制拉取最新代码
git fetch origin main
git reset --hard origin/main

# 或者重新克隆
cd /var/www
rm -rf document-scanner
git clone https://github.com/peakcary/document-scanner.git
cd document-scanner

# 修复兼容性并启动
sed -i 's/git stash push -m/git stash save/g' *.sh
chmod +x *.sh
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &
```

## 📊 验证同步结果

同步完成后，在服务器上检查：

```bash
# 检查文件列表
ls -la

# 检查最新的脚本是否存在
ls -la *sync* *update* *fix*

# 检查服务状态
ps aux | grep python3
netstat -tlpn | grep 8080

# 测试访问
curl -I http://localhost:8080
```

## 🎯 本地最新文件清单

当前本地最新文件包括：
- `sync-local-to-server.sh` - 完整同步脚本
- `force-update-server.sh` - 强制更新脚本
- `server-update-script.sh` - 一键更新脚本
- `fix-git-compatibility.sh` - Git兼容性修复
- `server-quick-fix.sh` - 服务器快速修复
- `update-and-deploy.sh` - 更新部署脚本
- 各种Git问题诊断和修复工具

## ⚠️ 重要提醒

1. **备份重要**：同步前务必备份服务器当前状态
2. **权限设置**：同步后确保脚本有执行权限
3. **Git兼容性**：服务器Git版本较旧，需要修复stash命令
4. **服务重启**：同步后重启HTTP服务
5. **访问验证**：确保 http://47.92.236.28:8080 正常访问

## 🚀 快速执行（推荐）

```bash
# 本地打包
cd /Users/peakom/document-scanner
tar --exclude='.git' --exclude='*.tar.gz' --exclude='.DS_Store' -czf latest.tar.gz .

# 上传（输入服务器密码）
scp latest.tar.gz root@47.92.236.28:/tmp/

# 服务器同步（SSH登录后执行）
ssh root@47.92.236.28
cd /var/www/document-scanner
pkill -f python3
cp -r . ../backup-$(date +%Y%m%d)
find . -maxdepth 1 -not -name '.' -not -name '.git' -exec rm -rf {} \;
tar -xzf /tmp/latest.tar.gz
chmod +x *.sh
sed -i 's/git stash push/git stash save/g' *.sh
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &
```

执行完成后访问：http://47.92.236.28:8080