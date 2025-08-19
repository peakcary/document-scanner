#!/bin/bash

# 服务器环境完整修复脚本
# 解决目录不存在、权限问题等

echo "🔧 服务器环境完整修复脚本"
echo "=========================="

# 定义项目路径
PROJECT_DIR="/var/www/document-scanner"
BACKUP_BASE="/var/www"

echo "目标项目目录: $PROJECT_DIR"
echo "当前用户: $(whoami)"
echo "当前位置: $(pwd)"

# 第1步：检查和创建基础目录
echo ""
echo "📁 第1步：检查基础目录结构..."

if [ ! -d "/var/www" ]; then
    echo "创建 /var/www 目录..."
    mkdir -p /var/www
    echo "✅ /var/www 目录已创建"
else
    echo "✅ /var/www 目录已存在"
fi

# 第2步：处理项目目录
echo ""
echo "📂 第2步：处理项目目录..."

if [ -d "$PROJECT_DIR" ]; then
    echo "✅ 项目目录已存在: $PROJECT_DIR"
    
    # 检查目录内容
    FILES_COUNT=$(ls -1 "$PROJECT_DIR" 2>/dev/null | wc -l)
    echo "目录中文件数量: $FILES_COUNT"
    
    if [ "$FILES_COUNT" -eq 0 ]; then
        echo "⚠️  目录为空"
    elif [ ! -f "$PROJECT_DIR/index.html" ]; then
        echo "⚠️  缺少主要文件"
    else
        echo "✅ 目录内容正常"
    fi
else
    echo "⚠️  项目目录不存在，正在创建..."
    mkdir -p "$PROJECT_DIR"
    echo "✅ 项目目录已创建: $PROJECT_DIR"
fi

# 第3步：进入项目目录
echo ""
echo "📍 第3步：进入项目目录..."
cd "$PROJECT_DIR" || {
    echo "❌ 无法进入项目目录"
    exit 1
}
echo "✅ 成功进入: $(pwd)"

# 第4步：初始化Git仓库
echo ""
echo "🔄 第4步：检查Git仓库..."

if [ ! -d ".git" ]; then
    echo "初始化Git仓库..."
    git init
    git remote add origin https://github.com/peakcary/document-scanner.git 2>/dev/null || true
    echo "✅ Git仓库已初始化"
else
    echo "✅ Git仓库已存在"
    
    # 检查远程仓库
    if ! git remote get-url origin >/dev/null 2>&1; then
        echo "添加远程仓库..."
        git remote add origin https://github.com/peakcary/document-scanner.git 2>/dev/null || true
    fi
fi

# 第5步：查找和恢复备份
echo ""
echo "🔍 第5步：查找可用备份..."

# 查找备份目录
BACKUP_DIRS=$(find /var -name "*document-scanner*backup*" -o -name "*backup*document-scanner*" 2>/dev/null | head -5)

if [ -n "$BACKUP_DIRS" ]; then
    echo "找到以下备份目录:"
    echo "$BACKUP_DIRS"
    
    # 如果当前目录为空且有备份，询问是否恢复
    if [ "$(ls -A . 2>/dev/null | wc -l)" -eq 0 ] || [ ! -f "index.html" ]; then
        echo ""
        echo "当前目录缺少文件，尝试从最新备份恢复..."
        
        LATEST_BACKUP=$(echo "$BACKUP_DIRS" | sort | tail -1)
        if [ -d "$LATEST_BACKUP" ] && [ -f "$LATEST_BACKUP/index.html" ]; then
            echo "从备份恢复: $LATEST_BACKUP"
            cp -r "$LATEST_BACKUP"/* . 2>/dev/null || true
            cp -r "$LATEST_BACKUP"/.[^.]* . 2>/dev/null || true
            echo "✅ 备份恢复完成"
        fi
    fi
else
    echo "❌ 未找到备份目录"
fi

# 第6步：检查部署包
echo ""
echo "📦 第6步：检查可用部署包..."

DEPLOY_PACKAGES=$(ls /tmp/deploy-*.tar.gz 2>/dev/null)
PACKAGE_COUNT=$(echo "$DEPLOY_PACKAGES" | grep -c "deploy-" 2>/dev/null || echo "0")

echo "可用部署包数量: $PACKAGE_COUNT"

if [ "$PACKAGE_COUNT" -gt 0 ]; then
    echo "找到部署包:"
    ls -la /tmp/deploy-*.tar.gz
    
    # 如果当前目录缺少文件，询问是否使用部署包
    if [ ! -f "index.html" ]; then
        echo ""
        echo "当前目录缺少主文件，尝试使用最新部署包..."
        
        LATEST_PACKAGE=$(ls -t /tmp/deploy-*.tar.gz 2>/dev/null | head -1)
        if [ -f "$LATEST_PACKAGE" ]; then
            echo "解压部署包: $LATEST_PACKAGE"
            tar -xzf "$LATEST_PACKAGE"
            echo "✅ 部署包解压完成"
        fi
    fi
else
    echo "❌ 未找到部署包"
fi

# 第7步：尝试从GitHub获取代码
echo ""
echo "🌐 第7步：尝试从GitHub获取代码..."

if [ ! -f "index.html" ]; then
    echo "本地文件缺失，尝试从GitHub克隆..."
    
    # 临时克隆到其他位置
    TEMP_DIR="/tmp/document-scanner-temp"
    if git clone https://github.com/peakcary/document-scanner.git "$TEMP_DIR" 2>/dev/null; then
        echo "✅ GitHub克隆成功"
        
        # 复制文件到项目目录
        cp -r "$TEMP_DIR"/* . 2>/dev/null || true
        cp -r "$TEMP_DIR"/.[^.]* . 2>/dev/null || true
        
        # 清理临时目录
        rm -rf "$TEMP_DIR"
        echo "✅ 文件已复制到项目目录"
    else
        echo "❌ GitHub克隆失败"
    fi
fi

# 第8步：设置权限
echo ""
echo "🔐 第8步：设置文件权限..."

chmod +x *.sh 2>/dev/null || true
chmod 644 *.html *.css *.js *.md 2>/dev/null || true

# 修复Git兼容性
for file in *.sh; do
    if [ -f "$file" ] && grep -q "git stash push" "$file" 2>/dev/null; then
        sed -i 's/git stash push -m/git stash save/g' "$file"
        echo "修复Git兼容性: $file"
    fi
done

echo "✅ 权限设置完成"

# 第9步：检查服务状态
echo ""
echo "🔍 第9步：检查HTTP服务状态..."

if ps aux | grep -v grep | grep "python.*http.server.*8080" >/dev/null; then
    echo "✅ HTTP服务正在运行"
    PID=$(ps aux | grep -v grep | grep "python.*http.server.*8080" | awk '{print $2}')
    echo "服务PID: $PID"
else
    echo "❌ HTTP服务未运行"
    
    # 检查端口占用
    if netstat -tlpn 2>/dev/null | grep ":8080 " >/dev/null; then
        echo "⚠️  端口8080被占用"
        netstat -tlpn | grep ":8080 "
        echo "尝试释放端口..."
        lsof -ti:8080 | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
    
    # 启动HTTP服务
    if [ -f "index.html" ]; then
        echo "启动HTTP服务..."
        nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &
        sleep 3
        
        if ps aux | grep -v grep | grep "python.*http.server.*8080" >/dev/null; then
            echo "✅ HTTP服务启动成功"
        else
            echo "❌ HTTP服务启动失败"
            echo "查看日志:"
            tail -5 server.log 2>/dev/null || echo "无日志文件"
        fi
    else
        echo "⚠️  缺少index.html文件，无法启动服务"
    fi
fi

# 第10步：验证网站访问
echo ""
echo "🧪 第10步：验证网站访问..."

if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null | grep -q "200"; then
    echo "✅ 网站访问正常"
else
    echo "❌ 网站访问失败"
fi

# 显示最终状态
echo ""
echo "================================="
echo "🎯 环境修复完成 - 状态总结"
echo "================================="
echo ""

echo "📁 目录信息:"
echo "  项目路径: $PROJECT_DIR"
echo "  当前路径: $(pwd)"
echo "  文件数量: $(ls -1 2>/dev/null | wc -l)"

echo ""
echo "📋 关键文件:"
echo "  index.html: $([ -f "index.html" ] && echo "✅ 存在" || echo "❌ 缺失")"
echo "  server-deploy.sh: $([ -f "server-deploy.sh" ] && echo "✅ 存在" || echo "❌ 缺失")"
echo "  CSS文件: $(ls css/*.css 2>/dev/null | wc -l) 个"
echo "  JS文件: $(ls js/*.js 2>/dev/null | wc -l) 个"

echo ""
echo "🔧 服务状态:"
if ps aux | grep -v grep | grep "python.*http.server.*8080" >/dev/null; then
    PID=$(ps aux | grep -v grep | grep "python.*http.server.*8080" | awk '{print $2}')
    echo "  HTTP服务: ✅ 运行中 (PID: $PID)"
else
    echo "  HTTP服务: ❌ 未运行"
fi

echo "  端口8080: $(netstat -tlpn 2>/dev/null | grep ":8080 " >/dev/null && echo "⚠️ 被占用" || echo "✅ 可用")"

echo ""
echo "🌐 访问测试:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null || echo "000")
echo "  本地访问: $([ "$HTTP_CODE" = "200" ] && echo "✅ 正常 (HTTP $HTTP_CODE)" || echo "❌ 失败 (HTTP $HTTP_CODE)")"

echo ""
echo "🎯 建议的下一步操作:"

if [ ! -f "index.html" ]; then
    echo "1. ❌ 项目文件缺失 - 需要部署新代码"
    echo "   解决方案:"
    echo "   - 从本地运行: ./dev-deploy.sh"
    echo "   - 或手动上传: scp deploy-*.tar.gz root@47.92.236.28:/tmp/"
    echo "   - 然后运行: ./server-deploy.sh"
elif ! ps aux | grep -v grep | grep "python.*http.server.*8080" >/dev/null; then
    echo "1. ⚠️  文件存在但服务未运行"
    echo "   启动命令: nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &"
else
    echo "1. ✅ 环境正常 - 可以正常使用"
    echo "   访问地址: http://47.92.236.28:8080"
fi

echo ""
echo "📞 常用管理命令:"
echo "  进入项目: cd $PROJECT_DIR"
echo "  查看文件: ls -la"
echo "  查看服务: ps aux | grep python"
echo "  查看日志: tail -f server.log"
echo "  重启服务: pkill -f python3 && nohup python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &"

echo ""
echo "✅ 服务器环境修复脚本执行完成！"