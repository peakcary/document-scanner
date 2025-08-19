#!/bin/bash

# 智能部署策略脚本
# 自动选择Git或TCP推送，并处理状态同步

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

echo "=========================================="
echo "  智能部署系统"
echo "  Git + TCP双重保障 + 自动同步"
echo "=========================================="

# 检查是否有未提交的修改
check_local_changes() {
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "检测到未提交的本地修改"
        git status --short
        echo ""
        read -p "是否提交这些修改? (Y/n): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo "请输入提交信息:"
            read -p "提交信息: " COMMIT_MSG
            
            if [ -z "$COMMIT_MSG" ]; then
                COMMIT_MSG="Update: $(date '+%Y-%m-%d %H:%M:%S')"
            fi
            
            git add .
            git commit -m "$COMMIT_MSG"
            print_success "本地修改已提交"
        fi
    fi
}

# 测试Git连接
test_git_connection() {
    print_step "测试Git连接..."
    
    # 测试GitHub连接
    if timeout 10 git ls-remote origin > /dev/null 2>&1; then
        print_success "Git连接正常"
        return 0
    else
        print_warning "Git连接失败"
        return 1
    fi
}

# Git部署流程
deploy_with_git() {
    print_step "使用Git部署..."
    
    # 推送到远程
    if git push origin main; then
        print_success "Git推送成功"
        
        echo ""
        print_success "📋 服务器端操作指南:"
        echo "1. SSH登录服务器: ssh root@47.92.236.28"
        echo "2. 进入项目目录: cd /var/www/document-scanner"
        echo "3. 拉取最新代码: git pull origin main"
        echo "4. 执行部署脚本: ./update-and-deploy.sh"
        echo "5. 验证部署结果: 访问 http://47.92.236.28:8080"
        
        return 0
    else
        print_error "Git推送失败"
        return 1
    fi
}

# TCP部署流程
deploy_with_tcp() {
    print_step "使用TCP推送部署..."
    
    print_warning "📋 TCP推送需要两个步骤:"
    echo ""
    echo "步骤1: 在服务器启动TCP接收服务"
    echo "  ssh root@47.92.236.28"
    echo "  cd /var/www/document-scanner"
    echo "  python3 tcp-receiver.py"
    echo ""
    echo "步骤2: 在本地执行TCP推送"
    echo "  python3 tcp-push.py"
    echo ""
    
    read -p "服务器端TCP接收服务是否已启动? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "执行TCP推送..."
        
        if python3 tcp-push.py; then
            print_success "TCP推送成功"
            
            echo ""
            print_success "📋 服务器端操作指南:"
            echo "1. 在TCP接收服务窗口按 Ctrl+C 停止服务"
            echo "2. 执行部署脚本: ./update-and-deploy.sh"
            echo "3. 选择 '使用TCP推送的文件'"
            echo "4. 同步Git状态: ./sync-git-after-tcp.sh"
            echo "5. 验证部署结果: 访问 http://47.92.236.28:8080"
            
            return 0
        else
            print_error "TCP推送失败"
            return 1
        fi
    else
        print_error "请先启动服务器端TCP接收服务"
        return 1
    fi
}

# 主部署逻辑
main_deploy() {
    # 检查本地修改
    check_local_changes
    
    # 检查必需文件
    if [ ! -f "tcp-push.py" ]; then
        print_error "TCP推送脚本不存在"
        exit 1
    fi
    
    echo ""
    print_step "选择部署策略..."
    
    # 自动测试Git连接
    if test_git_connection; then
        echo ""
        print_success "🎯 推荐使用Git部署（网络连接正常）"
        echo "1. Git部署（推荐）"
        echo "2. TCP推送"
        echo ""
        read -p "请选择部署方式 (1/2): " -n 1 -r
        echo ""
        
        case $REPLY in
            1)
                if deploy_with_git; then
                    print_success "🎉 Git部署完成！"
                else
                    print_warning "Git部署失败，自动切换到TCP推送"
                    deploy_with_tcp
                fi
                ;;
            2)
                deploy_with_tcp
                ;;
            *)
                print_warning "无效选择，使用Git部署"
                deploy_with_git
                ;;
        esac
    else
        echo ""
        print_warning "⚠️  Git连接失败，自动使用TCP推送"
        deploy_with_tcp
    fi
}

# 显示使用说明
show_usage() {
    echo ""
    print_success "💡 智能部署系统特性:"
    echo "  ✅ 自动检测网络状况"
    echo "  ✅ Git失败自动切换TCP"
    echo "  ✅ 提供详细操作指导"
    echo "  ✅ 支持状态同步"
    echo ""
    print_success "🔄 后续更新流程:"
    echo "  1. 本地修改代码"
    echo "  2. 运行 ./smart-deploy.sh"
    echo "  3. 按照提示完成部署"
    echo "  4. 系统自动处理Git/TCP选择"
    echo ""
    print_success "🛠️ 工具脚本:"
    echo "  - ./smart-deploy.sh      # 智能部署（推荐）"
    echo "  - ./deploy-local.sh      # 传统部署助手"
    echo "  - ./sync-git-after-tcp.sh # TCP后Git同步"
    echo "  - python3 tcp-push.py   # 直接TCP推送"
}

# 检查运行环境
if [ ! -f "index.html" ]; then
    print_error "请在项目根目录执行此脚本"
    exit 1
fi

if ! git status > /dev/null 2>&1; then
    print_error "当前目录不是Git仓库"
    exit 1
fi

# 执行主流程
main_deploy

# 显示使用说明
show_usage

echo ""
print_success "🎯 智能部署系统使用完毕！"