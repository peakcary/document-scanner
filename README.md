# 📱 智能文档扫描器

一个功能完整的H5文档扫描应用，支持手机拍照和图片上传，自动生成高质量PDF扫描件。完全基于前端技术，保护用户隐私，支持离线使用。

## ✨ 功能特点

- 📱 **移动端友好**: 专为移动设备优化，支持手机拍照上传
- 🖼️ **多图片处理**: 支持批量上传多张图片，拖拽操作
- 📄 **一键生成PDF**: 自动生成A4格式PDF文档，支持多页
- 🎯 **智能排版**: 自动调整图片尺寸，保持比例，居中排版
- 💾 **即时下载**: PDF生成后自动下载到设备
- 🔒 **隐私保护**: 完全本地处理，无需上传到服务器
- 🌐 **跨平台**: 支持手机、平板、电脑等各种设备

## 🛠️ 技术栈

- **前端框架**: 纯HTML5 + CSS3 + JavaScript
- **PDF生成**: jsPDF 2.5.1
- **图像处理**: Canvas API
- **设备兼容**: getUserMedia API (摄像头访问)
- **UI交互**: 现代CSS3动画和响应式设计

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone git@github.com:peakcary/document-scanner.git
cd document-scanner
```

### 2. 启动本地服务器

选择任一方式启动HTTP服务器：

```bash
# 使用Python 3
python3 -m http.server 8080

# 使用Python 2
python -m SimpleHTTPServer 8080

# 使用Node.js
npx serve . -p 8080

# 使用PHP
php -S localhost:8080
```

### 3. 访问应用

在浏览器中打开：`http://localhost:8080`

## 📖 使用方法

### 📷 手机拍照上传

1. 访问网站
2. 点击 **"📷 选择/拍摄照片"** 按钮
3. 选择 **"拍照"** 或 **"从相册选择"**
4. 拍摄或选择文档照片
5. 预览图片，可调整顺序
6. 点击 **"📄 生成PDF文档"**
7. PDF自动下载到设备

### 🖼️ 电脑图片上传

1. 拖拽图片文件到上传区域
2. 或点击上传区域选择文件
3. 支持同时选择多张图片
4. 预览和排序图片
5. 一键生成PDF并下载

### 🎛️ 图片管理

- **排序**: 使用↑↓按钮调整图片顺序
- **删除**: 点击删除按钮移除不需要的图片
- **预览**: 实时查看将要生成的PDF内容

## 🎯 PDF生成特性

- **A4标准格式**: 210×297mm标准尺寸
- **智能排版**: 自动调整图片尺寸，保持原始比例
- **多页支持**: 每张图片一页，支持批量处理
- **高质量输出**: 保持图片清晰度
- **自动命名**: 带时间戳的文件名

## 📱 支持的格式

- **输入格式**: JPG, JPEG, PNG, WebP, GIF
- **输出格式**: PDF (A4纸张格式)
- **图片质量**: 支持高分辨率图片处理

## 🌐 浏览器兼容性

- ✅ **Chrome 60+** (推荐)
- ✅ **Firefox 55+**
- ✅ **Safari 11+**
- ✅ **Edge 79+**
- ✅ **移动端浏览器** (iOS Safari, Chrome Mobile)

## ⚠️ 重要说明

1. **摄像头权限**: 
   - HTTPS环境下可直接访问摄像头
   - HTTP环境下建议使用图片上传功能
   
2. **性能优化**: 
   - 大图片会自动压缩以提升处理速度
   - 建议单次处理不超过20张图片
   
3. **隐私安全**: 
   - 所有处理完全在本地进行
   - 不会上传任何图片到服务器

## 🚀 服务器部署

### 阿里云ECS部署

项目包含完整的自动化部署脚本：

```bash
# 上传项目到服务器
scp -r document-scanner root@your-server:/tmp/

# 执行部署脚本
./deploy-without-ssl.sh  # Python HTTP服务器
# 或
./deploy-no-docker.sh    # Nginx服务器
```

### Docker部署

```bash
# 使用包含的docker-compose文件
docker-compose up -d
```

### 手动部署

```bash
# 复制文件到Web目录
cp -r . /var/www/document-scanner/

# 启动Python服务器
python3 -m http.server 8080 --bind 0.0.0.0
```

## 📁 项目结构

```
document-scanner/
├── index.html              # 主应用页面
├── css/
│   └── style.css          # 样式文件
├── js/
│   ├── app.js             # 主应用逻辑
│   └── image-processor.js # 图像处理模块
├── assets/                # 静态资源
├── deploy-*.sh           # 部署脚本集合
├── docker-compose.yml    # Docker配置
├── package.json          # 项目配置
└── README.md             # 项目说明
```

## 🔧 开发说明

### 主要功能模块

- **文件上传处理**: 支持多文件选择和拖拽
- **图片预览管理**: 实时预览、排序、删除
- **PDF生成引擎**: 基于jsPDF的高质量PDF生成
- **响应式UI**: 适配各种设备屏幕

### 技术特点

- 纯前端实现，无需后端服务
- 现代ES6+语法
- 响应式设计
- 渐进式Web应用理念

## 📊 演示地址

- **在线演示**: http://47.92.236.28:8080
- **功能展示**: 支持手机访问测试

## 🤝 贡献

欢迎提交Issue和Pull Request来改进项目！

## 📄 开源协议

MIT License - 详见 [LICENSE](LICENSE) 文件