#!/bin/bash

# 部署到阿里云ECS的完整脚本

SERVER_IP="47.92.236.28"
SERVER_USER="root"
PROJECT_NAME="document-scanner"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[步骤]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

echo "=========================================="
echo "  文档扫描器 - ECS部署脚本"
echo "  从Mac本地部署到阿里云ECS"
echo "  服务器: $SERVER_IP"
echo "=========================================="
echo

# 检查本地环境
print_step "检查本地环境..."

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 如果当前目录有document-scanner，使用当前目录
if [ -d "$PROJECT_NAME" ]; then
    PROJECT_PATH="$PROJECT_NAME"
elif [ -d "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/index.html" ]; then
    # 如果脚本在项目目录内，使用脚本目录
    PROJECT_PATH="$SCRIPT_DIR"
    cd "$(dirname "$SCRIPT_DIR")"
else
    print_error "项目目录不存在: $PROJECT_NAME"
    print_error "当前目录: $(pwd)"
    print_error "请确保在包含document-scanner目录的位置执行此脚本"
    exit 1
fi

if [ ! -f "$PROJECT_PATH/index.html" ]; then
    print_error "项目文件不完整，未找到index.html"
    print_error "检查路径: $PROJECT_PATH/index.html"
    exit 1
fi

print_success "本地项目文件检查通过"
print_success "项目路径: $PROJECT_PATH"

# 停止本地服务器
print_step "停止本地开发服务器..."
pkill -f "python.*http.server.*8000" 2>/dev/null || true
print_success "本地服务器已停止"

# 打包项目
print_step "打包项目文件..."
tar --exclude='*.tar.gz' --exclude='.git' --exclude='node_modules' --exclude='.DS_Store' -czf ${PROJECT_NAME}.tar.gz $PROJECT_PATH/

if [ $? -eq 0 ]; then
    print_success "项目打包完成"
    ls -lh ${PROJECT_NAME}.tar.gz
else
    print_error "项目打包失败"
    exit 1
fi

# 测试服务器连接
print_step "测试服务器连接..."
if ping -c 1 $SERVER_IP > /dev/null 2>&1; then
    print_success "服务器连接正常"
else
    print_warning "服务器ping测试失败，但可能仍然可以连接"
fi

# 上传文件
print_step "上传文件到ECS服务器..."
echo "正在上传到 ${SERVER_USER}@${SERVER_IP}:/tmp/"
echo "请输入ECS服务器密码:"

scp ${PROJECT_NAME}.tar.gz ${SERVER_USER}@${SERVER_IP}:/tmp/

if [ $? -eq 0 ]; then
    print_success "文件上传成功"
else
    print_error "文件上传失败"
    print_error "请检查:"
    print_error "1. 服务器IP地址是否正确: $SERVER_IP"
    print_error "2. 用户名是否正确: $SERVER_USER"  
    print_error "3. 密码是否正确"
    print_error "4. 服务器SSH服务是否正常"
    exit 1
fi

# 连接服务器部署
print_step "连接ECS服务器进行部署..."
echo "即将连接服务器并自动部署应用"
echo "请再次输入ECS服务器密码:"

ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
#!/bin/bash

# 服务器端部署脚本
echo "=========================================="
echo "  ECS服务器端自动部署开始"
echo "=========================================="

# 检查系统类型
if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
    UPDATE_CMD="apt update && apt upgrade -y"
    INSTALL_CMD="apt install -y"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    UPDATE_CMD="yum update -y"
    INSTALL_CMD="yum install -y"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    UPDATE_CMD="dnf update -y"
    INSTALL_CMD="dnf install -y"
else
    echo "❌ 不支持的系统类型"
    exit 1
fi

echo "✅ 检测到包管理器: $PKG_MANAGER"

# 解压项目文件
echo "📦 解压项目文件..."
cd /tmp
if [ -f "document-scanner.tar.gz" ]; then
    tar -xzf document-scanner.tar.gz
    echo "✅ 文件解压成功"
else
    echo "❌ 未找到上传的项目文件"
    exit 1
fi

# 进入项目目录
cd document-scanner

# 检查部署脚本
if [ -f "deploy-universal.sh" ]; then
    chmod +x deploy-universal.sh
    echo "🚀 开始执行部署脚本..."
    ./deploy-universal.sh
else
    echo "❌ 未找到部署脚本"
    exit 1
fi

ENDSSH

if [ $? -eq 0 ]; then
    echo
    echo "=========================================="
    print_success "🎉 ECS部署完成！"
    echo "=========================================="
    echo
    print_success "应用访问地址:"
    print_success "  公网访问: http://$SERVER_IP"
    print_success "  如果有域名: http://your-domain.com"
    echo
    print_success "管理命令 (需要SSH连接到服务器):"
    echo "  连接服务器: ssh $SERVER_USER@$SERVER_IP"
    echo "  查看状态: docker ps"
    echo "  查看日志: cd /var/www/document-scanner && docker-compose -f docker-compose-simple.yml logs -f"
    echo "  重启服务: cd /var/www/document-scanner && docker-compose -f docker-compose-simple.yml restart"
    echo
    print_success "🎯 下一步:"
    echo "  1. 在浏览器中访问 http://$SERVER_IP 测试应用"
    echo "  2. 如需HTTPS，请配置域名和SSL证书"
    echo "  3. 确保阿里云安全组开放了80端口"
else
    print_error "ECS部署过程中出现错误"
    print_error "请检查错误信息并重试"
fi

# 清理本地临时文件
print_step "清理本地临时文件..."
rm -f ${PROJECT_NAME}.tar.gz
print_success "清理完成"

echo
echo "部署脚本执行完毕！"