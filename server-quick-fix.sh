#!/bin/bash

# 服务器端快速修复脚本
# 解决Git版本兼容性和常见部署问题

echo "🚀 服务器端快速修复工具"
echo "======================="

# 1. 检查当前目录
if [ ! -f "index.html" ]; then
    echo "❌ 请在项目目录执行: cd /var/www/document-scanner"
    exit 1
fi

echo "✅ 当前在项目目录"

# 2. 检查Git版本并修复兼容性
echo ""
echo "🔧 检查Git版本..."
git_version=$(git --version 2>/dev/null || echo "Git not found")
echo "Git版本: $git_version"

# 修复Git stash命令兼容性
if [ -f "update-and-deploy.sh" ]; then
    echo "🔧 修复Git兼容性问题..."
    
    # 检查是否有git stash push命令
    if grep -q "git stash push" update-and-deploy.sh 2>/dev/null; then
        echo "  发现git stash push命令，替换为兼容命令..."
        sed -i.bak 's/git stash push -m/git stash save/g' update-and-deploy.sh
        echo "  ✅ 已修复update-and-deploy.sh"
    fi
    
    # 修复其他脚本
    for script in *.sh; do
        if [ "$script" != "server-quick-fix.sh" ] && grep -q "git stash push" "$script" 2>/dev/null; then
            sed -i.bak 's/git stash push -m/git stash save/g' "$script"
            echo "  ✅ 已修复 $script"
        fi
    done
fi

# 3. 清理Git状态
echo ""
echo "🔧 清理Git状态..."
git gc --prune=now 2>/dev/null || true
echo "✅ Git缓存已清理"

# 4. 处理未提交的修改
echo ""
echo "🔍 检查文件状态..."
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "⚠️  发现未提交的修改:"
    git status --short
    
    echo ""
    echo "选择处理方式:"
    echo "1. 保存修改并强制同步到远程"
    echo "2. 放弃修改，重置到远程状态"
    echo "3. 创建提交保留修改"
    read -p "请选择 (1-3): " -n 1 -r
    echo ""
    
    case $REPLY in
        1)
            echo "🔧 保存修改并强制同步..."
            git stash save "Server quick fix backup $(date)" 2>/dev/null || true
            if git fetch origin main 2>/dev/null && git reset --hard origin/main 2>/dev/null; then
                echo "✅ 已同步到远程状态"
            else
                echo "⚠️  远程同步失败，保持当前状态"
            fi
            ;;
        2)
            echo "🔧 重置到Git状态..."
            git checkout -- . 2>/dev/null || true
            echo "✅ 已重置文件"
            ;;
        3)
            echo "🔧 创建提交..."
            git add .
            git commit -m "Server status backup: $(date)" 2>/dev/null || true
            echo "✅ 已创建提交"
            ;;
        *)
            echo "⚠️  保持当前状态不变"
            ;;
    esac
else
    echo "✅ 文件状态正常"
fi

# 5. 测试基本功能
echo ""
echo "🧪 测试基本功能..."

# 测试Git基本命令
if git status >/dev/null 2>&1; then
    echo "✅ Git状态检查正常"
else
    echo "❌ Git状态检查失败"
fi

# 测试Python
if command -v python3 >/dev/null 2>&1; then
    echo "✅ Python3可用"
else
    echo "⚠️  Python3不可用"
fi

# 检查端口占用
if netstat -tlpn 2>/dev/null | grep -q ":8080 "; then
    echo "⚠️  端口8080被占用"
    echo "运行中的进程:"
    netstat -tlpn 2>/dev/null | grep ":8080 "
else
    echo "✅ 端口8080可用"
fi

# 6. 提供后续操作指南
echo ""
echo "🎯 后续操作建议:"
echo "=================="

if git ls-remote origin >/dev/null 2>&1; then
    echo "网络状况: ✅ 可以连接GitHub"
    echo ""
    echo "推荐操作流程:"
    echo "1. git pull origin main          # 拉取最新代码"
    echo "2. ./update-and-deploy.sh        # 执行部署"
    echo "3. 访问 http://47.92.236.28:8080 # 验证结果"
else
    echo "网络状况: ⚠️ 无法连接GitHub"
    echo ""
    echo "推荐操作流程:"
    echo "1. 等待本地TCP推送"
    echo "2. ./update-and-deploy.sh        # 选择TCP选项"
    echo "3. 访问 http://47.92.236.28:8080 # 验证结果"
    echo ""
    echo "启动TCP接收服务:"
    echo "python3 tcp-receiver.py"
fi

echo ""
echo "🔧 故障排查命令:"
echo "git status                        # 检查Git状态"
echo "ps aux | grep python3             # 检查运行进程"
echo "tail -f server.log                # 查看服务日志"
echo "netstat -tlpn | grep 8080         # 检查端口占用"

echo ""
echo "🎉 快速修复完成！"