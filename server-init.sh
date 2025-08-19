#!/bin/bash

# 服务器环境初始化脚本
# 检查并创建必要的目录和环境

echo "🔧 服务器环境初始化脚本"
echo "========================"

# 检查当前位置
echo "当前位置: $(pwd)"
echo "当前用户: $(whoami)"

# 检查项目目录是否存在
PROJECT_DIR="/var/www/document-scanner"
echo ""
echo "🔍 检查项目目录..."

if [ -d "$PROJECT_DIR" ]; then
    echo "✅ 项目目录存在: $PROJECT_DIR"
    cd "$PROJECT_DIR"
    echo "进入项目目录成功"
    
    # 检查目录内容
    echo ""
    echo "📁 当前目录内容:"
    ls -la
    
    if [ -f "index.html" ]; then
        echo "✅ 发现主页文件"
    else
        echo "⚠️  未发现主页文件"
    fi
    
else
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    echo ""
    echo "🔧 开始创建项目环境..."
    
    # 创建必要的目录
    mkdir -p /var/www
    echo "✅ 创建 /var/www 目录"
    
    # 检查是否有备份目录
    echo ""
    echo "🔍 查找备份目录..."
    BACKUP_DIRS=$(find /var -name "*document-scanner*" -type d 2>/dev/null)
    
    if [ -n "$BACKUP_DIRS" ]; then
        echo "找到以下相关目录:"
        echo "$BACKUP_DIRS"
        echo ""
        
        # 选择最新的备份
        LATEST_BACKUP=$(echo "$BACKUP_DIRS" | grep backup | sort | tail -1)
        if [ -n "$LATEST_BACKUP" ]; then
            echo "🔄 使用最新备份恢复项目..."
            cp -r "$LATEST_BACKUP" "$PROJECT_DIR"
            echo "✅ 项目从备份恢复: $LATEST_BACKUP"
        fi
    else
        echo "❌ 未找到相关备份目录"
        echo ""
        echo "🆕 创建新的项目目录..."
        mkdir -p "$PROJECT_DIR"
        cd "$PROJECT_DIR"
        
        # 初始化Git仓库
        git init
        git remote add origin https://github.com/peakcary/document-scanner.git
        echo "✅ Git仓库初始化完成"
    fi
fi

# 无论如何，确保在项目目录中
cd "$PROJECT_DIR" || exit 1
echo ""
echo "✅ 当前在项目目录: $(pwd)"

# 检查Git状态
echo ""
echo "🔍 检查Git状态..."
if git status >/dev/null 2>&1; then
    echo "✅ Git仓库正常"
    echo "当前分支: $(git branch --show-current 2>/dev/null || echo '未知')"
    echo "远程地址: $(git remote get-url origin 2>/dev/null || echo '未配置')"
else
    echo "⚠️  Git仓库异常，重新初始化..."
    git init
    git remote add origin https://github.com/peakcary/document-scanner.git 2>/dev/null || true
fi

# 检查项目文件
echo ""
echo "📋 检查项目文件状态..."
FILES_COUNT=$(ls -1 2>/dev/null | wc -l)
echo "当前文件数量: $FILES_COUNT"

if [ "$FILES_COUNT" -lt 5 ]; then
    echo "⚠️  文件数量较少，可能需要重新部署"
    
    # 尝试从Git拉取
    echo "🔄 尝试从GitHub拉取代码..."
    if git fetch origin main 2>/dev/null && git checkout main 2>/dev/null; then
        echo "✅ 从GitHub拉取成功"
    else
        echo "❌ Git拉取失败，需要手动部署"
    fi
fi

# 检查部署包
echo ""
echo "📦 检查部署包..."
DEPLOY_PACKAGES=$(ls /tmp/deploy-*.tar.gz 2>/dev/null | wc -l)
echo "可用部署包数量: $DEPLOY_PACKAGES"

if [ "$DEPLOY_PACKAGES" -gt 0 ]; then
    echo "找到以下部署包:"
    ls -la /tmp/deploy-*.tar.gz
fi

# 检查服务状态
echo ""
echo "🔍 检查HTTP服务状态..."
if ps aux | grep -v grep | grep "python.*http.server" >/dev/null; then
    echo "✅ HTTP服务正在运行"
    ps aux | grep -v grep | grep "python.*http.server"
else
    echo "❌ HTTP服务未运行"
fi

# 检查端口占用
echo ""
echo "🔍 检查端口8080状态..."
if netstat -tlpn 2>/dev/null | grep ":8080 " >/dev/null; then
    echo "⚠️  端口8080被占用"
    netstat -tlpn | grep ":8080 "
else
    echo "✅ 端口8080可用"
fi

# 显示环境总结
echo ""
echo "================================="
echo "🎯 环境检查总结"
echo "================================="
echo "项目目录: $PROJECT_DIR"
echo "目录状态: $([ -d "$PROJECT_DIR" ] && echo "存在" || echo "不存在")"
echo "文件数量: $(ls -1 "$PROJECT_DIR" 2>/dev/null | wc -l)"
echo "Git状态: $(cd "$PROJECT_DIR" && git status >/dev/null 2>&1 && echo "正常" || echo "异常")"
echo "HTTP服务: $(ps aux | grep -v grep | grep "python.*http.server" >/dev/null && echo "运行中" || echo "未运行")"
echo "可用部署包: $(ls /tmp/deploy-*.tar.gz 2>/dev/null | wc -l) 个"
echo ""

# 提供下一步建议
echo "🎯 建议的下一步操作:"

if [ ! -f "$PROJECT_DIR/index.html" ]; then
    echo "1. 项目文件缺失，需要部署:"
    echo "   - 从本地运行: ./dev-deploy.sh"
    echo "   - 或手动上传: scp deploy-*.tar.gz root@47.92.236.28:/tmp/"
elif ps aux | grep -v grep | grep "python.*http.server" >/dev/null; then
    echo "1. 环境正常，服务运行中"
    echo "   - 访问: http://47.92.236.28:8080"
else
    echo "1. 文件存在但服务未运行:"
    echo "   - 启动服务: nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &"
fi

echo ""
echo "🔧 常用管理命令:"
echo "查看项目文件: ls -la $PROJECT_DIR"
echo "启动HTTP服务: cd $PROJECT_DIR && nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &"
echo "查看服务状态: ps aux | grep python"
echo "部署新代码: cd $PROJECT_DIR && ./server-deploy.sh"

echo ""
echo "✅ 环境初始化检查完成！"