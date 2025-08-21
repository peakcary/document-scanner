/**
 * 部署配置文件
 * 支持多环境配置
 */

module.exports = {
    // 开发环境 - 从环境变量读取配置
    development: {
        host: process.env.DEV_HOST || 'localhost',
        user: process.env.DEV_USER || 'deploy',
        password: process.env.DEV_PASSWORD, // 建议使用SSH密钥
        keyFile: process.env.DEV_KEY_FILE, // SSH私钥文件路径
        path: process.env.DEV_PATH || '/var/www/document-scanner',
        port: parseInt(process.env.DEV_PORT) || 22,
        url: process.env.DEV_URL || 'http://localhost:8080',
        restart: process.env.DEV_RESTART_CMD // 如需重启服务，填写命令
    },
    
    // 生产环境 - 从环境变量读取配置
    production: {
        host: process.env.PROD_HOST || 'your-production-server.com',
        user: process.env.PROD_USER || 'deploy',
        password: process.env.PROD_PASSWORD,
        keyFile: process.env.PROD_KEY_FILE || '~/.ssh/id_rsa',
        path: process.env.PROD_PATH || '/var/www/document-scanner',
        port: parseInt(process.env.PROD_PORT) || 22,
        url: process.env.PROD_URL || 'https://your-domain.com',
        restart: process.env.PROD_RESTART_CMD || 'systemctl restart nginx'
    },
    
    // 测试环境 - 从环境变量读取配置
    staging: {
        host: process.env.STAGING_HOST || 'staging-server.com',
        user: process.env.STAGING_USER || 'staging',
        password: process.env.STAGING_PASSWORD,
        keyFile: process.env.STAGING_KEY_FILE,
        path: process.env.STAGING_PATH || '/var/www/staging/document-scanner',
        port: parseInt(process.env.STAGING_PORT) || 22,
        url: process.env.STAGING_URL || 'http://staging-server.com:8080',
        restart: process.env.STAGING_RESTART_CMD
    }
};

/*
使用方法:

1. 开发环境部署:
   npm run deploy

2. 生产环境部署:
   npm run deploy:prod

3. 自定义环境:
   NODE_ENV=staging npm run deploy

注意事项:
- 生产环境建议使用SSH密钥而不是密码
- 确保目标服务器上有Python3用于运行Web服务器
- 备份文件会自动创建在远程服务器上
- 可以根据需要修改restart命令来重启Web服务
*/