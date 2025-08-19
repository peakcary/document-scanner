#!/bin/bash

# TCP推送后Git状态同步脚本
# 解决TCP推送和Git状态不一致的问题

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

echo "================================================"
echo "  TCP推送后Git状态同步工具"
echo "  解决文件和Git版本不一致问题"
echo "================================================"

# 检查是否在Git仓库中
if [ ! -d ".git" ]; then
    print_error "当前目录不是Git仓库"
    exit 1
fi

print_step "分析当前Git状态..."

# 显示当前状态
echo "当前分支: $(git branch --show-current)"
echo "最新本地提交: $(git log --oneline -1)"

# 检查远程连接
print_step "检查远程仓库连接..."
if git ls-remote origin > /dev/null 2>&1; then
    print_success "远程仓库连接正常"
    REMOTE_AVAILABLE=true
else
    print_warning "远程仓库连接失败"
    REMOTE_AVAILABLE=false
fi

# 检查文件状态
MODIFIED_FILES=$(git status --porcelain | wc -l)
if [ "$MODIFIED_FILES" -gt 0 ]; then
    print_warning "检测到 $MODIFIED_FILES 个文件与Git记录不同"
    echo "修改的文件:"
    git status --short
else
    print_success "文件状态与Git记录一致"
fi

echo ""
print_step "选择同步策略..."
echo "1. 强制同步Git到当前文件状态（推荐）"
echo "2. 重置文件到最后已知的Git状态"
echo "3. 创建新提交包含TCP推送的更改"
echo "4. 仅显示状态，不做任何更改"
echo ""
read -p "请选择同步策略 (1-4): " -n 1 -r
echo ""

case $REPLY in
    1)
        sync_git_to_files
        ;;
    2)
        reset_files_to_git
        ;;
    3)
        create_commit_for_tcp_changes
        ;;
    4)
        show_status_only
        ;;
    *)
        print_warning "无效选择，默认使用策略1"
        sync_git_to_files
        ;;
esac

# 策略1: 强制同步Git到当前文件状态
sync_git_to_files() {
    print_step "执行策略1: 强制同步Git到当前文件状态"
    
    if [ "$REMOTE_AVAILABLE" = true ]; then
        print_step "获取远程最新信息..."
        git fetch origin main 2>/dev/null || true
        
        print_step "强制重置本地Git到远程最新状态..."
        git reset --hard origin/main
        
        print_success "Git已同步到远程最新状态"
        print_success "TCP推送的文件已成为当前工作状态"
    else
        print_warning "远程不可用，无法同步"
        print_warning "当前文件状态保持不变"
    fi
    
    show_final_status
}

# 策略2: 重置文件到最后已知的Git状态
reset_files_to_git() {
    print_step "执行策略2: 重置文件到Git状态"
    
    print_warning "⚠️  这将丢失TCP推送的所有更改！"
    read -p "确认重置文件到Git状态? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git checkout -- .
        print_success "文件已重置到Git状态"
        print_warning "TCP推送的更改已丢失"
    else
        print_warning "重置操作已取消"
    fi
    
    show_final_status
}

# 策略3: 创建新提交包含TCP推送的更改
create_commit_for_tcp_changes() {
    print_step "执行策略3: 创建提交包含TCP更改"
    
    if [ "$MODIFIED_FILES" -eq 0 ]; then
        print_success "没有需要提交的更改"
        return
    fi
    
    print_step "准备提交TCP推送的更改..."
    git add .
    
    echo "请输入提交信息（描述TCP推送的更改）:"
    read -p "提交信息: " COMMIT_MSG
    
    if [ -z "$COMMIT_MSG" ]; then
        COMMIT_MSG="TCP推送更新: $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    
    git commit -m "$COMMIT_MSG"
    print_success "TCP更改已提交到本地Git"
    
    if [ "$REMOTE_AVAILABLE" = true ]; then
        read -p "是否推送到远程仓库? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if git push origin main; then
                print_success "已推送到远程仓库"
            else
                print_warning "推送失败，提交仅保存在本地"
            fi
        fi
    fi
    
    show_final_status
}

# 策略4: 仅显示状态
show_status_only() {
    print_step "当前详细状态"
    
    echo ""
    echo "Git分支信息:"
    git branch -vv
    
    echo ""
    echo "最近3次提交:"
    git log --oneline -3
    
    if [ "$REMOTE_AVAILABLE" = true ]; then
        echo ""
        echo "与远程的差异:"
        git log --oneline HEAD..origin/main 2>/dev/null || echo "  无法获取远程差异"
    fi
    
    echo ""
    echo "文件状态:"
    if [ "$MODIFIED_FILES" -gt 0 ]; then
        git status --short
    else
        echo "  无修改文件"
    fi
}

# 显示最终状态
show_final_status() {
    echo ""
    print_success "📊 同步完成！当前状态:"
    echo "  Git提交: $(git log --oneline -1)"
    echo "  修改文件: $(git status --porcelain | wc -l) 个"
    echo "  分支状态: $(git branch --show-current)"
    
    if [ "$REMOTE_AVAILABLE" = true ]; then
        echo "  远程状态: 可连接"
    else
        echo "  远程状态: 连接失败"
    fi
    
    echo ""
    print_success "🎯 后续建议:"
    if [ "$REMOTE_AVAILABLE" = true ]; then
        echo "  1. 可以正常使用git pull/push"
        echo "  2. TCP推送作为备用方案"
    else
        echo "  1. 继续使用TCP推送直到网络修复"
        echo "  2. 网络修复后再同步Git状态"
    fi
    echo "  3. 使用 ./deploy-local.sh 进行日常部署"
}

# 提供使用建议
echo ""
print_success "💡 使用建议:"
echo "  - 网络正常时优先使用Git"
echo "  - 网络问题时使用TCP推送"
echo "  - 定期执行此脚本同步状态"
echo "  - 重要更改建议两种方式都备份"