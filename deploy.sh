#!/bin/bash

# 文档扫描器部署脚本
# 适用于阿里云服务器部署

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
PROJECT_NAME="document-scanner"
DOMAIN_NAME=""
EMAIL=""
DEPLOY_PATH="/var/www/${PROJECT_NAME}"

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请以root用户运行此脚本"
        echo "使用命令: sudo bash deploy.sh"
        exit 1
    fi
}

# 获取用户输入
get_user_input() {
    echo "=== 文档扫描器部署配置 ==="
    echo
    
    read -p "请输入您的域名 (例如: scanner.example.com): " DOMAIN_NAME
    if [ -z "$DOMAIN_NAME" ]; then
        print_error "域名不能为空"
        exit 1
    fi
    
    read -p "请输入您的邮箱 (用于SSL证书): " EMAIL
    if [ -z "$EMAIL" ]; then
        print_error "邮箱不能为空"
        exit 1
    fi
    
    echo
    print_message "配置信息:"
    print_message "域名: $DOMAIN_NAME"
    print_message "邮箱: $EMAIL"
    print_message "部署路径: $DEPLOY_PATH"
    echo
    
    read -p "确认以上配置是否正确? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_message "部署已取消"
        exit 0
    fi
}

# 系统更新
update_system() {
    print_step "更新系统软件包..."
    apt update && apt upgrade -y
}

# 安装必要软件
install_requirements() {
    print_step "安装必要软件..."
    
    # 安装基础软件
    apt install -y curl wget git unzip software-properties-common
    
    # 安装Docker
    if ! command -v docker &> /dev/null; then
        print_message "安装 Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl start docker
        systemctl enable docker
        rm get-docker.sh
    else
        print_message "Docker 已安装"
    fi
    
    # 安装Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_message "安装 Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        print_message "Docker Compose 已安装"
    fi
    
    # 安装Certbot
    if ! command -v certbot &> /dev/null; then
        print_message "安装 Certbot..."
        apt install -y certbot python3-certbot-nginx
    else
        print_message "Certbot 已安装"
    fi
}

# 创建部署目录
create_directories() {
    print_step "创建部署目录..."
    mkdir -p $DEPLOY_PATH
    mkdir -p $DEPLOY_PATH/ssl
    mkdir -p $DEPLOY_PATH/logs
}

# 部署应用文件
deploy_application() {
    print_step "部署应用文件..."
    
    # 复制应用文件
    cp -r ./* $DEPLOY_PATH/
    
    # 设置正确的权限
    chown -R www-data:www-data $DEPLOY_PATH
    chmod -R 755 $DEPLOY_PATH
    
    # 更新Nginx配置中的域名
    sed -i "s/your-domain.com/$DOMAIN_NAME/g" $DEPLOY_PATH/nginx.conf
}

# 配置SSL证书
setup_ssl() {
    print_step "配置SSL证书..."
    
    # 停止可能占用80端口的服务
    systemctl stop nginx 2>/dev/null || true
    docker stop document-scanner 2>/dev/null || true
    
    # 获取SSL证书
    print_message "获取SSL证书..."
    certbot certonly --standalone \
        --non-interactive \
        --agree-tos \
        --email $EMAIL \
        -d $DOMAIN_NAME
    
    # 复制证书到项目目录
    cp /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem $DEPLOY_PATH/ssl/cert.pem
    cp /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem $DEPLOY_PATH/ssl/key.pem
    
    # 设置证书自动续期
    (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && docker restart document-scanner") | crontab -
}

# 配置防火墙
setup_firewall() {
    print_step "配置防火墙..."
    
    if command -v ufw &> /dev/null; then
        ufw --force enable
        ufw allow ssh
        ufw allow 80
        ufw allow 443
        print_message "UFW防火墙已配置"
    else
        print_warning "未检测到UFW防火墙，请手动配置防火墙规则"
    fi
}

# 启动应用
start_application() {
    print_step "启动应用..."
    
    cd $DEPLOY_PATH
    
    # 停止旧容器
    docker-compose down 2>/dev/null || true
    
    # 启动新容器
    docker-compose up -d
    
    # 等待服务启动
    sleep 10
    
    # 检查服务状态
    if docker ps | grep -q document-scanner; then
        print_message "应用启动成功！"
    else
        print_error "应用启动失败，请检查日志"
        docker-compose logs
        exit 1
    fi
}

# 验证部署
verify_deployment() {
    print_step "验证部署..."
    
    # 检查HTTP重定向
    if curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN_NAME | grep -q "301"; then
        print_message "HTTP重定向正常"
    else
        print_warning "HTTP重定向可能有问题"
    fi
    
    # 检查HTTPS访问
    if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN_NAME | grep -q "200"; then
        print_message "HTTPS访问正常"
    else
        print_warning "HTTPS访问可能有问题"
    fi
}

# 显示部署信息
show_deployment_info() {
    echo
    echo "=========================================="
    print_message "部署完成！"
    echo "=========================================="
    echo
    print_message "应用访问地址: https://$DOMAIN_NAME"
    print_message "部署路径: $DEPLOY_PATH"
    print_message "SSL证书路径: /etc/letsencrypt/live/$DOMAIN_NAME/"
    echo
    print_message "常用命令:"
    echo "  查看应用状态: docker ps"
    echo "  查看应用日志: docker-compose logs -f"
    echo "  重启应用: docker-compose restart"
    echo "  停止应用: docker-compose down"
    echo "  更新应用: docker-compose pull && docker-compose up -d"
    echo
    print_message "SSL证书将自动续期，无需手动操作"
    echo
}

# 创建管理脚本
create_management_script() {
    print_step "创建管理脚本..."
    
    cat > /usr/local/bin/scanner-manage << 'EOF'
#!/bin/bash

DEPLOY_PATH="/var/www/document-scanner"

case "$1" in
    start)
        cd $DEPLOY_PATH && docker-compose up -d
        echo "应用已启动"
        ;;
    stop)
        cd $DEPLOY_PATH && docker-compose down
        echo "应用已停止"
        ;;
    restart)
        cd $DEPLOY_PATH && docker-compose restart
        echo "应用已重启"
        ;;
    status)
        docker ps | grep document-scanner
        ;;
    logs)
        cd $DEPLOY_PATH && docker-compose logs -f
        ;;
    update)
        cd $DEPLOY_PATH && docker-compose pull && docker-compose up -d
        echo "应用已更新"
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|logs|update}"
        exit 1
        ;;
esac
EOF

    chmod +x /usr/local/bin/scanner-manage
    print_message "管理脚本已创建: scanner-manage"
}

# 主函数
main() {
    echo "=== 文档扫描器自动部署脚本 ==="
    echo "适用于阿里云服务器"
    echo
    
    check_root
    get_user_input
    
    print_message "开始部署..."
    
    update_system
    install_requirements
    create_directories
    deploy_application
    setup_ssl
    setup_firewall
    start_application
    verify_deployment
    create_management_script
    
    show_deployment_info
    
    print_message "部署完成！请访问 https://$DOMAIN_NAME 查看应用"
}

# 执行主函数
main "$@"