#!/usr/bin/env node

/**
 * 文档扫描器部署脚本
 * 支持多环境部署
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// 加载环境变量
function loadEnvFile(filename) {
    if (fs.existsSync(filename)) {
        const envConfig = fs.readFileSync(filename, 'utf8');
        envConfig.split('\n').forEach(line => {
            const trimmed = line.trim();
            if (trimmed && !trimmed.startsWith('#') && trimmed.includes('=')) {
                const [key, ...values] = trimmed.split('=');
                process.env[key] = values.join('=');
            }
        });
        console.log(`✓ 已加载环境配置: ${filename}`);
    }
}

// 按优先级加载环境变量文件
loadEnvFile('.env.local');  // 本地配置 (最高优先级)
loadEnvFile('.env');        // 通用配置

// 加载配置文件
let config = {};
const configFile = 'deploy.config.js';

if (fs.existsSync(configFile)) {
    config = require(`../${configFile}`);
} else {
    console.log('⚠️  未找到部署配置文件，使用默认配置');
    config = {
        development: {
            host: '47.92.236.28',
            user: 'root',
            password: 'Pp--9257',
            path: '/var/www/document-scanner',
            port: 22
        }
    };
}

// 获取环境
const env = process.env.NODE_ENV || 'development';
const envConfig = config[env];

if (!envConfig) {
    console.error(`❌ 未找到环境 ${env} 的配置`);
    process.exit(1);
}

console.log(`🚀 开始部署到 ${env} 环境...`);
console.log(`   目标: ${envConfig.user}@${envConfig.host}:${envConfig.path}`);

// 检查是否有最新的部署包
const latestPackage = 'document-scanner-latest.tar.gz';
if (!fs.existsSync(latestPackage)) {
    console.log('📦 未找到部署包，开始打包...');
    try {
        execSync('node scripts/package.js', { stdio: 'inherit' });
    } catch (error) {
        console.error('❌ 打包失败:', error.message);
        process.exit(1);
    }
}

// 构建部署命令
const { host, user, password, path: remotePath, port = 22 } = envConfig;

// 备份当前版本
const backupCmd = `sshpass -p "${password}" ssh -p ${port} -o StrictHostKeyChecking=no ${user}@${host} "cd ${remotePath} && tar -czf backup-$(date +%Y%m%d_%H%M%S).tar.gz * 2>/dev/null || echo 'No files to backup'"`;

// 上传新版本
const uploadCmd = `sshpass -p "${password}" scp -P ${port} -o StrictHostKeyChecking=no ${latestPackage} ${user}@${host}:${remotePath}/`;

// 解压并部署
const deployCmd = `sshpass -p "${password}" ssh -p ${port} -o StrictHostKeyChecking=no ${user}@${host} "cd ${remotePath} && tar -xzf document-scanner-latest.tar.gz && rm -f document-scanner-latest.tar.gz"`;

// 重启服务（如果需要）
const restartCmd = envConfig.restart ? 
    `sshpass -p "${password}" ssh -p ${port} -o StrictHostKeyChecking=no ${user}@${host} "${envConfig.restart}"` : 
    null;

try {
    console.log('💾 备份当前版本...');
    execSync(backupCmd, { stdio: 'pipe' });
    
    console.log('📤 上传部署包...');
    execSync(uploadCmd, { stdio: 'inherit' });
    
    console.log('📂 解压并部署...');
    execSync(deployCmd, { stdio: 'inherit' });
    
    if (restartCmd) {
        console.log('🔄 重启服务...');
        execSync(restartCmd, { stdio: 'inherit' });
    }
    
    console.log('✅ 部署成功！');
    
    if (envConfig.url) {
        console.log(`🌐 访问地址: ${envConfig.url}`);
    } else {
        console.log(`🌐 访问地址: http://${host}:8080`);
    }
    
} catch (error) {
    console.error('❌ 部署失败:', error.message);
    console.log('\n🔧 排查建议:');
    console.log('1. 检查网络连接');
    console.log('2. 验证服务器凭据');
    console.log('3. 确认远程路径权限');
    console.log('4. 检查磁盘空间');
    process.exit(1);
}