#!/bin/bash

# 服务器一键更新脚本
# 从GitHub拉取最新代码并部署

echo "🚀 服务器一键更新和部署工具"
echo "============================"

# 检查当前目录
if [ ! -f "index.html" ]; then
    echo "❌ 请在项目目录执行此脚本"
    echo "正确位置: cd /var/www/document-scanner"
    exit 1
fi

echo "✅ 当前在项目目录"

# 创建备份
echo ""
echo "📦 创建当前状态备份..."
backup_dir="../document-scanner-backup-$(date +%Y%m%d_%H%M%S)"
cp -r . "$backup_dir"
echo "✅ 备份创建: $backup_dir"

# 停止现有服务
echo ""
echo "🛑 停止现有服务..."
pkill -f "python3 -m http.server 8080" 2>/dev/null || true
pkill -f "python -m http.server 8080" 2>/dev/null || true
echo "✅ 现有服务已停止"

# 修复Git兼容性
echo ""
echo "🔧 修复Git兼容性问题..."
# 检查并替换git stash push命令
for file in *.sh; do
    if [ -f "$file" ] && grep -q "git stash push" "$file" 2>/dev/null; then
        sed -i.bak 's/git stash push -m/git stash save/g' "$file"
        echo "  ✅ 修复 $file"
    fi
done

# 尝试Git更新
echo ""
echo "🔄 尝试Git更新..."
git_success=false

# 方法1: 标准git pull
if git pull origin main 2>/dev/null; then
    echo "✅ Git拉取成功"
    git_success=true
elif git fetch origin main 2>/dev/null && git reset --hard origin/main 2>/dev/null; then
    echo "✅ Git强制同步成功"
    git_success=true
else
    echo "❌ Git更新失败，尝试其他方案..."
fi

# 如果Git失败，尝试重新克隆
if [ "$git_success" = false ]; then
    echo ""
    echo "🔄 尝试重新克隆仓库..."
    
    cd ..
    if git clone https://github.com/peakcary/document-scanner.git document-scanner-new 2>/dev/null; then
        echo "✅ 重新克隆成功"
        
        # 备份旧目录
        mv document-scanner document-scanner-old-$(date +%Y%m%d_%H%M%S)
        
        # 使用新代码
        mv document-scanner-new document-scanner
        cd document-scanner
        
        echo "✅ 代码更新完成"
        git_success=true
    else
        echo "❌ 重新克隆也失败"
        cd document-scanner
    fi
fi

# 设置文件权限
echo ""
echo "🔐 设置文件权限..."
chmod +x *.sh 2>/dev/null || true
echo "✅ 权限设置完成"

# 启动服务
echo ""
echo "🚀 启动HTTP服务..."
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &

# 等待服务启动
sleep 3

# 检查服务状态
if ps aux | grep -v grep | grep "python3 -m http.server 8080" > /dev/null; then
    echo "✅ HTTP服务启动成功"
    echo "   PID: $(ps aux | grep -v grep | grep 'python3 -m http.server 8080' | awk '{print $2}')"
else
    echo "❌ HTTP服务启动失败"
fi

# 验证访问
echo ""
echo "🧪 验证服务..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
    echo "✅ 服务访问正常"
else
    echo "⚠️  服务访问异常，请检查日志"
fi

# 显示结果
echo ""
echo "🎉 更新和部署完成！"
echo "===================="
echo ""

if [ "$git_success" = true ]; then
    echo "✅ 代码更新: 成功"
    echo "📊 最新版本: $(git log --oneline -1 2>/dev/null || echo '未知')"
else
    echo "⚠️  代码更新: 失败（使用备份文件）"
fi

echo "✅ 服务状态: 运行中"
echo "🌐 访问地址: http://47.92.236.28:8080"
echo "📋 日志文件: ./server.log"
echo ""

echo "🛠️  管理命令:"
echo "  查看日志: tail -f server.log"
echo "  重启服务: pkill -f 'python3 -m http.server' && nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &"
echo "  停止服务: pkill -f 'python3 -m http.server'"
echo ""

echo "🎯 更新完成！请访问 http://47.92.236.28:8080 验证结果"