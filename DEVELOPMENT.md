# 🔄 开发部署流程指南

本文档说明如何进行项目的日常开发、测试和部署。

## 📋 完整工作流程

```
本地开发 → Git提交推送 → 服务器自动更新 → 线上部署
```

## 🛠️ 日常开发流程

### 1. 本地开发

```bash
# 启动本地开发服务器
python3 -m http.server 8080

# 在浏览器中打开
open http://localhost:8080

# 进行代码修改...
```

### 2. 提交和推送代码

```bash
# 查看修改状态
git status

# 添加修改的文件
git add .

# 提交修改
git commit -m "描述你的修改内容"

# 推送到GitHub
git push origin main
```

### 3. 部署到服务器

#### 方法1: 一键自动部署 (推荐)

```bash
# 执行一键部署脚本
./deploy-to-server.sh
```

这个脚本会自动：
- ✅ 检查本地Git状态
- ✅ 提交未保存的修改(可选)
- ✅ 推送代码到GitHub
- ✅ 触发服务器自动更新
- ✅ 重启服务并验证

#### 方法2: 手动分步执行

```bash
# 1. 推送代码到GitHub
git push origin main

# 2. 连接服务器并手动更新
ssh root@47.92.236.28
cd /var/www/document-scanner
./update-from-git.sh
```

## 🔧 服务器管理命令

### 连接服务器
```bash
ssh root@47.92.236.28
```

### 常用服务器操作
```bash
# 进入项目目录
cd /var/www/document-scanner

# 查看服务状态
ps aux | grep python3

# 重启服务
pkill -f 'python3 -m http.server 8080'
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &

# 查看服务日志
tail -f server.log

# 从GitHub更新代码
./update-from-git.sh

# 查看Git状态
git status
git log --oneline -5
```

## 📁 脚本文件说明

### 本地脚本

| 文件 | 作用 | 使用方法 |
|------|------|----------|
| `deploy-to-server.sh` | 一键部署到服务器 | `./deploy-to-server.sh` |
| `start-local.sh` | 启动本地开发服务器 | `./start-local.sh` |

### 服务器脚本

| 文件 | 作用 | 位置 |
|------|------|------|
| `update-from-git.sh` | 从GitHub更新并重启 | `/var/www/document-scanner/` |
| `start-scanner.sh` | 启动文档扫描器服务 | `/var/www/document-scanner/` |

## 🚨 故障排查

### 1. 本地开发服务器无法启动
```bash
# 检查端口是否被占用
lsof -ti:8080

# 杀死占用进程
kill -9 $(lsof -ti:8080)

# 重新启动
python3 -m http.server 8080
```

### 2. Git推送失败
```bash
# 检查远程仓库配置
git remote -v

# 强制推送(谨慎使用)
git push origin main --force
```

### 3. 服务器更新失败
```bash
# 连接服务器检查
ssh root@47.92.236.28

# 检查网络连接
ping github.com

# 手动拉取代码
cd /var/www/document-scanner
git fetch origin main
git reset --hard origin/main
```

### 4. 服务器服务无法启动
```bash
# 检查端口占用
netstat -tlpn | grep 8080

# 检查Python进程
ps aux | grep python3

# 强制重启
pkill -f python3
cd /var/www/document-scanner
./start-scanner.sh
```

## 🔄 版本管理

### 查看版本历史
```bash
# 查看提交历史
git log --oneline -10

# 查看某次提交的详细信息
git show <commit-hash>

# 比较两个版本的差异
git diff <commit1> <commit2>
```

### 回滚版本
```bash
# 回滚到指定版本
git reset --hard <commit-hash>
git push origin main --force

# 服务器更新
./deploy-to-server.sh
```

## 📊 性能监控

### 服务器性能检查
```bash
# 查看服务器资源使用
htop

# 查看磁盘使用
df -h

# 查看网络连接
netstat -tuln
```

### 网站访问测试
```bash
# 测试本地访问
curl -I http://localhost:8080

# 测试远程访问
curl -I http://47.92.236.28:8080
```

## 🎯 最佳实践

1. **定期提交**: 完成一个功能就提交一次
2. **清晰的提交信息**: 使用有意义的提交消息
3. **测试后部署**: 本地测试通过后再部署
4. **备份重要版本**: 为重要版本打标签
5. **监控服务状态**: 定期检查服务器运行状态

## 📞 快速参考

| 场景 | 命令 |
|------|------|
| 本地开发 | `python3 -m http.server 8080` |
| 一键部署 | `./deploy-to-server.sh` |
| 查看日志 | `tail -f server.log` |
| 重启服务 | `./update-from-git.sh` |
| 连接服务器 | `ssh root@47.92.236.28` |

---

🔗 **相关链接**:
- 在线演示: http://47.92.236.28:8080
- GitHub仓库: https://github.com/peakcary/document-scanner
- 项目文档: [README.md](README.md)