/**
 * 部署配置文件
 * 支持多环境配置
 */

module.exports = {
    // 开发环境
    development: {
        host: '47.92.236.28',
        user: 'root',
        password: 'Pp--9257', // 生产环境建议使用SSH密钥
        path: '/var/www/document-scanner',
        port: 22,
        url: 'http://47.92.236.28:8080',
        restart: null // 如需重启服务，填写命令
    },
    
    // 生产环境模板
    production: {
        host: 'your-production-server.com',
        user: 'deploy',
        // password: 'your-password', // 不推荐在生产环境使用密码
        keyFile: '~/.ssh/id_rsa', // 推荐使用SSH密钥
        path: '/var/www/document-scanner',
        port: 22,
        url: 'https://your-domain.com',
        restart: 'systemctl restart nginx' // 重启Web服务器
    },
    
    // 测试环境
    staging: {
        host: 'staging-server.com',
        user: 'staging',
        password: 'staging-password',
        path: '/var/www/staging/document-scanner',
        port: 22,
        url: 'http://staging-server.com:8080',
        restart: null
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