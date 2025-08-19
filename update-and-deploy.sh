#!/bin/bash

# 文档扫描器 - 服务器端更新和部署脚本
# 支持Git更新和TCP推送两种方式

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

# 配置
PROJECT_DIR="/var/www/document-scanner"
BACKUP_DIR="/var/www/document-scanner-backups"
SERVICE_PORT=8080
LOG_FILE="server.log"
TCP_PORT=9999

echo "=============================================="
echo "  文档扫描器 - 服务器端部署脚本"
echo "  支持Git和TCP两种更新方式"
echo "=============================================="

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
    print_error "请使用root用户运行此脚本"
    exit 1
fi

# 检查是否在项目目录
if [ ! -f "index.html" ]; then
    print_error "请在项目目录执行此脚本"
    print_error "正确路径: cd $PROJECT_DIR && ./update-and-deploy.sh"
    exit 1
fi

# 创建备份
create_backup() {
    print_step "创建项目备份..."
    timestamp=$(date '+%Y%m%d_%H%M%S')
    backup_path="$BACKUP_DIR/$timestamp"
    
    mkdir -p "$BACKUP_DIR"
    cp -r "$PROJECT_DIR" "$backup_path"
    
    if [ $? -eq 0 ]; then
        print_success "备份创建成功: $backup_path"
        # 保留最近5个备份
        cd "$BACKUP_DIR"
        ls -t | tail -n +6 | xargs rm -rf 2>/dev/null || true
    else
        print_error "备份创建失败"
        exit 1
    fi
}

# 检查Git状态
check_git_status() {
    print_step "检查Git状态..."
    
    if ! git status > /dev/null 2>&1; then
        print_error "当前目录不是Git仓库"
        return 1
    fi
    
    echo "当前分支: $(git branch --show-current)"
    echo "最新提交: $(git log --oneline -1)"
    echo ""
    
    return 0
}

# Git更新
update_from_git() {
    print_step "从GitHub拉取最新代码..."
    
    # 检查网络连接
    if ! ping -c 1 github.com > /dev/null 2>&1; then
        print_error "无法连接到GitHub，网络可能有问题"
        print_warning "建议使用TCP推送方式"
        return 1
    fi
    
    # 保存本地修改（如果有）- 兼容旧版Git
    git stash save "Auto stash before update $(date)" 2>/dev/null || true
    
    # 尝试拉取最新代码
    if git pull origin main; then
        print_success "代码更新成功"
        git log --oneline -3
        return 0
    else
        print_error "Git拉取失败，尝试自动修复..."
        
        # 自动修复Git问题
        fix_git_issues
        
        # 再次尝试拉取
        if git pull origin main; then
            print_success "修复后拉取成功"
            git log --oneline -3
            return 0
        else
            print_error "修复后仍然失败"
            return 1
        fi
    fi
}

# Git问题自动修复
fix_git_issues() {
    print_step "自动修复Git问题..."
    
    # 1. 切换到HTTPS连接
    current_url=$(git remote get-url origin 2>/dev/null || echo "")
    if echo "$current_url" | grep -q "git@github.com:"; then
        https_url=$(echo "$current_url" | sed 's/git@github.com:/https:\/\/github.com\//')
        git remote set-url origin "$https_url"
        print_success "已切换到HTTPS连接"
    fi
    
    # 2. 清理Git缓存
    git gc --prune=now 2>/dev/null || true
    print_success "Git缓存已清理"
    
    # 3. 重置远程追踪
    git fetch origin main 2>/dev/null || true
    git branch --set-upstream-to=origin/main main 2>/dev/null || true
    print_success "远程分支追踪已重置"
    
    # 4. 如果仍然失败，尝试强制同步
    print_warning "尝试强制同步..."
    if git fetch origin main 2>/dev/null && git reset --hard origin/main 2>/dev/null; then
        print_success "强制同步成功"
    else
        print_error "强制同步也失败"
    fi
}

# 检查TCP接收服务状态
check_tcp_service() {
    if ps aux | grep -v grep | grep "tcp-receiver.py" > /dev/null; then
        print_warning "检测到TCP接收服务正在运行"
        print_warning "TCP服务PID: $(ps aux | grep -v grep | grep 'tcp-receiver.py' | awk '{print $2}')"
        
        read -p "是否停止TCP服务? (Y/n): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            pkill -f "tcp-receiver.py" || true
            sleep 2
            print_success "TCP服务已停止"
        fi
    fi
}

# 停止现有服务
stop_service() {
    print_step "停止现有服务..."
    
    # 停止HTTP服务
    pkill -f "python3 -m http.server $SERVICE_PORT" 2>/dev/null || true
    pkill -f "python -m http.server $SERVICE_PORT" 2>/dev/null || true
    
    # 等待进程完全停止
    sleep 2
    
    # 检查端口是否释放
    if netstat -tlpn | grep ":$SERVICE_PORT " > /dev/null; then
        print_warning "端口 $SERVICE_PORT 仍被占用"
        lsof -ti:$SERVICE_PORT | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
    
    print_success "服务已停止"
}

# 启动服务
start_service() {
    print_step "启动HTTP服务..."
    
    # 检查端口是否可用
    if netstat -tlpn | grep ":$SERVICE_PORT " > /dev/null; then
        print_error "端口 $SERVICE_PORT 被占用"
        print_error "运行 'lsof -i:$SERVICE_PORT' 查看占用进程"
        exit 1
    fi
    
    # 启动HTTP服务
    nohup python3 -m http.server $SERVICE_PORT --bind 0.0.0.0 > $LOG_FILE 2>&1 &
    
    # 等待服务启动
    sleep 3
    
    # 检查服务状态
    if ps aux | grep -v grep | grep "python3 -m http.server $SERVICE_PORT" > /dev/null; then
        print_success "HTTP服务启动成功"
        print_success "PID: $(ps aux | grep -v grep | grep 'python3 -m http.server' | awk '{print $2}')"
    else
        print_error "HTTP服务启动失败"
        print_error "查看日志: tail -f $LOG_FILE"
        exit 1
    fi
}

# 验证部署
verify_deployment() {
    print_step "验证部署结果..."
    
    # 测试HTTP访问
    sleep 2
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$SERVICE_PORT | grep -q "200"; then
        print_success "HTTP服务访问正常"
    else
        print_warning "HTTP服务访问异常"
        print_warning "查看日志: tail -f $LOG_FILE"
    fi
    
    # 显示服务状态
    echo ""
    print_success "📊 服务状态:"
    echo "  HTTP服务: $(ps aux | grep -v grep | grep 'python3 -m http.server' | wc -l) 个进程"
    echo "  监听端口: $SERVICE_PORT"
    echo "  日志文件: $LOG_FILE"
    echo "  项目目录: $PROJECT_DIR"
    
    # 显示最近的日志
    echo ""
    print_success "📋 最近日志:"
    tail -n 5 $LOG_FILE 2>/dev/null || echo "  无日志文件"
}

# 主部署流程
main_deployment() {
    echo ""
    print_warning "📋 选择更新方式:"
    echo "1. Git更新（推荐）"
    echo "2. 使用TCP推送的文件（如果刚刚使用了TCP推送）"
    echo "3. 跳过更新，仅重启服务"
    echo ""
    read -p "请选择更新方式 (1/2/3): " -n 1 -r
    echo ""
    
    # 创建备份
    create_backup
    
    case $REPLY in
        1)
            print_step "使用Git更新..."
            if check_git_status && update_from_git; then
                print_success "Git更新完成"
            else
                print_error "Git更新失败"
                exit 1
            fi
            ;;
        2)
            print_step "使用TCP推送的文件..."
            check_tcp_service
            print_success "使用当前文件（TCP推送后的文件）"
            ;;
        3)
            print_step "跳过更新..."
            print_success "仅重启服务"
            ;;
        *)
            print_step "默认使用Git更新..."
            if check_git_status && update_from_git; then
                print_success "Git更新完成"
            else
                print_warning "Git更新失败，使用当前文件"
            fi
            ;;
    esac
    
    # 停止和启动服务
    stop_service
    start_service
    verify_deployment
    
    # 显示结果
    echo ""
    echo "=============================================="
    print_success "🎉 部署完成！"
    echo "=============================================="
    echo ""
    print_success "🌐 访问地址:"
    echo "  本地访问: http://localhost:$SERVICE_PORT"
    echo "  公网访问: http://47.92.236.28:$SERVICE_PORT"
    echo ""
    print_success "🛠️ 管理命令:"
    echo "  查看日志: tail -f $LOG_FILE"
    echo "  重启服务: ./update-and-deploy.sh"
    echo "  查看进程: ps aux | grep python3"
    echo "  停止服务: pkill -f 'python3 -m http.server'"
    echo ""
    print_success "🔧 故障排查:"
    echo "  检查端口: netstat -tlpn | grep $SERVICE_PORT"
    echo "  检查防火墙: ufw status"
    echo "  TCP推送: python3 tcp-receiver.py（启动TCP接收服务）"
    echo ""
    
    # 提供TCP服务启动选项
    echo ""
    read -p "是否启动TCP接收服务以备下次使用? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "启动TCP接收服务..."
        echo ""
        print_warning "⚠️  TCP接收服务将在前台运行"
        print_warning "   使用 Ctrl+C 停止服务"
        print_warning "   端口: $TCP_PORT"
        echo ""
        sleep 3
        python3 tcp-receiver.py
    fi
}

# 执行主流程
main_deployment