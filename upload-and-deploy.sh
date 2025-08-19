#!/bin/bash

# 一键上传并部署到阿里云服务器脚本
# 使用方法: ./upload-and-deploy.sh

SERVER_IP="47.92.236.28"
SERVER_USER="root"
PROJECT_NAME="document-scanner"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[步骤]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

echo "=================================="
echo "  文档扫描器 - 一键部署脚本"
echo "  目标服务器: $SERVER_IP"
echo "=================================="
echo

# 检查本地文件
print_step "检查本地项目文件..."
if [ ! -d "$PROJECT_NAME" ]; then
    print_error "未找到项目目录: $PROJECT_NAME"
    exit 1
fi

print_success "项目目录存在"

# 打包项目
print_step "打包项目文件..."
tar -czf ${PROJECT_NAME}.tar.gz $PROJECT_NAME/
if [ $? -eq 0 ]; then
    print_success "项目打包完成"
    ls -lh ${PROJECT_NAME}.tar.gz
else
    print_error "项目打包失败"
    exit 1
fi

# 测试服务器连接
print_step "测试服务器连接..."
ping -c 1 $SERVER_IP > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_success "服务器连接正常"
else
    print_warning "服务器ping测试失败，但可能仍然可以连接"
fi

# 上传文件
print_step "上传文件到服务器..."
echo "正在上传 ${PROJECT_NAME}.tar.gz 到 ${SERVER_USER}@${SERVER_IP}:/tmp/"
echo "请输入服务器密码:"

scp ${PROJECT_NAME}.tar.gz ${SERVER_USER}@${SERVER_IP}:/tmp/
if [ $? -eq 0 ]; then
    print_success "文件上传成功"
else
    print_error "文件上传失败"
    exit 1
fi

# 连接服务器并部署
print_step "连接服务器执行部署..."
echo "即将连接服务器执行部署脚本"
echo "请再次输入服务器密码:"

ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
# 服务器端执行的命令
echo "已连接到服务器，开始部署..."

# 解压文件
cd /tmp
if [ -f "document-scanner.tar.gz" ]; then
    echo "解压项目文件..."
    tar -xzf document-scanner.tar.gz
    if [ $? -eq 0 ]; then
        echo "✓ 解压成功"
    else
        echo "✗ 解压失败"
        exit 1
    fi
else
    echo "✗ 未找到上传的文件"
    exit 1
fi

# 进入项目目录
cd document-scanner
if [ ! -f "deploy.sh" ]; then
    echo "✗ 未找到部署脚本"
    exit 1
fi

# 给部署脚本执行权限
chmod +x deploy.sh
echo "✓ 部署脚本权限设置完成"

echo ""
echo "========================================"
echo "  准备执行自动部署脚本"
echo "  接下来需要您输入："
echo "  1. 您的域名 (如: scanner.yourdomain.com)"
echo "  2. 您的邮箱 (用于SSL证书申请)"
echo "========================================"
echo ""

# 执行部署脚本
./deploy.sh

ENDSSH

if [ $? -eq 0 ]; then
    print_success "部署完成！"
    echo ""
    echo "=================================="
    echo "🎉 部署成功！"
    echo "=================================="
    echo "请访问您配置的域名查看应用"
    echo "如果遇到问题，请联系技术支持"
else
    print_error "部署过程中遇到错误"
    echo "请检查服务器日志或联系技术支持"
fi

# 清理本地文件
print_step "清理临时文件..."
rm -f ${PROJECT_NAME}.tar.gz
print_success "清理完成"

echo ""
echo "脚本执行完毕"