#!/bin/bash

# GitHub连接超时快速修复脚本
# 专门解决: Failed connect to github.com:443; Connection timed out

echo "🔧 GitHub连接超时修复工具"
echo "========================="
echo "错误: Failed connect to github.com:443; Connection timed out"
echo ""

# 1. 诊断网络连接
echo "1️⃣ 诊断网络连接..."
echo "🔍 测试基本网络连接:"
if ping -c 2 -W 5 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ 基本网络连接正常"
else
    echo "❌ 基本网络连接失败"
    echo "🔧 建议: 检查网络配置或联系网络管理员"
    exit 1
fi

echo ""
echo "🔍 测试GitHub域名解析:"
if nslookup github.com > /dev/null 2>&1; then
    echo "✅ GitHub域名解析正常"
    github_ip=$(nslookup github.com | grep "Address" | tail -1 | awk '{print $2}')
    echo "   GitHub IP: $github_ip"
else
    echo "❌ GitHub域名解析失败"
    echo "🔧 修复DNS配置..."
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    echo "nameserver 114.114.114.114" >> /etc/resolv.conf
    echo "✅ DNS配置已更新"
fi

echo ""
echo "🔍 测试GitHub端口连接:"
timeout 10 bash -c 'cat < /dev/null > /dev/tcp/github.com/443' 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ GitHub 443端口连接正常"
else
    echo "❌ GitHub 443端口连接失败"
    echo "🔧 这是主要问题所在！"
fi

echo ""
echo "2️⃣ 应用网络修复..."

# 2. 配置Git网络优化
echo "🔧 优化Git网络配置..."
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 300
git config --global http.postBuffer 1048576000
git config --global core.compression 0
echo "✅ Git网络配置已优化"

# 3. 尝试使用镜像源
echo ""
echo "🔧 尝试GitHub镜像源..."
original_url=$(git remote get-url origin)
echo "原始URL: $original_url"

# 检查是否已经是镜像URL
if echo "$original_url" | grep -q "github.com.cnpmjs.org"; then
    echo "✅ 已使用镜像源"
elif echo "$original_url" | grep -q "gitee.com"; then
    echo "✅ 已使用Gitee镜像"
else
    echo "🔄 切换到GitHub镜像源..."
    mirror_url=$(echo "$original_url" | sed 's/github.com/github.com.cnpmjs.org/')
    git remote set-url origin "$mirror_url"
    echo "✅ 已切换到镜像源: $mirror_url"
fi

echo ""
echo "3️⃣ 测试修复结果..."

# 4. 测试Git连接
echo "🧪 测试Git连接..."
timeout 30 git ls-remote origin > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Git连接测试成功！"
    echo ""
    echo "🚀 尝试拉取最新代码..."
    if git pull origin main; then
        echo "🎉 Git拉取成功！问题已解决"
        exit 0
    else
        echo "⚠️  拉取仍有问题，继续其他方案..."
    fi
else
    echo "❌ Git连接仍然失败"
fi

echo ""
echo "4️⃣ 备用解决方案..."

# 5. 恢复原始URL并提供备用方案
echo "🔄 恢复原始GitHub URL..."
git remote set-url origin "$original_url"

echo ""
echo "🚀 推荐使用TCP推送方案:"
echo "=========================================="
echo ""
echo "📋 TCP推送步骤:"
echo "1. 保持当前SSH连接打开"
echo "2. 开启新的SSH连接到服务器:"
echo "   ssh root@47.92.236.28"
echo ""
echo "3. 在新连接中启动TCP接收服务:"
echo "   cd /var/www/document-scanner"
echo "   python3 tcp-receiver.py"
echo ""
echo "4. 在本地执行TCP推送:"
echo "   cd /Users/peakom/document-scanner"
echo "   python3 tcp-push.py"
echo ""
echo "5. TCP推送完成后，在服务器执行:"
echo "   ./update-and-deploy.sh"
echo "   选择 '使用TCP推送的文件'"
echo ""
echo "=========================================="

echo ""
echo "🔧 其他尝试方案:"
echo "1. 使用VPN或代理"
echo "2. 联系服务商解除GitHub访问限制"
echo "3. 使用Gitee等国内Git平台镜像"
echo "4. 手动文件传输: scp方式上传"

echo ""
echo "💡 TCP推送是最可靠的解决方案！"