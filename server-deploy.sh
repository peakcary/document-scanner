#!/bin/bash

# 服务器端自动部署脚本
# 处理从本地上传的部署包

set -e

echo "🔄 服务器端自动部署脚本"
echo "========================="

# 检查是否在项目目录
if [ ! -d ".git" ] && [ ! -f "index.html" ]; then
    echo "❌ 请在项目目录执行此脚本"
    echo "正确位置: cd /var/www/document-scanner"
    exit 1
fi

echo "✅ 当前在项目目录: $(pwd)"

# 停止现有服务
echo ""
echo "🛑 停止现有服务..."
pkill -f "python3 -m http.server" 2>/dev/null || true
pkill -f "python -m http.server" 2>/dev/null || true
sleep 2
echo "✅ 现有服务已停止"

# 创建备份
echo ""
echo "💾 创建当前状态备份..."
BACKUP_DIR="../backup-$(date +%Y%m%d_%H%M%S)"
cp -r . "$BACKUP_DIR"
echo "✅ 备份创建: $BACKUP_DIR"

# 查找最新的部署包
echo ""
echo "📦 查找部署包..."
DEPLOY_PACKAGE=$(ls -t /tmp/deploy-*.tar.gz 2>/dev/null | head -1)

if [ -z "$DEPLOY_PACKAGE" ]; then
    echo "❌ 未找到部署包"
    echo "请确保已从本地上传部署包到 /tmp/"
    exit 1
fi

echo "✅ 找到部署包: $DEPLOY_PACKAGE"

# 清空当前目录（保留.git）
echo ""
echo "🧹 清空当前目录..."
find . -maxdepth 1 -not -name '.' -not -name '.git' -exec rm -rf {} \;
echo "✅ 目录清空完成"

# 解压部署包
echo ""
echo "📦 解压部署包..."
tar -xzf "$DEPLOY_PACKAGE"
echo "✅ 代码解压完成"

# 设置文件权限
echo ""
echo "🔐 设置文件权限..."
chmod +x *.sh 2>/dev/null || true
chmod 644 *.html *.css *.js *.md 2>/dev/null || true
echo "✅ 权限设置完成"

# 修复Git兼容性
echo ""
echo "🔧 修复Git兼容性..."
for file in *.sh; do
    if [ -f "$file" ] && grep -q "git stash push" "$file" 2>/dev/null; then
        sed -i 's/git stash push -m/git stash save/g' "$file"
        echo "  修复: $file"
    fi
done
echo "✅ Git兼容性修复完成"

# 同步Git状态
echo ""
echo "🔄 同步Git状态..."
if git status >/dev/null 2>&1; then
    git add . 2>/dev/null || true
    git commit -m "Deploy update: $(date)" 2>/dev/null || true
    echo "✅ Git状态已同步"
else
    echo "⚠️  Git状态同步跳过"
fi

# 启动HTTP服务
echo ""
echo "🚀 启动HTTP服务..."
nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &

# 等待服务启动
sleep 3

# 验证服务状态
echo ""
echo "🧪 验证服务状态..."

if ps aux | grep -v grep | grep "python3 -m http.server 8080" > /dev/null; then
    PID=$(ps aux | grep -v grep | grep "python3 -m http.server 8080" | awk '{print $2}')
    echo "✅ HTTP服务启动成功 (PID: $PID)"
else
    echo "❌ HTTP服务启动失败"
    echo "错误日志:"
    tail -5 server.log 2>/dev/null || echo "无日志文件"
    exit 1
fi

# 测试网站访问
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
    echo "✅ 网站访问测试通过"
else
    echo "⚠️  网站访问测试失败"
fi

# 显示部署文件信息
echo ""
echo "📁 部署文件信息:"
echo "HTML文件: $(ls *.html 2>/dev/null | wc -l) 个"
echo "脚本文件: $(ls *.sh 2>/dev/null | wc -l) 个"
echo "CSS文件: $(ls css/*.css 2>/dev/null | wc -l) 个"
echo "JS文件: $(ls js/*.js 2>/dev/null | wc -l) 个"

# 显示结果
echo ""
echo "================================="
echo "🎉 服务器部署完成！"
echo "================================="
echo ""
echo "✅ 部署信息:"
echo "  部署包: $DEPLOY_PACKAGE"
echo "  备份位置: $BACKUP_DIR"
echo "  服务PID: $(ps aux | grep -v grep | grep 'python3 -m http.server 8080' | awk '{print $2}')"
echo "  日志文件: ./server.log"
echo ""
echo "🌐 访问地址:"
echo "  本地测试: http://localhost:8080"
echo "  公网访问: http://47.92.236.28:8080"
echo ""
echo "🛠️  管理命令:"
echo "  查看日志: tail -f server.log"
echo "  检查进程: ps aux | grep python3"
echo "  重启服务: pkill -f python3 && nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &"
echo "  恢复备份: rm -rf ./* && cp -r $BACKUP_DIR/* ."
echo ""

# 清理旧的部署包（保留最近3个）
echo "🧹 清理旧部署包..."
cd /tmp
ls -t deploy-*.tar.gz 2>/dev/null | tail -n +4 | xargs rm -f 2>/dev/null || true
echo "✅ 清理完成"

echo ""
echo "🎯 部署完成！请访问 http://47.92.236.28:8080 验证结果"