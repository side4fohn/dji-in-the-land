@echo off
:: ============================================================
:: 一键推送 dji-in-the-land 到 GitHub
:: 使用方法:
::   1. 先设置环境变量: set GH_TOKEN=你的GitHub_PAT_token
::   2. 运行: push-to-github.bat
:: ============================================================

setlocal enabledelayedexpansion

set "REPO_DIR=%~dp0"
set "REMOTE_URL=https://github.com/side4fohn/dji-in-the-land.git"
set "TOKEN=%GH_TOKEN%"

echo ================================================
echo  推送 dji-in-the-land 到 GitHub
echo ================================================
echo.

if "%TOKEN%"=="" (
    echo [错误] 请先设置 GH_TOKEN 环境变量:
    echo   set GH_TOKEN=ghp_your_token_here
    echo.
    echo 或直接运行:
    echo   set GH_TOKEN=ghp_your_token_here
    echo   "%~f0"
    echo.
    pause
    exit /b 1
)

echo [1/5] 检查 Git 安装...
git --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到 git，请先安装 Git
    pause
    exit /b 1
)

echo [2/5] 进入仓库目录...
cd /d "%REPO_DIR%"

echo [3/5] 初始化 Git（如果是首次）...
if not exist ".git" (
    echo   初始化新仓库...
    git init
    git remote add origin "!REMOTE_URL!"
) else (
    echo   已有 .git，设置远程仓库...
    git remote set-url origin "!REMOTE_URL!"
)

echo [4/5] 提交所有更改...
git add .
git commit -m "v3: 深度优化 - iOS Flutter (自动推送)"

echo [5/5] 推送到 GitHub...
git push -u origin main --force

if errorlevel 1 (
    echo.
    echo [错误] 推送失败！
    echo.
    echo 请检查:
    echo   1. GH_TOKEN 是否有效
    echo   2. 仓库地址是否正确
    echo   3. 网络连接
    pause
    exit /b 1
)

echo.
echo ================================================
echo  推送成功！
echo.
echo 下一步：
echo   1. 打开 https://github.com/side4fohn/dji-in-the-land/actions
echo   2. 点击 "Build iOS" workflow
echo   3. 点击 "Run workflow" -^> 开始编译
echo ================================================
pause
