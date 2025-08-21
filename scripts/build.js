#!/usr/bin/env node

/**
 * 文档扫描器构建脚本
 * 创建生产环境优化版本
 */

const fs = require('fs');
const path = require('path');

console.log('🔨 开始构建文档扫描器...');

// 创建dist目录
const distDir = 'dist';
if (!fs.existsSync(distDir)) {
    fs.mkdirSync(distDir, { recursive: true });
}

// 需要复制的文件和目录
const filesToCopy = [
    'index.html',
    'js/',
    'css/',
    'assets/',
    'README.md',
    'LICENSE'
];

// 复制文件函数
function copyRecursive(src, dest) {
    const stats = fs.statSync(src);
    
    if (stats.isDirectory()) {
        // 创建目录
        if (!fs.existsSync(dest)) {
            fs.mkdirSync(dest, { recursive: true });
        }
        
        // 递归复制目录内容
        const files = fs.readdirSync(src);
        files.forEach(file => {
            if (!file.startsWith('.')) { // 忽略隐藏文件
                copyRecursive(
                    path.join(src, file),
                    path.join(dest, file)
                );
            }
        });
    } else {
        // 复制文件
        fs.copyFileSync(src, dest);
        console.log(`  ✓ 复制: ${src} -> ${dest}`);
    }
}

// 复制所有必要文件
filesToCopy.forEach(item => {
    const srcPath = item;
    const destPath = path.join(distDir, item);
    
    if (fs.existsSync(srcPath)) {
        copyRecursive(srcPath, destPath);
    } else {
        console.log(`  ⚠️  跳过不存在的文件: ${srcPath}`);
    }
});

// 优化HTML文件（移除开发环境的注释和调试代码）
const htmlPath = path.join(distDir, 'index.html');
if (fs.existsSync(htmlPath)) {
    let html = fs.readFileSync(htmlPath, 'utf8');
    
    // 移除console.log语句
    html = html.replace(/console\.log\([^)]*\);?\s*/g, '');
    
    // 移除多余的空行
    html = html.replace(/\n\s*\n\s*\n/g, '\n\n');
    
    // 添加构建信息
    const buildInfo = `<!-- Built on ${new Date().toISOString()} -->`;
    html = html.replace('</head>', `  ${buildInfo}\n</head>`);
    
    fs.writeFileSync(htmlPath, html);
    console.log('  ✓ 优化HTML文件');
}

// 创建部署信息文件
const deployInfo = {
    buildTime: new Date().toISOString(),
    version: require('../package.json').version,
    environment: process.env.NODE_ENV || 'development',
    files: filesToCopy.filter(f => fs.existsSync(f))
};

fs.writeFileSync(
    path.join(distDir, 'deploy-info.json'),
    JSON.stringify(deployInfo, null, 2)
);

console.log('✅ 构建完成！');
console.log(`📦 输出目录: ${distDir}/`);
console.log(`📊 构建信息: ${distDir}/deploy-info.json`);