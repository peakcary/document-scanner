#!/bin/bash

# 开发到生产一键部署脚本
# 自动化本地开发到服务器部署的完整流程

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[步骤]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

echo "=================================================="
echo "  🚀 开发到生产一键部署工具"
echo "  本地开发 → Git管理 → 服务器部署"
echo "=================================================="

# 检查环境
if [ ! -f "index.html" ]; then
    print_error "请在项目根目录执行此脚本"
    exit 1
fi

if ! git status > /dev/null 2>&1; then
    print_error "当前目录不是Git仓库"
    exit 1
fi

print_success "环境检查通过"

# 第1步：处理本地修改
print_step "检查本地修改状态..."

if [ -n "$(git status --porcelain)" ]; then
    print_warning "发现未提交的本地修改："
    git status --short
    echo ""
    
    read -p "是否提交这些修改? (Y/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        print_step "提交本地修改..."
        git add .
        
        echo "请输入提交信息（按Enter使用默认）:"
        read -p "提交信息: " COMMIT_MSG
        
        if [ -z "$COMMIT_MSG" ]; then
            COMMIT_MSG="Deploy update: $(date '+%Y-%m-%d %H:%M:%S')"
        fi
        
        git commit -m "$COMMIT_MSG"
        
        # 推送到远程
        if git push origin main; then
            print_success "代码已提交并推送到GitHub"
        else
            print_warning "推送失败，继续本地部署"
        fi
    fi
else
    print_success "没有未提交的修改"
fi

# 第2步：创建部署包
print_step "创建部署包..."

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEPLOY_PACKAGE="deploy-${TIMESTAMP}.tar.gz"

tar --exclude='.git' \
    --exclude='*.tar.gz' \
    --exclude='.DS_Store' \
    --exclude='node_modules' \
    --exclude='*.tmp' \
    --exclude='backup-*' \
    -czf "$DEPLOY_PACKAGE" .

if [ -f "$DEPLOY_PACKAGE" ]; then
    PACKAGE_SIZE=$(ls -lh "$DEPLOY_PACKAGE" | awk '{print $5}')
    print_success "部署包创建成功: $DEPLOY_PACKAGE ($PACKAGE_SIZE)"
else
    print_error "部署包创建失败"
    exit 1
fi

# 第3步：上传到服务器
print_step "上传部署包到服务器..."

if scp "$DEPLOY_PACKAGE" root@47.92.236.28:/tmp/; then
    print_success "部署包上传成功"
else
    print_error "部署包上传失败"
    print_error "请检查网络连接和服务器状态"
    exit 1
fi

# 第4步：服务器部署
print_step "在服务器上执行部署..."

# 创建服务器端部署脚本
SERVER_DEPLOY_SCRIPT="
#!/bin/bash
echo '🔄 服务器端部署开始...'

cd /var/www/document-scanner || exit 1

# 停止现有服务
echo '停止现有服务...'
pkill -f 'python3 -m http.server' 2>/dev/null || true
pkill -f 'python -m http.server' 2>/dev/null || true
sleep 2

# 创建备份
echo '创建备份...'
BACKUP_DIR=\"../backup-\$(date +%Y%m%d_%H%M%S)\"
cp -r . \"\$BACKUP_DIR\"
echo \"✅ 备份创建: \$BACKUP_DIR\"

# 清空当前目录（保留.git）
echo '清空当前目录...'
find . -maxdepth 1 -not -name '.' -not -name '.git' -exec rm -rf {} \\;

# 解压最新部署包
echo '解压部署包...'
DEPLOY_PACKAGE=\$(ls -t /tmp/deploy-*.tar.gz | head -1)
if [ -f \"\$DEPLOY_PACKAGE\" ]; then
    tar -xzf \"\$DEPLOY_PACKAGE\"
    echo \"✅ 代码解压完成: \$DEPLOY_PACKAGE\"
else
    echo \"❌ 未找到部署包\"
    exit 1
fi

# 设置文件权限
echo '设置文件权限...'
chmod +x *.sh 2>/dev/null || true
chmod 644 *.html *.css *.js *.md 2>/dev/null || true

# 修复Git兼容性
echo '修复Git兼容性...'
for file in *.sh; do
    if [ -f \"\$file\" ] && grep -q 'git stash push' \"\$file\" 2>/dev/null; then
        sed -i 's/git stash push -m/git stash save/g' \"\$file\"
        echo \"修复: \$file\"
    fi
done

# 同步Git状态
echo '同步Git状态...'
if git status >/dev/null 2>&1; then
    git add . 2>/dev/null || true
    git commit -m 'Deploy update: \$(date)' 2>/dev/null || true
fi

# 启动HTTP服务
echo '启动HTTP服务...'
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &

# 等待服务启动
sleep 3

# 验证服务状态
if ps aux | grep -v grep | grep 'python3 -m http.server 8080' > /dev/null; then
    PID=\$(ps aux | grep -v grep | grep 'python3 -m http.server 8080' | awk '{print \$2}')
    echo \"✅ HTTP服务启动成功 (PID: \$PID)\"
else
    echo \"❌ HTTP服务启动失败\"
    echo \"错误日志:\"
    tail -5 server.log 2>/dev/null || echo \"无日志文件\"
    exit 1
fi

# 测试访问
if curl -s -o /dev/null -w '%{http_code}' http://localhost:8080 | grep -q '200'; then
    echo \"✅ 网站访问测试通过\"
else
    echo \"⚠️  网站访问测试失败\"
fi

echo \"\"
echo \"🎉 服务器部署完成！\"
echo \"访问地址: http://47.92.236.28:8080\"
echo \"日志位置: ./server.log\"
echo \"备份位置: \$BACKUP_DIR\"

# 清理旧的部署包（保留最近5个）
rm -f /tmp/deploy-*.tar.gz
"

# 执行服务器端部署
if ssh root@47.92.236.28 "$SERVER_DEPLOY_SCRIPT"; then
    print_success "服务器部署完成"
else
    print_error "服务器部署失败"
    exit 1
fi

# 第5步：验证部署结果
print_step "验证部署结果..."

# 测试网站访问
if curl -s -o /dev/null -w "%{http_code}" http://47.92.236.28:8080 | grep -q "200"; then
    print_success "网站访问测试通过"
else
    print_warning "网站访问测试失败，可能需要等待服务启动"
fi

# 清理本地临时文件
print_step "清理本地临时文件..."
rm -f "$DEPLOY_PACKAGE"
print_success "本地临时文件已清理"

# 显示部署结果
echo ""
echo "=================================================="
print_success "🎉 一键部署完成！"
echo "=================================================="
echo ""
print_success "部署信息:"
echo "  本地版本: $(git log --oneline -1)"
echo "  部署时间: $(date)"
echo "  部署包: $DEPLOY_PACKAGE"
echo ""
print_success "访问地址:"
echo "  🌐 线上网站: http://47.92.236.28:8080"
echo "  🖥️  本地测试: http://localhost:8080"
echo ""
print_success "管理命令:"
echo "  查看服务器日志: ssh root@47.92.236.28 'cd /var/www/document-scanner && tail -f server.log'"
echo "  重启服务器服务: ssh root@47.92.236.28 'cd /var/www/document-scanner && ./server-quick-fix.sh'"
echo "  查看服务器状态: ssh root@47.92.236.28 'ps aux | grep python3'"
echo ""

# 询问是否打开网站
read -p "是否在浏览器中打开网站? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    open http://47.92.236.28:8080
fi

print_success "🚀 部署流程全部完成！"