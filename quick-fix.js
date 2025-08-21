// 快速修复脚本 - 删除有问题的旧代码
const fs = require('fs');

let content = fs.readFileSync('index.html', 'utf8');

// 找到并删除有问题的代码段
const lines = content.split('\n');
const newLines = [];

let skipMode = false;
for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    
    // 检测开始删除的标记
    if (line.includes('// 添加辅助网格线功能')) {
        skipMode = true;
        continue;
    }
    
    // 检测结束删除的标记
    if (line.includes('// 扫描增强功能')) {
        skipMode = false;
    }
    
    if (!skipMode) {
        newLines.push(line);
    }
}

// 写回修复后的文件
fs.writeFileSync('index.html', newLines.join('\n'));
console.log('修复完成！');