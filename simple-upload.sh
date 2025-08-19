#!/bin/bash

# 简化版上传脚本
SERVER_IP="47.92.236.28"
SERVER_USER="root"
PROJECT_NAME="document-scanner"

echo "=================================="
echo "  文档扫描器 - 简单上传脚本"
echo "  目标服务器: $SERVER_IP"
echo "=================================="

# 打包项目
echo "正在打包项目文件..."
tar -czf ${PROJECT_NAME}.tar.gz $PROJECT_NAME/
echo "✓ 打包完成"

# 上传文件
echo "正在上传文件到服务器..."
echo "请输入服务器密码:"
scp ${PROJECT_NAME}.tar.gz ${SERVER_USER}@${SERVER_IP}:/tmp/

if [ $? -eq 0 ]; then
    echo "✓ 文件上传成功！"
    echo ""
    echo "现在请手动连接服务器完成部署:"
    echo "ssh ${SERVER_USER}@${SERVER_IP}"
    echo ""
    echo "连接后执行以下命令:"
    echo "cd /tmp"
    echo "tar -xzf ${PROJECT_NAME}.tar.gz"
    echo "cd ${PROJECT_NAME}"
    echo "chmod +x deploy.sh"
    echo "./deploy.sh"
    echo ""
else
    echo "✗ 文件上传失败"
fi

# 清理本地文件
rm -f ${PROJECT_NAME}.tar.gz
echo "✓ 清理完成"