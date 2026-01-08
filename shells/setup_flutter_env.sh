#!/bin/bash

# 遇到错误立即停止
set -e

echo "🍎 macOS Flutter 环境极速配置脚本 (Archive 版)"
echo "=================================================="
echo ""

# ==================== 1. 系统与架构检测 ====================
OS_NAME="$(uname -s)"
ARCH_NAME="$(uname -m)"

# 1.1 锁定 macOS 系统
if [[ "$OS_NAME" != "Darwin" ]]; then
    echo "❌ 错误: 本脚本仅支持 macOS 系统。"
    echo "当前系统: $OS_NAME"
    exit 1
fi

echo "🖥️  检测到 macOS 系统"

# 1.2 检测芯片架构
IS_ARM=false
if [[ "$ARCH_NAME" == "arm64" ]]; then
    IS_ARM=true
    echo "⚙️  检测到 Apple Silicon 芯片 (M1/M2/M3...)"
else
    echo "⚙️  检测到 Intel 芯片"
fi

# ==================== 2. Xcode 和命令行工具检查 ====================
echo ""
echo "🔍 检查 Xcode 和命令行工具..."

# 2.1 先检查完整的 Xcode
HAS_XCODE=false
if [ -d "/Applications/Xcode.app" ]; then
    echo "✅ 已安装 Xcode"
    HAS_XCODE=true

    # 配置 Xcode 命令行工具路径
    XCODE_DEV_PATH="/Applications/Xcode.app/Contents/Developer"
    CURRENT_DEV_PATH=$(xcode-select -p 2>/dev/null || echo "")

    if [ "$CURRENT_DEV_PATH" != "$XCODE_DEV_PATH" ]; then
        echo "🔧 正在配置 Xcode 命令行工具路径..."
        sudo xcode-select --switch "$XCODE_DEV_PATH"
        echo "✅ Xcode 命令行工具路径已配置"
    fi
else
    echo "⚠️  未检测到完整的 Xcode"
    echo ""
    echo "Xcode 安装选项："
    echo "   1. 安装完整的 Xcode (约 15GB，包含 iOS 开发所需的全部工具)"
    echo "      - 通过 mas 命令行工具自动安装"
    echo "   2. 只安装 Xcode 命令行工具 (约 500MB，包含基础开发工具)"
    echo "      - 足够运行 Homebrew 和基础开发"
    echo "   3. 手动从 App Store 安装 Xcode"
    echo "   4. 跳过（不推荐，会影响 iOS 开发）"
    echo ""
    read -p "请选择 (1/2/3/4): " -n 1 -r
    echo

    if [[ $REPLY == "1" ]]; then
        # 安装��整的 Xcode
        if ! command -v mas &> /dev/null; then
            echo "📦 未检测到 mas，需要先安装 Xcode 命令行工具..."

            # 检查命令行工具
            if ! xcode-select -p &> /dev/null; then
                echo "🔧 正在安装 Xcode 命令行工具..."
                xcode-select --install
                echo "⏳ 请在弹出的对话框中点击'安装'并等待安装完成..."
                echo "   安装完成后按任意键继续..."
                read -n 1 -s -r
            fi

            # 安装 Homebrew（临时）
            if ! command -v brew &> /dev/null; then
                echo "📦 临时安装 Homebrew 以便安装 mas..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

                # Apple Silicon 配置
                if [ "$IS_ARM" = true ]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
            fi

            echo "📦 正在安装 mas..."
            brew install mas
        fi

        echo "📱 正在通过 mas 安装 Xcode（需要 Apple ID 登录 App Store）..."
        echo "⚠️  注意：Xcode 文件很大（约 15GB），下载需要较长时间。"
        mas install 497799835

        if [ -d "/Applications/Xcode.app" ]; then
            echo "✅ Xcode 安装完成"
            echo "🔧 正在接受许可协议并配置命令行工具..."
            sudo xcodebuild -license accept
            sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
            HAS_XCODE=true
        else
            echo "❌ Xcode 安装失败"
        fi

    elif [[ $REPLY == "2" ]]; then
        # 只安装命令行工具
        echo "🔧 正在安装 Xcode 命令行工具..."
        xcode-select --install
        echo "⏳ 请在弹出的对话框中点击'安装'并等待安装完成..."
        echo "   安装完成后按任意键继续..."
        read -n 1 -s -r

        if xcode-select -p &> /dev/null; then
            echo "✅ Xcode 命令行工具安装完成"
        else
            echo "❌ 错误: Xcode 命令行工具未安装成功"
            exit 1
        fi

    elif [[ $REPLY == "3" ]]; then
        echo "📝 请手动打开 App Store 搜索并安装 Xcode"
        echo "   安装完成后重新运行本脚本"
        exit 0
    else
        echo "⚠️  跳过 Xcode 安装（不推荐）"
        echo "   尝试安装命令行工具以满足基本需求..."

        if ! xcode-select -p &> /dev/null; then
            xcode-select --install
            echo "⏳ 请在弹出的对话框中点击'安装'并等待安装完成..."
            echo "   安装完成后按任意键继续..."
            read -n 1 -s -r
        fi
    fi
fi

# 2.2 最终验证命令行工具
echo ""
echo "🔍 验证命令行工具..."
if xcode-select -p &> /dev/null; then
    echo "✅ 命令行工具可用: $(xcode-select -p)"
else
    echo "❌ 错误: 未检测到命令行工具"
    echo "   iOS 开发和 Homebrew 需要命令行工具"
    exit 1
fi

# ==================== 3. 配置 Shell 环境 ====================
# macOS 默认使用 zsh，但也兼容 bash
CURRENT_SHELL=$(basename "$SHELL")
if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$CURRENT_SHELL" == "bash" ]]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.zshrc" # 默认回退到 zsh
fi

echo ""
echo "🔧 环境变量将写入: $SHELL_RC"

# ==================== 4. Homebrew 检查 ====================
echo ""
echo "🍺 检查 Homebrew..."

if command -v brew &> /dev/null; then
    echo "✅ 已安装 Homebrew"
    BREW_VERSION=$(brew --version | head -n 1)
    echo "   版本: $BREW_VERSION"
else
    echo "📦 未检测到 Homebrew，正在安装..."
    echo "   Homebrew 是 macOS 的包管理器，用于安装各种开发工具"
    echo ""

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon Mac 需要手动添加到 PATH
    if [ "$IS_ARM" = true ]; then
        echo ""
        echo "🔧 配置 Homebrew 环境变量（Apple Silicon）..."

        # 临时添加到当前会话
        eval "$(/opt/homebrew/bin/brew shellenv)"

        # 添加 Homebrew 初始化脚本
        if ! grep -q "/opt/homebrew/bin/brew shellenv" "$SHELL_RC" 2>/dev/null; then
            echo "" >> "$SHELL_RC"
            echo "# Homebrew" >> "$SHELL_RC"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$SHELL_RC"
        fi
    fi

    # 验证安装
    if command -v brew &> /dev/null; then
        echo "✅ Homebrew 安装完成"
    else
        echo "❌ 错误: Homebrew 安装失败"
        echo "   请访问 https://brew.sh 手动安装"
        exit 1
    fi
fi

# ==================== 5. Android Studio 安装检查 ====================
echo ""
echo "🔍 正在检查 Android Studio..."

MISSING_IDE=false

# 检查 Android Studio
if [ -d "/Applications/Android Studio.app" ]; then
    echo "✅ 已安装 Android Studio"
else
    echo "⚠️  警告: 未检测到 Android Studio"
    echo "   Android 开发建议安装 Android Studio 以获取 SDK 和模拟器。"

    read -p "是否自动下载并安装 Android Studio？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📦 正在下载 Android Studio..."

        # 根据架构选择下载链接
        if [ "$IS_ARM" = true ]; then
            AS_URL="https://dl.google.com/android/studio/install/2025.2.2.8/android-studio-2025.2.2.8-mac_arm.dmg"
        else
            AS_URL="https://dl.google.com/android/studio/install/2025.2.2.8/android-studio-2025.2.2.8-mac.dmg"
        fi

        AS_DMG="/tmp/android-studio.dmg"
        curl -o "$AS_DMG" -L "$AS_URL"

        echo "📀 正在挂载 DMG..."
        hdiutil attach "$AS_DMG" -nobrowse

        echo "📋 正在安装 Android Studio..."
        cp -R "/Volumes/Android Studio/Android Studio.app" /Applications/

        echo "📤 正在卸载 DMG..."
        hdiutil detach "/Volumes/Android Studio"
        rm -f "$AS_DMG"

        echo "✅ Android Studio 安装完成"
    else
        MISSING_IDE=true
    fi
fi

if [ "$MISSING_IDE" = true ]; then
    echo ""
    echo "🛑 提示: Android Studio 未安装，可能无法进行 Android 开发。"
    read -p "是否忽略警告继续安装 Flutter SDK？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ 用户取消操作"
        exit 1
    fi
fi

# 验证 iOS 开发环境
if [ "$HAS_XCODE" = false ]; then
    echo ""
    echo "⚠️  警告: 未安装完整的 Xcode，iOS 开发功能将受限"
    echo "   仅可使用 Flutter 命令行工具，无法使用 iOS 模拟器和真机调试"
fi

# ==================== 6. Flutter 检查 ====================
INSTALL_DIR="$HOME/Documents"
FLUTTER_PATH="$INSTALL_DIR/flutter"

echo ""
echo "📱 检查 Flutter SDK..."

# 检查是否已安装 Flutter
if [ -d "$FLUTTER_PATH" ]; then
    echo "✅ 检测到 Flutter 已安装: $FLUTTER_PATH"
    FLUTTER_VERSION=$("$FLUTTER_PATH/bin/flutter" --version | grep "Flutter" | awk '{print $2}')
    echo "   当前版本: $FLUTTER_VERSION"
else
    echo ""
    echo "❌ 未检测到 Flutter SDK"
    echo ""

    # 询问用户 Flutter 版本
    echo "📝 请输入要安装的 Flutter 版本号（例如: 3.83.3）"
    read -p "按 Enter 使用默认版本 [3.83.3]: " FLUTTER_VERSION

    # 如果用户没有输入，使用默认版本
    if [ -z "$FLUTTER_VERSION" ]; then
        FLUTTER_VERSION="3.83.3"
    fi

    echo "   选择的版本: $FLUTTER_VERSION"
    echo ""

    # 根据架构生成下载链接
    if [ "$IS_ARM" = true ]; then
        FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_${FLUTTER_VERSION}-stable.zip"
    else
        FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_${FLUTTER_VERSION}-stable.zip"
    fi

    echo "=================================================="
    echo "📥 Flutter 安装"
    echo "=================================================="
    echo ""
    echo "下载地址: $FLUTTER_URL"
    echo "安装路径: $FLUTTER_PATH"
    echo ""
    read -p "是否自动下载并安装？(y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        FLUTTER_ZIP="/tmp/flutter_${FLUTTER_VERSION}.zip"

        echo "📦 正在下载 Flutter SDK..."
        echo "   这可能需要几分钟，请耐心等待..."

        if curl -o "$FLUTTER_ZIP" -L "$FLUTTER_URL"; then
            echo "✅ 下载完成"

            echo "📂 正在解压到 $INSTALL_DIR..."
            unzip -q "$FLUTTER_ZIP" -d "$INSTALL_DIR"
            rm -f "$FLUTTER_ZIP"

            if [ -d "$FLUTTER_PATH" ]; then
                echo "✅ Flutter SDK 安装完成"
            else
                echo "❌ 解压失败，请检查文件"
                exit 1
            fi
        else
            echo "❌ 下载失败，可能版本号不正确或网络问题"
            echo ""
            echo "请手动下载并安装："
            echo "   1. 访问 Flutter 官网确认正确的版本号"
            echo "   2. 下载对应的 zip 文件"
            echo "   3. 解压到 $INSTALL_DIR"
            echo "   4. 重新运行本脚本"
            exit 1
        fi
    else
        echo ""
        echo "📝 手动安装步骤："
        echo "   1. 访问 Flutter 官网下载对应版本的 SDK"
        echo "   2. 下载地址: $FLUTTER_URL"
        echo "   3. 解压下载的 zip 文件"
        echo "   4. 将解压后的 flutter 文件夹移动到: $INSTALL_DIR"
        echo "      最终路径应为: $FLUTTER_PATH"
        echo ""
        echo "   完成后重新运行本脚本即可。"
        echo "=================================================="
        exit 1
    fi
fi

# ==================== 7. 配置环境变量 ====================
echo ""
echo "🔧 正在更新环境变量..."

# 7.1 备份配置
cp "$SHELL_RC" "${SHELL_RC}.backup.$(date +%Y%m%d_%H%M%S)"

# 7.2 清理旧的 Flutter 配置
grep -v "flutter/bin" "$SHELL_RC" > "${SHELL_RC}.tmp" || true
grep -v ".pub-cache/bin" "${SHELL_RC}.tmp" > "${SHELL_RC}.new" || true
mv "${SHELL_RC}.new" "$SHELL_RC"
rm -f "${SHELL_RC}.tmp"

# 7.3 写入新配置
# 这里使用了单引号防止变量立即展开，除了 $FLUTTER_PATH 需要展开
echo "" >> "$SHELL_RC"
echo "# Flutter SDK Config - $(date)" >> "$SHELL_RC"
echo "export PATH=\"$FLUTTER_PATH/bin:\$PATH\"" >> "$SHELL_RC"
echo "export PATH=\"\$HOME/.pub-cache/bin:\$PATH\"" >> "$SHELL_RC"

# 临时应用路径给当前脚本后续步骤使用
export PATH="$FLUTTER_PATH/bin:$PATH"

echo "✅ Flutter 路径已写入配置文件"

# ==================== 8. JDK 17 配置 ====================
echo ""
echo "☕ 检查 JDK 17 (Flutter 推荐环境)..."

JDK_PATH=""
NEED_INSTALL_JDK=true

# 检查是否已有 JDK 17
if /usr/libexec/java_home -v 17 &> /dev/null; then
    JDK_PATH=$(/usr/libexec/java_home -v 17)
    echo "✅ 检测到已安装 JDK 17: $JDK_PATH"
    NEED_INSTALL_JDK=false
fi

if [ "$NEED_INSTALL_JDK" = true ]; then
    echo "📦 未找到 JDK 17，正在通过 Homebrew 安装 temurin@17..."
    brew install --cask temurin@17

    JDK_PATH=$(/usr/libexec/java_home -v 17)
    echo "✅ JDK 17 安装完成"
fi

# 配置 JAVA_HOME
grep -v "export JAVA_HOME" "$SHELL_RC" > "${SHELL_RC}.tmp" && mv "${SHELL_RC}.tmp" "$SHELL_RC"
echo "" >> "$SHELL_RC"
echo "export JAVA_HOME=\$(/usr/libexec/java_home -v 17)" >> "$SHELL_RC"

# 告诉 Flutter 使用这个 JDK
echo "⚙️  配置 Flutter 使用 JDK 17..."
flutter config --jdk-dir="$JDK_PATH"

# ==================== 9. CocoaPods (iOS 依赖) ====================
echo ""
echo "💎 检查 CocoaPods..."

if ! command -v pod >/dev/null 2>&1; then
    echo "📦 正在通过 Homebrew 安装 CocoaPods..."
    brew install cocoapods
    echo "✅ CocoaPods 安装完成"
else
    echo "✅ CocoaPods 已安装"
fi

# ==================== 10. Android SDK 配置 (如果有) ====================
ANDROID_HOME="$HOME/Library/Android/sdk"
if [ -d "$ANDROID_HOME" ]; then
    echo ""
    echo "🤖 配置 Android SDK 路径..."
    
    # 清理旧配置
    grep -v "ANDROID_HOME" "$SHELL_RC" > "${SHELL_RC}.tmp"
    mv "${SHELL_RC}.tmp" "$SHELL_RC"
    
    echo "" >> "$SHELL_RC"
    echo "export ANDROID_HOME=\"$ANDROID_HOME\"" >> "$SHELL_RC"
    echo "export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$PATH\"" >> "$SHELL_RC"
    echo "export PATH=\"\$ANDROID_HOME/platform-tools:\$PATH\"" >> "$SHELL_RC"
    
    # 尝试同意协议
    if [ -f "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
        echo "📜 自动接受 Android SDK 许可证..."
        yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null 2>&1 || true
    fi
fi

echo ""
echo "=================================================="
echo "🎉 安装配置完成！"
echo "=================================================="
echo "📂 Flutter 安装位置: $FLUTTER_PATH"
echo "🔢 Flutter 版本: $FLUTTER_VERSION"
echo "📝 配置文件: $SHELL_RC"
echo ""
echo "⚠️  重要：请务必执行以下命令使配置立即生效："
echo "   source $SHELL_RC"
echo ""
echo "之后运行 'flutter doctor' 检查环境状态。"