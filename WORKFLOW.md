# 🔄 安全部署工作流程

本项目采用手动但安全的部署流程，避免在本地存储服务器凭据。

## 📋 标准工作流程

### 1️⃣ 本地开发和测试

```bash
# 启动本地开发服务器
python3 -m http.server 8080

# 在浏览器中测试
open http://localhost:8080

# 进行代码修改和测试...
```

### 2️⃣ 提交代码到Git

```bash
# 查看修改状态
git status

# 添加修改的文件
git add .

# 提交修改（使用有意义的提交信息）
git commit -m "描述你的修改内容"

# 推送到GitHub
git push origin main
```

### 3️⃣ 登录服务器

```bash
# 使用SSH登录服务器
ssh root@47.92.236.28
```

### 4️⃣ 在服务器上更新和部署

```bash
# 进入项目目录
cd /var/www/document-scanner

# 从GitHub拉取最新代码
git pull origin main

# 执行部署脚本
./update-and-deploy.sh
```

## 🎯 优势说明

### ✅ 安全优势
- **无凭据泄露**: 本地代码中不包含任何服务器密码
- **手动控制**: 每次部署都需要手动确认
- **审计追踪**: 清楚知道何时何人进行了部署
- **权限分离**: 开发和部署权限分离

### ✅ 操作优势
- **简单可靠**: 流程清晰，不容易出错
- **易于调试**: 可以在服务器上直接查看和调试
- **灵活控制**: 可以选择性部署某些更改
- **回滚容易**: 可以快速回滚到之前版本

## 🛠️ 详细操作步骤

### 本地开发环节

```bash
# 1. 确保在项目目录
cd /Users/peakom/document-scanner

# 2. 启动开发服务器
python3 -m http.server 8080

# 3. 在浏览器中打开
# http://localhost:8080

# 4. 修改代码（index.html, css/, js/ 等）

# 5. 测试功能是否正常
```

### Git操作环节

```bash
# 1. 查看修改了哪些文件
git status

# 2. 查看具体修改内容
git diff

# 3. 添加要提交的文件
git add .

# 4. 提交修改
git commit -m "功能描述: 具体修改了什么"

# 5. 推送到远程仓库
git push origin main

# 6. 确认推送成功
git log --oneline -3
```

### 服务器部署环节

```bash
# 1. SSH登录服务器
ssh root@47.92.236.28

# 2. 进入项目目录
cd /var/www/document-scanner

# 3. 查看当前状态
git status
git log --oneline -3

# 4. 拉取最新代码
git pull origin main

# 5. 查看更新内容
git log --oneline -5

# 6. 执行部署
./update-and-deploy.sh

# 7. 验证部署结果
curl -I http://localhost:8080
```

## 🔧 常用命令速查

### 本地开发
| 操作 | 命令 |
|------|------|
| 启动开发服务器 | `python3 -m http.server 8080` |
| 查看Git状态 | `git status` |
| 查看修改内容 | `git diff` |
| 提交所有修改 | `git add . && git commit -m "message"` |
| 推送到远程 | `git push origin main` |

### 服务器操作
| 操作 | 命令 |
|------|------|
| 登录服务器 | `ssh root@47.92.236.28` |
| 进入项目目录 | `cd /var/www/document-scanner` |
| 拉取最新代码 | `git pull origin main` |
| 执行部署 | `./update-and-deploy.sh` |
| 查看服务状态 | `ps aux \| grep python3` |
| 查看网站日志 | `tail -f server.log` |
| 测试网站访问 | `curl -I http://localhost:8080` |

## 🚨 故障排查

### 1. Git拉取失败
```bash
# 检查网络连接
ping github.com

# 查看Git配置
git remote -v

# 强制重置到远程状态
git fetch origin main
git reset --hard origin/main
```

### 2. 部署脚本执行失败
```bash
# 检查脚本权限
ls -la update-and-deploy.sh

# 添加执行权限
chmod +x update-and-deploy.sh

# 查看脚本内容
cat update-and-deploy.sh
```

### 3. 服务启动失败
```bash
# 查看端口占用
netstat -tlpn | grep 8080

# 杀死占用进程
pkill -f "python3 -m http.server 8080"

# 手动启动服务
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &
```

## 📊 版本管理

### 查看版本历史
```bash
# 查看最近的提交
git log --oneline -10

# 查看特定提交的详细信息
git show <commit-hash>

# 比较版本差异
git diff HEAD~1 HEAD
```

### 回滚版本（谨慎操作）
```bash
# 回滚到指定版本
git reset --hard <commit-hash>

# 或回滚到上一个版本
git reset --hard HEAD~1

# 重新部署
./update-and-deploy.sh
```

## 🎯 最佳实践

### 提交规范
- **功能性修改**: `feat: 添加图片旋转功能`
- **Bug修复**: `fix: 修复PDF生成时的尺寸问题`
- **样式调整**: `style: 优化移动端按钮样式`
- **文档更新**: `docs: 更新部署流程说明`
- **重构代码**: `refactor: 重构图片处理逻辑`

### 部署频率建议
- **小修改**: 可以随时部署
- **功能性更新**: 建议在非高峰时间部署
- **重大更改**: 建议先在测试环境验证

### 安全建议
- **定期备份**: 部署前自动创建备份
- **版本标记**: 重要版本使用Git标签
- **监控日志**: 部署后检查运行日志
- **快速回滚**: 准备好快速回滚方案

---

## 🔗 相关文档

- [项目介绍](README.md)
- [安全配置](SECURITY.md)
- [功能特性](FEATURES.md)
- [部署指南](DEPLOYMENT.md)