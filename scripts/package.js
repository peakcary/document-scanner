#!/usr/bin/env node

/**
 * 文档扫描器打包脚本
 * 创建部署包
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('📦 开始打包文档扫描器...');

// 获取当前时间戳
const timestamp = new Date().toISOString().replace(/[:-]/g, '').replace(/\..+/, '');
const version = require('../package.json').version;
const packageName = `document-scanner-v${version}-${timestamp}.tar.gz`;

// 先执行构建
console.log('🔨 执行构建...');
try {
    execSync('node scripts/build.js', { stdio: 'inherit' });
} catch (error) {
    console.error('❌ 构建失败:', error.message);
    process.exit(1);
}

// 检查dist目录
if (!fs.existsSync('dist')) {
    console.error('❌ dist目录不存在，请先运行构建');
    process.exit(1);
}

// 创建tar.gz包
console.log('📦 创建部署包...');
try {
    execSync(`tar -czf ${packageName} -C dist .`, { stdio: 'inherit' });
    console.log(`✅ 打包完成: ${packageName}`);
} catch (error) {
    console.error('❌ 打包失败:', error.message);
    process.exit(1);
}

// 显示包信息
const stats = fs.statSync(packageName);
const fileSizeMB = (stats.size / (1024 * 1024)).toFixed(2);

console.log('\n📊 打包信息:');
console.log(`   包名: ${packageName}`);
console.log(`   大小: ${fileSizeMB} MB`);
console.log(`   版本: ${version}`);
console.log(`   时间: ${new Date().toLocaleString()}`);

// 创建最新包的软链接
const latestPackage = 'document-scanner-latest.tar.gz';
if (fs.existsSync(latestPackage)) {
    fs.unlinkSync(latestPackage);
}

try {
    fs.symlinkSync(packageName, latestPackage);
    console.log(`🔗 创建最新包链接: ${latestPackage}`);
} catch (error) {
    // 如果系统不支持软链接，就复制文件
    fs.copyFileSync(packageName, latestPackage);
    console.log(`📋 创建最新包副本: ${latestPackage}`);
}

console.log('\n🚀 可以使用以下命令部署:');
console.log(`   npm run deploy`);
console.log(`   或手动部署: scp ${packageName} user@server:/path/`);