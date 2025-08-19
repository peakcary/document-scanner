#!/bin/bash

# 简单的本地HTTP服务器启动脚本

echo "=================================="
echo "  文档扫描器 - 本地测试服务器"
echo "=================================="

# 检查Python版本
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "❌ 未找到Python，请先安装Python"
    exit 1
fi

echo "✅ 使用 $PYTHON_CMD 启动服务器"
echo "🌐 访问地址: http://localhost:8000"
echo "⌨️  按 Ctrl+C 停止服务器"
echo ""

# 启动HTTP服务器
$PYTHON_CMD -m http.server 8000