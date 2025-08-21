#!/usr/bin/env node

/**
 * 版本管理脚本
 * 自动更新版本号
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const packageJsonPath = 'package.json';
const package = require(`../${packageJsonPath}`);

// 获取命令行参数
const args = process.argv.slice(2);
const versionType = args[0] || 'patch'; // patch, minor, major

console.log(`📈 更新版本号 (${versionType})...`);

// 解析当前版本
const currentVersion = package.version;
const [major, minor, patch] = currentVersion.split('.').map(Number);

// 计算新版本
let newVersion;
switch (versionType) {
    case 'major':
        newVersion = `${major + 1}.0.0`;
        break;
    case 'minor':
        newVersion = `${major}.${minor + 1}.0`;
        break;
    case 'patch':
    default:
        newVersion = `${major}.${minor}.${patch + 1}`;
        break;
}

console.log(`   ${currentVersion} -> ${newVersion}`);

// 更新package.json
package.version = newVersion;
fs.writeFileSync(packageJsonPath, JSON.stringify(package, null, 2) + '\n');

// 更新index.html中的版本信息
const indexPath = 'index.html';
if (fs.existsSync(indexPath)) {
    let html = fs.readFileSync(indexPath, 'utf8');
    
    // 查找并更新版本注释
    const versionRegex = /<!-- Version: v[\d.]+ -->/;
    const newVersionComment = `<!-- Version: v${newVersion} -->`;
    
    if (versionRegex.test(html)) {
        html = html.replace(versionRegex, newVersionComment);
    } else {
        // 如果没有版本注释，添加一个
        html = html.replace('</head>', `    ${newVersionComment}\n</head>`);
    }
    
    fs.writeFileSync(indexPath, html);
    console.log('✓ 更新index.html版本信息');
}

// Git操作
try {
    // 检查是否有Git仓库
    execSync('git status', { stdio: 'pipe' });
    
    // 添加文件
    execSync('git add package.json index.html', { stdio: 'pipe' });
    
    // 提交
    execSync(`git commit -m "chore: bump version to v${newVersion}"`, { stdio: 'pipe' });
    
    // 创建标签
    execSync(`git tag v${newVersion}`, { stdio: 'pipe' });
    
    console.log('✓ Git提交和标签创建完成');
    console.log(`\n📋 发布清单:`);
    console.log(`   1. git push origin main`);
    console.log(`   2. git push origin v${newVersion}`);
    console.log(`   3. npm run package`);
    console.log(`   4. npm run deploy`);
    
} catch (error) {
    console.log('⚠️  Git操作跳过 (未初始化或有冲突)');
}

console.log(`✅ 版本更新完成: v${newVersion}`);