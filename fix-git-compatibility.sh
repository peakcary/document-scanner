#!/bin/bash

# Git版本兼容性修复脚本
# 解决不同Git版本命令差异问题

echo "🔧 Git版本兼容性修复工具"
echo "========================"

# 检查Git版本
git_version=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
echo "当前Git版本: $git_version"

# 检查主要版本号
major_version=$(echo "$git_version" | cut -d. -f1)
minor_version=$(echo "$git_version" | cut -d. -f2)

echo "主版本: $major_version, 次版本: $minor_version"

if [ "$major_version" -lt 2 ] || ([ "$major_version" -eq 2 ] && [ "$minor_version" -lt 13 ]); then
    echo "❌ Git版本较旧 (< 2.13)，不支持 'git stash push'"
    echo "🔧 将使用兼容命令 'git stash save'"
    USE_OLD_STASH=true
else
    echo "✅ Git版本较新，支持现代命令"
    USE_OLD_STASH=false
fi

echo ""
echo "🔧 修复脚本中的Git命令..."

# 修复 update-and-deploy.sh
if [ -f "update-and-deploy.sh" ]; then
    echo "修复 update-and-deploy.sh..."
    
    # 备份原文件
    cp update-and-deploy.sh update-and-deploy.sh.backup
    
    # 替换 git stash push 为兼容命令
    if [ "$USE_OLD_STASH" = true ]; then
        sed -i.tmp 's/git stash push -m "\([^"]*\)"/git stash save "\1"/g' update-and-deploy.sh
        echo "  ✅ 已替换为 git stash save"
    fi
    
    rm -f update-and-deploy.sh.tmp
    echo "  ✅ update-and-deploy.sh 已修复"
else
    echo "  ⚠️  未找到 update-and-deploy.sh"
fi

# 修复 sync-git-after-tcp.sh  
if [ -f "sync-git-after-tcp.sh" ]; then
    echo "修复 sync-git-after-tcp.sh..."
    
    cp sync-git-after-tcp.sh sync-git-after-tcp.sh.backup
    
    if [ "$USE_OLD_STASH" = true ]; then
        sed -i.tmp 's/git stash push -m "\([^"]*\)"/git stash save "\1"/g' sync-git-after-tcp.sh
    fi
    
    rm -f sync-git-after-tcp.sh.tmp
    echo "  ✅ sync-git-after-tcp.sh 已修复"
else
    echo "  ⚠️  未找到 sync-git-after-tcp.sh"
fi

# 检查其他可能的文件
for file in *.sh; do
    if [ "$file" != "fix-git-compatibility.sh" ] && grep -q "git stash push" "$file" 2>/dev/null; then
        echo "发现 $file 中有 git stash push 命令"
        cp "$file" "$file.backup"
        
        if [ "$USE_OLD_STASH" = true ]; then
            sed -i.tmp 's/git stash push -m "\([^"]*\)"/git stash save "\1"/g' "$file"
        fi
        
        rm -f "$file.tmp"
        echo "  ✅ $file 已修复"
    fi
done

echo ""
echo "🧪 测试修复结果..."

# 测试兼容的stash命令
if [ "$USE_OLD_STASH" = true ]; then
    echo "测试 git stash save..."
    if git stash save "兼容性测试 $(date)" >/dev/null 2>&1; then
        echo "✅ git stash save 工作正常"
        # 恢复stash
        git stash pop >/dev/null 2>&1 || true
    else
        echo "❌ git stash save 仍有问题"
    fi
else
    echo "测试 git stash push..."
    if git stash push -m "兼容性测试 $(date)" >/dev/null 2>&1; then
        echo "✅ git stash push 工作正常"
        git stash pop >/dev/null 2>&1 || true
    else
        echo "❌ git stash push 有问题"
    fi
fi

echo ""
echo "📋 Git版本兼容性对照表:"
echo "Git 2.13+ : 支持 git stash push"
echo "Git 1.x-2.12 : 使用 git stash save"
echo "Git 1.5+ : 基本的 git stash"

echo ""
echo "🎉 修复完成！"

if [ "$USE_OLD_STASH" = true ]; then
    echo ""
    echo "⚠️  建议升级Git版本："
    echo "Ubuntu/Debian: apt update && apt install git"
    echo "CentOS/RHEL: yum update git"
    echo "或编译安装最新版本"
fi

echo ""
echo "💾 原始文件已备份为 *.backup"
echo "🔄 现在可以正常运行部署脚本了"