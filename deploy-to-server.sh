#!/bin/bash

# 文档扫描器 - 本地到服务器快速部署脚本

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

# 服务器配置
SERVER="47.92.236.28"
SERVER_USER="root"
SERVER_PASSWORD="Pp--9257"
SERVER_PATH="/var/www/document-scanner"

echo "======================================"
echo "  文档扫描器 - 快速部署到服务器"
echo "  本地 → GitHub → 服务器自动更新"
echo "======================================"

# 检查是否在项目目录
if [ ! -f "index.html" ]; then
    print_error "请在项目根目录执行此脚本"
    exit 1
fi

# 检查Git状态
print_step "检查Git状态..."
if ! git status > /dev/null 2>&1; then
    print_error "当前目录不是Git仓库"
    exit 1
fi

# 检查是否有未提交的修改
UNCOMMITTED_CHANGES=$(git status --porcelain)
if [ -n "$UNCOMMITTED_CHANGES" ]; then
    print_step "发现未提交的修改:"
    git status --short
    echo ""
    
    read -p "是否要提交这些修改? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "添加所有修改到Git..."
        git add .
        
        read -p "请输入提交信息: " COMMIT_MSG
        if [ -z "$COMMIT_MSG" ]; then
            COMMIT_MSG="Update: $(date '+%Y-%m-%d %H:%M:%S')"
        fi
        
        git commit -m "$COMMIT_MSG"
        print_success "修改已提交"
    else
        print_warning "存在未提交的修改，请先处理"
        exit 1
    fi
fi

# 推送到GitHub
print_step "推送到GitHub..."
git push origin main
if [ $? -eq 0 ]; then
    print_success "代码已推送到GitHub"
else
    print_error "推送失败"
    exit 1
fi

# 触发服务器更新
print_step "连接服务器并触发自动更新..."
sshpass -p "$SERVER_PASSWORD" ssh "$SERVER_USER@$SERVER" "
    echo '开始服务器更新...'
    cd $SERVER_PATH
    ./update-from-git.sh
"

if [ $? -eq 0 ]; then
    echo ""
    print_success "🎉 部署完成！"
    echo ""
    print_success "📱 访问地址: http://$SERVER:8080"
    print_success "📝 GitHub: https://github.com/peakcary/document-scanner"
    echo ""
    print_success "🔧 管理命令:"
    echo "  ./deploy-to-server.sh                    # 重新部署"
    echo "  git log --oneline -5                     # 查看提交历史"
    echo "  sshpass -p '$SERVER_PASSWORD' ssh $SERVER_USER@$SERVER  # 连接服务器"
else
    print_error "部署失败，请检查服务器日志"
    exit 1
fi