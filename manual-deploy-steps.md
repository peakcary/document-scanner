# 手动部署步骤

## 🔧 问题分析
SSH连接被拒绝，可能的原因：
1. 阿里云ECS默认禁用了密码登录
2. 需要使用密钥登录
3. SSH端口可能不是22
4. 服务器配置了安全策略

## 🚀 解决方案

### 方法1: 使用阿里云控制台
1. 登录阿里云ECS控制台
2. 找到你的ECS实例：47.92.236.28
3. 点击"远程连接" → "通过Workbench远程连接"
4. 使用Web终端直接访问服务器

### 方法2: 配置SSH密钥登录
```bash
# 生成SSH密钥对
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# 将公钥复制到ECS服务器
# (需要在ECS控制台中配置)
```

### 方法3: 手动分步操作

#### 步骤1: 打包项目文件
```bash
cd /Users/peakom
tar -czf document-scanner.tar.gz document-scanner/
```

#### 步骤2: 通过阿里云控制台上传文件
1. 在ECS控制台使用"远程连接"
2. 或者使用阿里云的文件传输工具

#### 步骤3: 在服务器上部署
连接到服务器后执行：
```bash
# 解压文件
cd /tmp
tar -xzf document-scanner.tar.gz
cd document-scanner

# 执行部署
chmod +x deploy-universal.sh
./deploy-universal.sh
```

## 🔑 推荐：使用阿里云控制台

### 详细步骤：

1. **登录阿里云控制台**
   - 访问：https://ecs.console.aliyun.com
   - 找到IP为 47.92.236.28 的ECS实例

2. **远程连接**
   - 点击实例右侧的"远程连接"
   - 选择"通过Workbench远程连接"
   - 输入用户名：root 和密码

3. **上传文件**
   - 在Web终端中执行：
   ```bash
   cd /tmp
   # 然后通过Workbench的文件上传功能上传 document-scanner.tar.gz
   ```

4. **部署应用**
   ```bash
   tar -xzf document-scanner.tar.gz
   cd document-scanner
   chmod +x deploy-universal.sh
   ./deploy-universal.sh
   ```

## 📱 最简单的方法：

如果上述方法都有问题，我可以为你准备一个：
1. **纯HTML版本** - 直接用nginx serve静态文件
2. **Docker镜像** - 预构建好的容器
3. **在线部署脚本** - 通过wget下载并部署

选择哪种方法？