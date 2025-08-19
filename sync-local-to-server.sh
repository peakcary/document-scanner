#!/bin/bash

# 本地到服务器完整代码同步脚本
# 确保服务器代码与本地完全一致

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

SERVER_IP="47.92.236.28"
SERVER_USER="root"
SERVER_PATH="/var/www/document-scanner"

echo "================================================"
echo "  本地到服务器完整代码同步工具"
echo "  确保服务器与本地代码100%一致"
echo "================================================"

# 检查本地环境
if [ ! -f "index.html" ]; then
    print_error "请在项目根目录执行此脚本"
    exit 1
fi

if ! git status > /dev/null 2>&1; then
    print_error "当前目录不是Git仓库"
    exit 1
fi

print_success "本地环境检查通过"

# 显示本地状态
print_step "本地代码状态："
echo "当前分支: $(git branch --show-current)"
echo "最新提交: $(git log --oneline -1)"
echo "文件数量: $(find . -type f -not -path './.git/*' | wc -l)"

# 检查是否有未提交的修改
if [ -n "$(git status --porcelain)" ]; then
    print_warning "发现未提交的本地修改："
    git status --short
    echo ""
    read -p "是否先提交这些修改? (Y/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        print_step "提交本地修改..."
        git add .
        
        echo "请输入提交信息（按Enter使用默认）:"
        read -p "提交信息: " COMMIT_MSG
        
        if [ -z "$COMMIT_MSG" ]; then
            COMMIT_MSG="Sync update: $(date '+%Y-%m-%d %H:%M:%S')"
        fi
        
        git commit -m "$COMMIT_MSG"
        git push origin main
        print_success "本地修改已提交并推送"
    fi
fi

# 创建同步包
print_step "创建本地代码包..."
SYNC_PACKAGE="project-sync-$(date +%Y%m%d_%H%M%S).tar.gz"

# 打包所有文件（排除.git和临时文件）
tar --exclude='.git' \
    --exclude='*.tar.gz' \
    --exclude='.DS_Store' \
    --exclude='node_modules' \
    --exclude='*.tmp' \
    -czf "$SYNC_PACKAGE" .

if [ -f "$SYNC_PACKAGE" ]; then
    PACKAGE_SIZE=$(ls -lh "$SYNC_PACKAGE" | awk '{print $5}')
    print_success "代码包创建成功: $SYNC_PACKAGE ($PACKAGE_SIZE)"
else
    print_error "代码包创建失败"
    exit 1
fi

# 测试服务器连接
print_step "测试服务器连接..."
if ping -c 1 $SERVER_IP > /dev/null 2>&1; then
    print_success "服务器网络连接正常"
else
    print_error "无法连接到服务器 $SERVER_IP"
    exit 1
fi

# 上传代码包到服务器
print_step "上传代码包到服务器..."
if scp "$SYNC_PACKAGE" "$SERVER_USER@$SERVER_IP:/tmp/"; then
    print_success "代码包上传成功"
else
    print_error "代码包上传失败"
    exit 1
fi

# 创建服务器端同步脚本
print_step "创建服务器端同步脚本..."
cat > server-sync-script.sh << 'EOF'
#!/bin/bash

# 服务器端代码同步脚本

echo "🔄 服务器端代码同步开始..."

# 进入项目目录
cd /var/www/document-scanner || exit 1

# 停止现有服务
echo "停止现有服务..."
pkill -f "python3 -m http.server" 2>/dev/null || true
pkill -f "python -m http.server" 2>/dev/null || true
sleep 2

# 创建备份
echo "创建当前状态备份..."
BACKUP_DIR="../document-scanner-backup-$(date +%Y%m%d_%H%M%S)"
cp -r . "$BACKUP_DIR"
echo "备份创建: $BACKUP_DIR"

# 清空当前目录（保留.git）
echo "清空当前目录..."
find . -maxdepth 1 -not -name '.' -not -name '.git' -exec rm -rf {} \;

# 解压新代码
echo "解压新代码..."
SYNC_PACKAGE=$(ls /tmp/project-sync-*.tar.gz | head -1)
if [ -f "$SYNC_PACKAGE" ]; then
    tar -xzf "$SYNC_PACKAGE"
    echo "代码解压完成"
else
    echo "❌ 未找到同步包"
    exit 1
fi

# 设置权限
echo "设置文件权限..."
chmod +x *.sh 2>/dev/null || true
chmod 644 *.html *.md *.css *.js 2>/dev/null || true

# 修复Git兼容性
echo "修复Git兼容性..."
for file in *.sh; do
    if [ -f "$file" ] && grep -q "git stash push" "$file" 2>/dev/null; then
        sed -i.bak 's/git stash push -m/git stash save/g' "$file"
        echo "修复 $file"
    fi
done

# 同步Git状态
echo "同步Git状态..."
if git status >/dev/null 2>&1; then
    git add . 2>/dev/null || true
    git commit -m "Server sync: $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null || true
    echo "Git状态已同步"
fi

# 启动服务
echo "启动HTTP服务..."
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &
sleep 3

# 验证服务
if ps aux | grep -v grep | grep "python3 -m http.server 8080" > /dev/null; then
    echo "✅ HTTP服务启动成功"
    PID=$(ps aux | grep -v grep | grep 'python3 -m http.server 8080' | awk '{print $2}')
    echo "服务PID: $PID"
else
    echo "❌ HTTP服务启动失败"
fi

# 测试访问
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
    echo "✅ 网站访问正常"
else
    echo "⚠️ 网站访问异常"
fi

# 显示结果
echo ""
echo "🎉 服务器代码同步完成！"
echo "========================"
echo "备份位置: $BACKUP_DIR"
echo "访问地址: http://47.92.236.28:8080"
echo "日志文件: ./server.log"
echo ""
echo "当前文件列表:"
ls -la *.html *.sh | head -5
echo ""

# 清理临时文件
rm -f "$SYNC_PACKAGE"

echo "🎯 请访问 http://47.92.236.28:8080 验证同步结果！"
EOF

# 上传并执行服务器端脚本
print_step "执行服务器端同步..."
scp server-sync-script.sh "$SERVER_USER@$SERVER_IP:/tmp/"

print_step "在服务器上执行同步..."
ssh "$SERVER_USER@$SERVER_IP" "chmod +x /tmp/server-sync-script.sh && /tmp/server-sync-script.sh"

# 清理本地临时文件
print_step "清理临时文件..."
rm -f "$SYNC_PACKAGE" server-sync-script.sh
print_success "本地临时文件已清理"

# 验证同步结果
print_step "验证同步结果..."
if curl -s -o /dev/null -w "%{http_code}" "http://$SERVER_IP:8080" | grep -q "200"; then
    print_success "服务器访问测试通过"
else
    print_warning "服务器访问测试失败，可能需要等待服务启动"
fi

echo ""
echo "================================================"
print_success "🎉 本地到服务器同步完成！"
echo "================================================"
echo ""
print_success "同步信息:"
echo "  本地版本: $(git log --oneline -1)"
echo "  服务器地址: http://$SERVER_IP:8080"
echo "  同步时间: $(date)"
echo ""
print_success "后续操作:"
echo "  1. 访问 http://$SERVER_IP:8080 验证网站"
echo "  2. 检查功能是否正常"
echo "  3. 如有问题可以SSH到服务器查看日志"
echo ""
print_success "🔧 服务器管理命令:"
echo "  SSH登录: ssh $SERVER_USER@$SERVER_IP"
echo "  查看日志: tail -f $SERVER_PATH/server.log"
echo "  重启服务: pkill -f python3 && cd $SERVER_PATH && nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &"