# 📋 服务器代码同步执行文档

## 🎯 目标
确保服务器代码与本地代码100%一致，解决版本不同步问题。

## 📦 准备工作

### 检查本地环境
```bash
# 确认在项目目录
cd /Users/peakom/document-scanner

# 检查本地代码状态
git status
git log --oneline -3

# 检查代码包是否存在
ls -lh document-scanner-latest.tar.gz
```

如果代码包不存在，创建它：
```bash
tar --exclude='.git' --exclude='*.tar.gz' --exclude='.DS_Store' --exclude='node_modules' -czf document-scanner-latest.tar.gz .
```

## 🚀 执行步骤

### 第1步：上传代码包到服务器

**在Mac终端执行：**
```bash
cd /Users/peakom/document-scanner

# 上传代码包到服务器
scp document-scanner-latest.tar.gz root@47.92.236.28:/tmp/
```

**预期提示：**
```
root@47.92.236.28's password: 
```

**输入密码：** `Pp--9257`

**预期结果：**
```
document-scanner-latest.tar.gz    100%   87KB   1.2MB/s   00:00
```

### 第2步：SSH登录服务器

**执行命令：**
```bash
ssh root@47.92.236.28
```

**输入密码：** `Pp--9257`

**预期结果：** 登录到服务器命令行

### 第3步：进入项目目录

**在服务器上执行：**
```bash
cd /var/www/document-scanner
pwd
```

**预期输出：**
```
/var/www/document-scanner
```

### 第4步：停止现有服务

**执行命令：**
```bash
pkill -f "python3 -m http.server" 2>/dev/null || true
pkill -f "python -m http.server" 2>/dev/null || true
```

**验证服务已停止：**
```bash
ps aux | grep python
```

应该看不到HTTP服务进程。

### 第5步：创建备份

**执行命令：**
```bash
cp -r . ../document-scanner-backup-$(date +%Y%m%d_%H%M%S)
```

**验证备份：**
```bash
ls -la ../document-scanner-backup-*
```

**预期结果：** 显示备份目录

### 第6步：清空当前目录

**⚠️ 重要：这将删除当前所有文件（除.git）**

**执行命令：**
```bash
find . -maxdepth 1 -not -name '.' -not -name '.git' -exec rm -rf {} \;
```

**验证清空结果：**
```bash
ls -la
```

**预期结果：** 只剩下 `.` 和 `.git` 目录

### 第7步：解压最新代码

**执行命令：**
```bash
tar -xzf /tmp/document-scanner-latest.tar.gz
```

**验证解压结果：**
```bash
ls -la
```

**预期结果：** 看到所有项目文件

### 第8步：设置文件权限

**执行命令：**
```bash
chmod +x *.sh
chmod 644 *.html *.css *.js *.md 2>/dev/null || true
```

**验证权限：**
```bash
ls -la *.sh
```

**预期结果：** 所有.sh文件显示可执行权限（-rwxr-xr-x）

### 第9步：修复Git兼容性

**⚠️ 关键步骤：修复旧版Git的stash命令**

**执行命令：**
```bash
sed -i 's/git stash push -m/git stash save/g' *.sh
```

**验证修复：**
```bash
grep -l "git stash save" *.sh
```

**预期结果：** 显示已修复的脚本文件

### 第10步：启动HTTP服务

**执行命令：**
```bash
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &
```

**等待服务启动：**
```bash
sleep 3
```

### 第11步：验证服务状态

**检查进程：**
```bash
ps aux | grep "python3 -m http.server"
```

**预期结果：**
```
root      1234  0.0  0.1  python3 -m http.server 8080 --bind 0.0.0.0
```

**测试本地访问：**
```bash
curl -I http://localhost:8080
```

**预期结果：**
```
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.x.x
```

### 第12步：检查最新文件

**验证同步的关键文件：**
```bash
ls -la sync-local-to-server.sh force-update-server.sh server-update-script.sh
```

**预期结果：** 这些文件都应该存在且有执行权限

## ✅ 验证成功标准

### 1. 服务运行正常
```bash
ps aux | grep python3
```
应该看到HTTP服务进程。

### 2. 网站可访问
**在浏览器访问：** http://47.92.236.28:8080

**或使用curl测试：**
```bash
curl http://47.92.236.28:8080 | head -5
```

### 3. 最新文件存在
```bash
ls -la *.sh | wc -l
```
应该看到多个脚本文件（至少8-10个）。

### 4. Git兼容性已修复
```bash
grep "git stash save" *.sh | wc -l
```
应该显示大于0的数字。

## 🚨 故障排查

### 问题1：上传失败
**症状：** scp命令失败
**解决：**
```bash
# 检查网络连接
ping 47.92.236.28

# 重试上传
scp document-scanner-latest.tar.gz root@47.92.236.28:/tmp/
```

### 问题2：SSH连接失败
**症状：** ssh连接被拒绝
**解决：**
```bash
# 检查IP和密码
ssh root@47.92.236.28
# 确保密码是：Pp--9257
```

### 问题3：服务启动失败
**症状：** HTTP服务无法启动
**解决：**
```bash
# 检查端口占用
netstat -tlpn | grep 8080

# 杀死占用进程
lsof -ti:8080 | xargs kill -9

# 重新启动
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &
```

### 问题4：网站无法访问
**症状：** 浏览器无法打开网站
**解决：**
```bash
# 查看服务日志
tail -f server.log

# 检查防火墙
ufw status

# 重启服务
pkill -f python3
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &
```

## 📊 完成检查清单

- [ ] 代码包上传成功
- [ ] SSH登录服务器成功  
- [ ] 进入项目目录
- [ ] 停止现有服务
- [ ] 创建备份
- [ ] 清空当前目录
- [ ] 解压最新代码
- [ ] 设置文件权限
- [ ] 修复Git兼容性
- [ ] 启动HTTP服务
- [ ] 验证服务状态
- [ ] 检查网站访问
- [ ] 确认最新文件存在

## 🎉 完成标志

当以下条件都满足时，同步完成：

1. ✅ **服务器HTTP服务正常运行**
2. ✅ **网站 http://47.92.236.28:8080 可正常访问**  
3. ✅ **最新的脚本文件都存在于服务器**
4. ✅ **Git兼容性问题已修复**

## 📞 后续管理

### 重启服务
```bash
pkill -f python3
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &
```

### 查看日志
```bash
tail -f server.log
```

### 检查状态
```bash
ps aux | grep python3
netstat -tlpn | grep 8080
```

---

**🎯 执行此文档后，服务器代码将与本地完全一致！**