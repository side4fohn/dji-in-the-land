# GitHub 配置指南

本指南帮助你将本地优化后的 iOS Flutter 代码同步到 GitHub，并配置 CI 自动编译。

---

## 第一步：获取 GitHub Personal Access Token (PAT)

1. 打开 https://github.com/settings/tokens
2. 点击 **Generate new token (classic)**
3. 设置：
   - **Name**: `dji-in-the-land-ci`
   - **Expiration**: 30 days（或按需）
   - **Scopes**: 勾选 `repo` (完整仓库访问)
4. 点击 **Generate token**
5. **立即复制保存**（关闭页面后无法再次查看）

---

## 第二步：本地初始化 Git 并推送

在 **PowerShell** 中执行（每行单独回车）：

```powershell
# 进入 iOS 项目目录
cd e:\dji-in-the-land

# 初始化 Git 仓库
git init

# 添加所有文件
git add .

# 提交
git commit -m "v3: 深度优化 - iOS Flutter"

# 添加远程仓库
git remote add origin https://github.com/side4fohn/dji-in-the-land.git

# 推送（会要求输入用户名和 PAT）
git push -u origin main --force
```

**推送时认证方式**：
- Username: `side4fohn`
- Password: **粘贴刚才的 PAT token**（不是 GitHub 密码！）

---

## 第三步：配置 GitHub Secrets（可选，用于 Release 构建）

Release 构建需要苹果签名证书。如果只用 Simulator 构建，跳过此步。

### 获取 Apple Team ID

1. 打开 https://developer.apple.com
2. 登录 → Account → Membership 信息
3. 复制 **Team ID**（类似 `XXXXXXXXXX`）

### 添加到 GitHub

1. 打开 https://github.com/side4fohn/dji-in-the-land/settings/secrets/actions
2. 点击 **New repository secret**，添加：

| Secret Name | 值 |
|---|---|
| `APPLE_CERTIFICATE` | base64 编码的 .p12 证书（需要从 Mac 导出）|
| `APPLE_CERTIFICATE_PASSWORD` | 导出证书时设置的密码 |
| `APPLE_PROVISIONING_PROFILE` | base64 编码的 .mobileprovision 文件 |
| `APPLE_TEAM_ID` | 你的 Apple Team ID |

3. 添加 **Variables**（不是 Secrets）：
   - `APPLE_TEAM_ID` → 你的 Team ID（公开可见）

---

## 第四步：在 GitHub 上触发构建

1. 打开 https://github.com/side4fohn/dji-in-the-land/actions
2. 点击 **Build iOS** workflow
3. 点击 **Run workflow** → 选择 `main` 分支
4. Build type 选择 **simulator**（无需签名）
5. 点击 **Run workflow**

等待约 10-15 分钟，绿色勾 = 成功。

---

## 第五步：下载构建产物

1. 构建成功后，点击该次构建
2. 进入 **Summary** 标签
3. 在 **Artifacts** 部分下载 `Runner-ios-simulator-xxx.app`

---

## 分支说明

| 分支 | 用途 |
|------|------|
| `main` | 生产代码，**GitHub Actions CI** 自动构建 |
| `dev` | 开发分支，CI 也会自动构建 |

---

## 常见问题

### Q: 推送时提示 `Authentication failed`
**原因**: 密码填错了（填了 GitHub 登录密码而非 PAT）  
**解决**: Password 栏填 **PAT token**，不是 GitHub 密码

### Q: `git push` 一直要求输入密码
**解决**: 使用 Token 认证
```powershell
git remote set-url origin https://side4fohn:YOUR_PAT@github.com/side4fohn/dji-in-the-land.git
```

### Q: GitHub Actions 显示"No runner"
**原因**: 免费账户 macOS runner 有分钟限制  
**解决**: 使用 [Codemagic](https://codemagic.io) 替代（免费 500分钟/月）

### Q: Simulator 构建成功但无法安装到真机
**原因**: Simulator build 没有签名，只能模拟器用  
**解决**: 需要配置 Secrets + Release build，或使用 Codemagic
