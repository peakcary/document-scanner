# 🔒 安全配置指南

为了保护服务器密码和其他敏感信息，请按照以下步骤进行安全配置。

## ⚠️ 重要安全提醒

**绝对不要**在代码中直接写入：
- 服务器密码
- API密钥
- 数据库连接信息
- 任何敏感凭据

## 🔧 安全配置方法

### 方法1：使用 .env 文件（推荐）

1. **复制示例文件**
   ```bash
   cp .env.example .env
   ```

2. **编辑 .env 文件**
   ```bash
   # 编辑文件，填入真实密码
   nano .env
   ```
   
   内容示例：
   ```
   SERVER_PASSWORD=Pp--9257
   ```

3. **确保 .env 被忽略**
   ```bash
   # 检查 .gitignore 中包含 .env
   grep ".env" .gitignore
   ```

### 方法2：使用环境变量

```bash
# 设置环境变量
export SERVER_PASSWORD="Pp--9257"

# 执行部署
./deploy-to-server.sh
```

### 方法3：交互式输入

如果没有设置密码，脚本会提示您输入：
```bash
./deploy-to-server.sh
# 会提示：或现在输入密码: [输入密码，不会显示]
```

## 🚀 推荐的 SSH 密钥配置

更安全的方式是使用 SSH 密钥而不是密码：

### 1. 生成 SSH 密钥
```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

### 2. 复制公钥到服务器
```bash
ssh-copy-id root@47.92.236.28
```

### 3. 测试免密登录
```bash
ssh root@47.92.236.28
```

### 4. 修改部署脚本使用 SSH 密钥
如果配置了 SSH 密钥，可以移除密码相关代码：
```bash
# 直接使用 ssh 而不是 sshpass
ssh "$SERVER_USER@$SERVER" "commands"
```

## 🔒 服务器安全加固

### 1. 禁用密码登录
```bash
# 编辑 SSH 配置
sudo nano /etc/ssh/sshd_config

# 修改以下设置
PasswordAuthentication no
PubkeyAuthentication yes

# 重启 SSH 服务
sudo systemctl restart sshd
```

### 2. 更改默认端口
```bash
# 编辑 SSH 配置
sudo nano /etc/ssh/sshd_config

# 修改端口
Port 2222

# 重启服务
sudo systemctl restart sshd
```

### 3. 配置防火墙
```bash
# 只允许特定 IP 访问
firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='YOUR_IP' service name='ssh' accept"
firewall-cmd --reload
```

## 📋 安全检查清单

- [ ] ✅ .env 文件已添加到 .gitignore
- [ ] ✅ 没有在代码中硬编码密码
- [ ] ✅ 配置了 SSH 密钥登录
- [ ] ✅ 禁用了服务器密码登录
- [ ] ✅ 更改了 SSH 默认端口
- [ ] ✅ 配置了防火墙规则
- [ ] ✅ 定期更新服务器补丁

## 🆘 紧急情况处理

### 如果密码泄露：
1. **立即更改服务器密码**
2. **检查服务器日志查看异常登录**
3. **更新所有配置文件**
4. **考虑重新部署服务器**

### 检查服务器日志：
```bash
# 查看登录日志
sudo tail -f /var/log/secure

# 查看失败的登录尝试
sudo grep "Failed password" /var/log/secure
```

## 📞 最佳实践

1. **定期轮换密码**：每3-6个月更换一次
2. **使用强密码**：包含大小写字母、数字、特殊字符
3. **启用双因素认证**：如果支持的话
4. **监控登录活动**：定期检查访问日志
5. **最小权限原则**：只给必要的权限

---

记住：**安全是一个持续的过程，不是一次性的设置！**