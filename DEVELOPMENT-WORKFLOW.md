# 🔄 项目开发部署标准流程

## 📋 概述

本文档定义了文档扫描器项目的标准开发、测试、部署流程，确保本地开发与服务器生产环境的一致性。

## 🎯 开发流程架构

```
本地开发 → 本地测试 → Git提交 → 打包上传 → 服务器部署 → 线上验证
```

## 📂 项目结构

```
document-scanner/
├── index.html              # 主页面
├── css/style.css           # 样式文件  
├── js/                     # JavaScript文件
│   ├── app.js              # 主应用逻辑
│   └── image-processor.js  # 图片处理
├── *.sh                    # 部署和管理脚本
├── README.md               # 项目说明
└── docs/                   # 文档目录
```

## 🛠️ 标准开发流程

### 第1阶段：本地开发

#### 1.1 启动本地开发环境
```bash
# 进入项目目录
cd /Users/peakom/document-scanner

# 启动本地开发服务器
python3 -m http.server 8080

# 在浏览器中打开
open http://localhost:8080
```

#### 1.2 进行代码修改
- **前端修改**：编辑 `index.html`、`css/style.css`、`js/*.js`
- **功能开发**：添加新功能、修复Bug、优化性能
- **脚本更新**：修改部署脚本、添加新工具

#### 1.3 本地测试验证
```bash
# 功能测试检查清单
□ 页面正常加载
□ 图片上传功能正常
□ 图片处理功能正常  
□ PDF生成功能正常
□ 移动端兼容性测试
□ 浏览器兼容性测试
```

### 第2阶段：版本控制

#### 2.1 检查修改状态
```bash
# 查看修改的文件
git status

# 查看具体修改内容
git diff
```

#### 2.2 提交到本地Git
```bash
# 添加修改的文件
git add .

# 提交修改（使用规范的提交信息）
git commit -m "feat: 添加新功能描述"
# 或
git commit -m "fix: 修复具体问题"
# 或  
git commit -m "style: 优化界面样式"
```

#### 2.3 推送到远程仓库
```bash
# 推送到GitHub
git push origin main
```

### 第3阶段：打包准备

#### 3.1 创建部署包
```bash
# 创建时间戳代码包
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
tar --exclude='.git' \
    --exclude='*.tar.gz' \
    --exclude='.DS_Store' \
    --exclude='node_modules' \
    --exclude='*.tmp' \
    -czf "deploy-${TIMESTAMP}.tar.gz" .

echo "✅ 部署包创建: deploy-${TIMESTAMP}.tar.gz"
```

#### 3.2 验证包内容
```bash
# 检查包的大小和内容
ls -lh deploy-*.tar.gz
tar -tzf deploy-*.tar.gz | head -20
```

### 第4阶段：上传到服务器

#### 4.1 上传部署包
```bash
# 获取最新的部署包
LATEST_PACKAGE=$(ls -t deploy-*.tar.gz | head -1)

# 上传到服务器
scp "$LATEST_PACKAGE" root@47.92.236.28:/tmp/

echo "✅ 部署包已上传: $LATEST_PACKAGE"
```

#### 4.2 确认上传成功
```bash
# SSH检查文件是否上传成功
ssh root@47.92.236.28 "ls -la /tmp/deploy-*.tar.gz"
```

### 第5阶段：服务器部署

#### 5.1 SSH登录服务器
```bash
ssh root@47.92.236.28
```

#### 5.2 执行标准部署流程
```bash
# 进入项目目录
cd /var/www/document-scanner

# 停止现有服务
pkill -f "python3 -m http.server" 2>/dev/null || true

# 创建当前状态备份
BACKUP_DIR="../backup-$(date +%Y%m%d_%H%M%S)"
cp -r . "$BACKUP_DIR"
echo "✅ 备份创建: $BACKUP_DIR"

# 清空当前目录（保留.git）
find . -maxdepth 1 -not -name '.' -not -name '.git' -exec rm -rf {} \;

# 解压最新部署包
DEPLOY_PACKAGE=$(ls -t /tmp/deploy-*.tar.gz | head -1)
tar -xzf "$DEPLOY_PACKAGE"
echo "✅ 代码部署完成"

# 设置文件权限
chmod +x *.sh
chmod 644 *.html *.css *.js *.md 2>/dev/null || true

# 修复Git兼容性（重要！）
sed -i 's/git stash push -m/git stash save/g' *.sh

# 同步Git状态
git add . 2>/dev/null || true
git commit -m "Deploy update: $(date)" 2>/dev/null || true

# 启动HTTP服务
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &

echo "✅ 服务启动完成"
```

#### 5.3 验证部署结果
```bash
# 等待服务启动
sleep 3

# 检查服务状态
ps aux | grep "python3 -m http.server"

# 测试本地访问
curl -I http://localhost:8080

# 检查日志
tail -5 server.log

echo "✅ 部署验证完成"
```

### 第6阶段：线上验证

#### 6.1 功能验证清单
```bash
# 在浏览器中验证以下功能：
□ 访问 http://47.92.236.28:8080 页面正常加载
□ 图片上传功能正常
□ 图片裁剪功能正常
□ PDF生成功能正常
□ 移动端访问正常
□ 新增功能工作正常
```

#### 6.2 性能检查
```bash
# 在服务器上检查性能
htop                    # 查看CPU和内存使用
df -h                   # 查看磁盘使用
netstat -tlpn | grep 8080  # 查看端口状态
```

## 🚀 快速部署脚本

为简化流程，我会创建自动化脚本：

### 本地快速部署脚本（dev-deploy.sh）
```bash
#!/bin/bash
# 本地开发到服务器部署一键脚本

echo "🚀 开始开发部署流程..."

# 1. 检查本地修改
if [ -n "$(git status --porcelain)" ]; then
    echo "📝 提交本地修改..."
    git add .
    read -p "提交信息: " msg
    git commit -m "$msg"
    git push origin main
fi

# 2. 创建部署包
echo "📦 创建部署包..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
tar --exclude='.git' --exclude='*.tar.gz' --exclude='.DS_Store' -czf "deploy-${TIMESTAMP}.tar.gz" .

# 3. 上传到服务器
echo "📤 上传到服务器..."
scp "deploy-${TIMESTAMP}.tar.gz" root@47.92.236.28:/tmp/

# 4. 触发服务器部署
echo "🔄 触发服务器部署..."
ssh root@47.92.236.28 "cd /var/www/document-scanner && ./server-deploy.sh"

echo "✅ 部署完成！访问: http://47.92.236.28:8080"
```

### 服务器自动部署脚本（server-deploy.sh）
```bash
#!/bin/bash
# 服务器端自动部署脚本

echo "🔄 服务器部署开始..."

# 停止服务
pkill -f "python3 -m http.server" 2>/dev/null || true

# 备份当前状态
BACKUP_DIR="../backup-$(date +%Y%m%d_%H%M%S)"
cp -r . "$BACKUP_DIR"

# 部署最新代码
find . -maxdepth 1 -not -name '.' -not -name '.git' -exec rm -rf {} \;
DEPLOY_PACKAGE=$(ls -t /tmp/deploy-*.tar.gz | head -1)
tar -xzf "$DEPLOY_PACKAGE"

# 设置权限和修复兼容性
chmod +x *.sh
sed -i 's/git stash push -m/git stash save/g' *.sh

# 启动服务
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &

echo "✅ 服务器部署完成"
```

## 📊 开发环境配置

### 本地开发环境
- **操作系统**: macOS
- **Python**: 3.x
- **Git**: 任意版本
- **编辑器**: 任意（推荐VSCode）

### 服务器生产环境
- **操作系统**: Linux
- **Python**: 3.x
- **Git**: 支持基础命令
- **Web服务**: Python HTTP Server

## 🔧 常见问题解决

### 问题1：上传失败
```bash
# 解决方案
ping 47.92.236.28                    # 检查网络
scp -v deploy-*.tar.gz root@47.92.236.28:/tmp/  # 详细模式上传
```

### 问题2：服务器部署失败
```bash
# 检查服务器状态
ssh root@47.92.236.28
cd /var/www/document-scanner
tail -f server.log                   # 查看错误日志
ps aux | grep python3                # 检查进程状态
```

### 问题3：网站无法访问
```bash
# 服务器端检查
netstat -tlpn | grep 8080            # 检查端口
ufw status                           # 检查防火墙
curl -I http://localhost:8080        # 本地测试
```

## 📋 部署检查清单

### 部署前检查
- [ ] 本地功能测试通过
- [ ] 代码已提交到Git
- [ ] 部署包创建成功
- [ ] 服务器连接正常

### 部署后检查
- [ ] 服务进程正常运行
- [ ] 网站可以正常访问
- [ ] 新功能工作正常
- [ ] 日志无错误信息
- [ ] 备份已创建

## 🎯 最佳实践

### 1. 提交信息规范
```
feat: 添加新功能
fix: 修复Bug
style: 样式调整
docs: 文档更新
refactor: 代码重构
test: 测试相关
chore: 杂务（构建、部署等）
```

### 2. 测试策略
- **本地测试**: 每次修改后必须本地测试
- **功能测试**: 验证所有核心功能
- **兼容性测试**: 检查不同浏览器和设备
- **性能测试**: 确保性能不退化

### 3. 部署安全
- **始终备份**: 部署前创建备份
- **权限检查**: 确保文件权限正确
- **日志监控**: 部署后检查日志
- **回滚准备**: 准备快速回滚方案

### 4. 版本管理
- **有意义的提交**: 每个提交都应该有明确目的
- **定期推送**: 避免本地代码堆积
- **标签管理**: 重要版本打标签
- **分支策略**: 功能开发使用分支

## 📞 紧急处理

### 网站宕机处理
```bash
# 1. 快速重启服务
ssh root@47.92.236.28
cd /var/www/document-scanner
pkill -f python3
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &

# 2. 如果仍有问题，回滚到备份
LATEST_BACKUP=$(ls -t ../backup-* | head -1)
rm -rf ./*
cp -r "$LATEST_BACKUP"/* .
chmod +x *.sh
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &
```

### 数据恢复
```bash
# 查看可用备份
ls -la ../backup-*

# 恢复指定备份
cp -r ../backup-YYYYMMDD_HHMMSS/* .
```

---

## 🎉 流程总结

**标准开发流程：**
1. **本地开发** → 修改代码并测试
2. **Git管理** → 提交并推送代码  
3. **打包上传** → 创建部署包并上传
4. **服务器部署** → 解压代码并重启服务
5. **验证确认** → 检查功能和性能

**这个流程确保了代码质量、部署安全和系统稳定性！**