#!/bin/bash

# 文档扫描器 - 本地开发助手脚本
# 仅处理本地Git操作，不涉及服务器

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
    echo -e "${YELLOW}[提醒]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

show_deployment_options() {
    print_warning "📋 选择部署方式:"
    echo "1. 标准Git部署（推荐）"
    echo "2. TCP直接推送（网络不稳定时使用）"
    echo ""
    read -p "请选择部署方式 (1/2): " -n 1 -r
    echo ""
    
    case $REPLY in
        1)
            show_git_deployment_steps
            ;;
        2)
            perform_tcp_push
            ;;
        *)
            show_git_deployment_steps
            ;;
    esac
}

show_git_deployment_steps() {
    print_warning "📋 Git部署流程:"
    echo "1. SSH登录服务器:"
    echo "   ssh root@47.92.236.28"
    echo ""
    echo "2. 进入项目目录:"
    echo "   cd /var/www/document-scanner"
    echo ""
    echo "3. 拉取最新代码:"
    echo "   git pull origin main"
    echo ""
    echo "4. 执行部署脚本:"
    echo "   ./update-and-deploy.sh"
    echo ""
    echo "5. 验证部署结果:"
    echo "   访问 http://47.92.236.28:8080"
}

perform_tcp_push() {
    print_step "🚀 启动TCP推送..."
    
    if [ ! -f "tcp-push.py" ]; then
        print_error "TCP推送脚本不存在: tcp-push.py"
        print_error "请确保项目文件完整"
        exit 1
    fi
    
    # 检查Python
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        print_error "未找到Python环境"
        exit 1
    fi
    
    echo ""
    print_warning "⚠️  TCP推送注意事项:"
    echo "1. 确保服务器端TCP接收服务正在运行"
    echo "2. 确保防火墙开放9999端口"
    echo "3. TCP推送完成后仍需手动执行部署脚本"
    echo ""
    
    read -p "确认继续TCP推送? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "执行TCP推送..."
        $PYTHON_CMD tcp-push.py
        
        if [ $? -eq 0 ]; then
            echo ""
            print_success "🎉 TCP推送完成！"
            echo ""
            print_warning "📋 下一步手动部署流程:"
            echo "1. SSH登录服务器:"
            echo "   ssh root@47.92.236.28"
            echo ""
            echo "2. 进入项目目录:"
            echo "   cd /var/www/document-scanner"
            echo ""
            echo "3. 停止TCP服务(如果正在运行):"
            echo "   Ctrl+C"
            echo ""
            echo "4. 执行部署脚本:"
            echo "   ./update-and-deploy.sh"
            echo ""
            echo "5. 验证部署结果:"
            echo "   访问 http://47.92.236.28:8080"
        else
            print_error "TCP推送失败"
            echo ""
            print_warning "可尝试以下解决方案:"
            echo "1. 检查网络连接: ping 47.92.236.28"
            echo "2. 确认服务器端TCP服务: ssh root@47.92.236.28"
            echo "3. 使用Git部署方式"
        fi
    else
        print_warning "TCP推送取消"
        show_git_deployment_steps
    fi
}

echo "========================================"
echo "  文档扫描器 - 本地部署助手"
echo "  Git推送 + TCP推送双重保障"
echo "========================================"

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

# 显示当前状态
print_step "当前项目状态..."
echo "当前分支: $(git branch --show-current)"
echo "最新提交: $(git log --oneline -1)"
echo ""

# 检查是否有未提交的修改
UNCOMMITTED_CHANGES=$(git status --porcelain)
if [ -z "$UNCOMMITTED_CHANGES" ]; then
    print_success "没有未提交的修改"
    
    # 检查是否与远程同步
    git fetch origin main
    LOCAL_COMMIT=$(git rev-parse HEAD)
    REMOTE_COMMIT=$(git rev-parse origin/main)
    
    if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
        print_success "本地和远程已同步，无需推送"
    else
        print_warning "本地和远程不同步"
        echo "本地版本: $(git log --oneline -1 $LOCAL_COMMIT)"
        echo "远程版本: $(git log --oneline -1 $REMOTE_COMMIT)"
        echo ""
        read -p "是否推送本地提交到远程? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git push origin main
            print_success "已推送到远程仓库"
        fi
    fi
    
    echo ""
    print_success "🎯 选择部署方式:"
    echo "1. 标准Git部署（推荐）"
    echo "2. TCP直接推送（网络不稳定时使用）"
    echo ""
    read -p "请选择部署方式 (1/2): " -n 1 -r
    echo ""
    
    case $REPLY in
        1)
            show_git_deployment_steps
            ;;
        2)
            perform_tcp_push
            ;;
        *)
            show_git_deployment_steps
            ;;
    esac
    exit 0
fi

# 显示修改内容
print_step "发现未提交的修改:"
git status --short
echo ""

# 显示详细修改
read -p "是否查看详细修改内容? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git diff
    echo ""
fi

# 询问是否提交
read -p "是否提交这些修改? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "准备提交修改..."
    
    # 添加所有修改
    git add .
    
    # 输入提交信息
    echo "请输入提交信息（按Enter使用默认信息）:"
    read -p "提交信息: " COMMIT_MSG
    
    if [ -z "$COMMIT_MSG" ]; then
        COMMIT_MSG="Update: $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    
    # 提交修改
    git commit -m "$COMMIT_MSG"
    print_success "修改已提交"
    
    # 询问是否推送
    read -p "是否推送到GitHub? (Y/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        print_step "推送到GitHub..."
        git push origin main
        if [ $? -eq 0 ]; then
            print_success "已推送到GitHub"
            
            echo ""
            print_success "🚀 Git操作完成！"
            echo ""
            show_deployment_options
        else
            print_error "Git推送失败"
            echo ""
            print_warning "Git推送失败，是否尝试TCP推送?"
            read -p "使用TCP推送到服务器? (y/N): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                perform_tcp_push
            else
                print_error "部署终止"
                exit 1
            fi
        fi
    else
        print_warning "修改已提交到本地，但未推送到远程"
        print_warning "记得稍后执行: git push origin main"
    fi
else
    print_warning "修改未提交，请手动处理后再运行此脚本"
    exit 0
fi