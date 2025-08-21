# 🚀 快速构建部署指南

## 一键命令

```bash
# 开发部署 (当前服务器)
npm run deploy

# 生产部署 (配置后)
npm run deploy:prod

# 手动打包
npm run package
```

## 📋 换服务器部署步骤

### 1. 配置新服务器信息

编辑 `deploy.config.js`:

```javascript
production: {
    host: '新服务器IP',
    user: '用户名',
    password: '密码',  // 或使用keyFile
    path: '/var/www/document-scanner',
    url: 'http://新服务器IP:8080'
}
```

### 2. 一键部署

```bash
npm run deploy:prod
```

### 3. 服务器端启动 (SSH到新服务器)

```bash
cd /var/www/document-scanner
python3 -m http.server 8080 --bind 0.0.0.0 &
```

## 🔧 版本管理

```bash
# 更新版本
npm run version patch   # 1.0.0 -> 1.0.1
npm run version minor   # 1.0.0 -> 1.1.0
npm run version major   # 1.0.0 -> 2.0.0

# 推送到Git
git push origin main
git push origin --tags
```

## 📁 项目结构

```
document-scanner/
├── index.html          # 主页面
├── js/                 # JavaScript文件
├── css/                # 样式文件
├── scripts/            # 构建部署脚本
├── deploy.config.js    # 部署配置
└── dist/              # 构建输出(自动生成)
```

## 🛠️ 功能特性

- ✅ 自动文档边缘检测
- ✅ 裁剪功能完全修复
- ✅ 移动端触摸支持
- ✅ 多种扫描增强模式
- ✅ PDF导出功能
- ✅ 一键部署系统

## 📞 常用命令

```bash
# 本地开发
npm start               # 启动本地服务器

# 构建打包
npm run build          # 构建项目
npm run package        # 创建部署包
npm run clean          # 清理构建文件

# 部署
npm run deploy         # 部署到开发环境
npm run deploy:prod    # 部署到生产环境

# 版本
npm run version        # 升级补丁版本
```

## ⚡ 快速换服务器

1. **修改配置** → 编辑 `deploy.config.js` 中的 production 配置
2. **一键部署** → 运行 `npm run deploy:prod`
3. **启动服务** → 在新服务器运行 `python3 -m http.server 8080 --bind 0.0.0.0`

搞定！🎉