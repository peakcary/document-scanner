# 🚀 开发部署快速参考

## 📋 日常开发流程速查

### 🔥 一键部署（推荐）
```bash
# 在本地项目目录执行
./dev-deploy.sh
```
**自动完成：** Git提交 → 打包 → 上传 → 服务器部署 → 验证

### 🛠️ 手动分步部署

#### 第1步：本地开发测试
```bash
cd /Users/peakom/document-scanner
python3 -m http.server 8080          # 启动本地服务
open http://localhost:8080            # 浏览器测试
```

#### 第2步：Git版本管理
```bash
git status                            # 查看修改
git add .                             # 添加文件
git commit -m "feat: 新功能描述"       # 提交修改
git push origin main                  # 推送到GitHub
```

#### 第3步：创建部署包
```bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
tar --exclude='.git' --exclude='*.tar.gz' -czf "deploy-${TIMESTAMP}.tar.gz" .
```

#### 第4步：上传到服务器
```bash
scp deploy-*.tar.gz root@47.92.236.28:/tmp/
```

#### 第5步：服务器部署
```bash
ssh root@47.92.236.28
cd /var/www/document-scanner
./server-deploy.sh                   # 自动部署脚本
```

## 🎯 提交信息规范

| 类型 | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat: 添加图片旋转功能` |
| `fix` | Bug修复 | `fix: 修复PDF生成错误` |
| `style` | 样式调整 | `style: 优化移动端布局` |
| `docs` | 文档更新 | `docs: 更新部署文档` |
| `refactor` | 代码重构 | `refactor: 重构图片处理逻辑` |
| `perf` | 性能优化 | `perf: 优化图片压缩算法` |
| `test` | 测试相关 | `test: 添加单元测试` |
| `chore` | 构建/部署 | `chore: 更新部署脚本` |

## 🔧 常用命令速查

### 本地开发
```bash
# 启动开发服务器
python3 -m http.server 8080

# 检查Git状态
git status && git log --oneline -3

# 一键部署
./dev-deploy.sh
```

### 服务器管理
```bash
# SSH登录
ssh root@47.92.236.28

# 进入项目目录
cd /var/www/document-scanner

# 查看服务状态
ps aux | grep python3
netstat -tlpn | grep 8080

# 查看日志
tail -f server.log

# 重启服务
pkill -f python3
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &

# 自动部署
./server-deploy.sh
```

### 故障排查
```bash
# 检查网络连接
ping 47.92.236.28

# 检查服务器磁盘空间
ssh root@47.92.236.28 "df -h"

# 查看服务器进程
ssh root@47.92.236.28 "ps aux | grep python"

# 测试网站访问
curl -I http://47.92.236.28:8080

# 查看详细日志
ssh root@47.92.236.28 "cd /var/www/document-scanner && tail -50 server.log"
```

## 📊 环境信息

### 本地环境
- **路径**: `/Users/peakom/document-scanner`
- **测试地址**: `http://localhost:8080`
- **Git仓库**: `https://github.com/peakcary/document-scanner.git`

### 服务器环境
- **服务器**: `47.92.236.28`
- **用户**: `root`
- **密码**: `Pp--9257`
- **项目路径**: `/var/www/document-scanner`
- **访问地址**: `http://47.92.236.28:8080`

## 🚨 紧急恢复

### 网站宕机快速恢复
```bash
ssh root@47.92.236.28
cd /var/www/document-scanner

# 快速重启
pkill -f python3
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &
```

### 回滚到备份
```bash
# 查看可用备份
ls -la ../backup-*

# 恢复最新备份
LATEST_BACKUP=$(ls -t ../backup-* | head -1)
rm -rf ./*
cp -r "$LATEST_BACKUP"/* .
chmod +x *.sh
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &
```

## ✅ 部署检查清单

### 部署前
- [ ] 本地功能测试通过
- [ ] 代码已提交到Git
- [ ] 网络连接正常

### 部署后
- [ ] 服务器进程正常运行
- [ ] 网站可以正常访问
- [ ] 新功能工作正常
- [ ] 日志无严重错误

## 🎯 开发提示

1. **本地优先**: 始终在本地测试通过后再部署
2. **小步快跑**: 频繁提交，每次修改都应该可部署
3. **备份意识**: 重要修改前创建备份
4. **日志监控**: 部署后检查服务器日志
5. **性能关注**: 关注网站加载速度和响应时间

## 📞 快速联系

**项目相关**:
- GitHub: https://github.com/peakcary/document-scanner
- 线上地址: http://47.92.236.28:8080

**服务器信息**:
- IP: 47.92.236.28
- SSH: `ssh root@47.92.236.28`
- 项目目录: `/var/www/document-scanner`

---

**💡 记住：`./dev-deploy.sh` 是你的最佳朋友！**