#!/bin/bash

# 强制更新服务器到最新版本脚本
# 确保服务器文件与GitHub完全同步

echo "🚀 强制更新服务器到最新版本"
echo "=========================="

# 检查当前目录
if [ ! -f "index.html" ]; then
    echo "❌ 请在项目目录执行此脚本"
    echo "正确位置: cd /var/www/document-scanner"
    exit 1
fi

echo "✅ 当前在项目目录: $(pwd)"

# 显示当前状态
echo ""
echo "📊 当前服务器状态:"
echo "Git提交: $(git log --oneline -1 2>/dev/null || echo '无法获取')"
echo "分支: $(git branch --show-current 2>/dev/null || echo '无法获取')"
echo "文件数量: $(ls -1 | wc -l)"

# 创建完整备份
echo ""
echo "💾 创建完整备份..."
backup_dir="/var/backups/document-scanner-$(date +%Y%m%d_%H%M%S)"
mkdir -p /var/backups
cp -r . "$backup_dir"
echo "✅ 完整备份创建: $backup_dir"

# 停止所有相关服务
echo ""
echo "🛑 停止所有相关服务..."
pkill -f "python3 -m http.server" 2>/dev/null || true
pkill -f "python -m http.server" 2>/dev/null || true
pkill -f "tcp-receiver.py" 2>/dev/null || true
sleep 2
echo "✅ 服务已停止"

# 方案1: Git强制更新
echo ""
echo "🔄 方案1: Git强制更新..."

# 重置Git状态
git reset --hard HEAD 2>/dev/null || true
git clean -fd 2>/dev/null || true

# 尝试拉取最新代码
if git fetch origin main 2>/dev/null && git reset --hard origin/main 2>/dev/null; then
    echo "✅ Git强制更新成功"
    git_success=true
    echo "📊 更新后版本: $(git log --oneline -1)"
else
    echo "❌ Git更新失败，尝试方案2"
    git_success=false
fi

# 方案2: 重新克隆
if [ "$git_success" = false ]; then
    echo ""
    echo "🔄 方案2: 重新克隆最新代码..."
    
    # 保存当前目录
    current_dir=$(pwd)
    parent_dir=$(dirname "$current_dir")
    project_name=$(basename "$current_dir")
    
    cd "$parent_dir"
    
    # 重命名旧目录
    mv "$project_name" "${project_name}-old-$(date +%Y%m%d_%H%M%S)"
    
    # 克隆最新代码
    if git clone https://github.com/peakcary/document-scanner.git "$project_name"; then
        echo "✅ 重新克隆成功"
        cd "$project_name"
        echo "📊 克隆版本: $(git log --oneline -1)"
        git_success=true
    else
        echo "❌ 重新克隆失败，恢复备份"
        mv "${project_name}-old-$(date +%Y%m%d_%H%M%S)" "$project_name"
        cd "$project_name"
        git_success=false
    fi
fi

# 方案3: 手动下载最新文件
if [ "$git_success" = false ]; then
    echo ""
    echo "🔄 方案3: 手动下载关键文件..."
    
    # 下载最新的关键文件
    files_to_update=(
        "index.html"
        "update-and-deploy.sh"
        "server-update-script.sh"
        "fix-git-compatibility.sh"
        "server-quick-fix.sh"
    )
    
    updated_count=0
    for file in "${files_to_update[@]}"; do
        if curl -s -o "$file.new" "https://raw.githubusercontent.com/peakcary/document-scanner/main/$file"; then
            if [ -s "$file.new" ]; then
                mv "$file.new" "$file"
                echo "  ✅ 更新 $file"
                ((updated_count++))
            else
                rm -f "$file.new"
                echo "  ❌ $file 下载为空"
            fi
        else
            rm -f "$file.new"
            echo "  ❌ 无法下载 $file"
        fi
    done
    
    if [ $updated_count -gt 0 ]; then
        echo "✅ 手动更新成功，共更新 $updated_count 个文件"
        git_success=true
    fi
fi

# 设置文件权限
echo ""
echo "🔐 设置文件权限..."
chmod +x *.sh 2>/dev/null || true
chmod 644 *.html *.md *.css *.js 2>/dev/null || true
echo "✅ 权限设置完成"

# 修复Git兼容性问题
echo ""
echo "🔧 修复Git兼容性..."
for file in *.sh; do
    if [ -f "$file" ] && grep -q "git stash push" "$file" 2>/dev/null; then
        sed -i.bak 's/git stash push -m/git stash save/g' "$file"
        echo "  ✅ 修复 $file"
    fi
done

# 启动HTTP服务
echo ""
echo "🚀 启动HTTP服务..."
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &

# 等待服务启动
sleep 3

# 验证服务
service_pid=$(ps aux | grep -v grep | grep "python3 -m http.server 8080" | awk '{print $2}')
if [ -n "$service_pid" ]; then
    echo "✅ HTTP服务启动成功 (PID: $service_pid)"
else
    echo "❌ HTTP服务启动失败"
    echo "📋 错误日志:"
    tail -n 5 server.log 2>/dev/null || echo "无日志文件"
fi

# 测试网站访问
echo ""
echo "🧪 测试网站访问..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
    echo "✅ 网站访问正常"
else
    echo "⚠️  网站访问可能有问题"
fi

# 显示最终状态
echo ""
echo "🎉 强制更新完成！"
echo "=================="

if [ "$git_success" = true ]; then
    echo "✅ 更新状态: 成功"
    if git log --oneline -1 >/dev/null 2>&1; then
        echo "📊 当前版本: $(git log --oneline -1)"
    fi
else
    echo "⚠️  更新状态: 部分成功"
fi

echo "🌐 访问地址: http://47.92.236.28:8080"
echo "📋 日志位置: ./server.log"
echo "💾 备份位置: $backup_dir"

# 显示最新文件列表
echo ""
echo "📁 当前文件列表:"
ls -la *.html *.sh *.md 2>/dev/null | head -10

echo ""
echo "🛠️  管理命令:"
echo "查看日志: tail -f server.log"
echo "重启服务: pkill -f python3 && nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &"
echo "检查进程: ps aux | grep python3"

echo ""
echo "🎯 请访问 http://47.92.236.28:8080 验证更新结果！"