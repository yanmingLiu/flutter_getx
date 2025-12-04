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

# ==================== 2. IDE 安装检查 ====================
echo ""
echo "🔍 正在检查开发工具..."

MISSING_IDE=false

# 检查 Xcode
if [ -d "/Applications/Xcode.app" ]; then
    echo "✅ 已安装 Xcode"
else
    echo "⚠️  警告: 未检测到 Xcode (/Applications/Xcode.app)"
    echo "   iOS 开发必须安装 Xcode，请务必在 App Store 下载。"
    MISSING_IDE=true
fi

# 检查 Android Studio
if [ -d "/Applications/Android Studio.app" ]; then
    echo "✅ 已安装 Android Studio"
else
    echo "⚠️  警告: 未检测到 Android Studio"
    echo "   Android 开发建议安装 Android Studio 以获取 SDK 和模拟器。"
    MISSING_IDE=true
fi

if [ "$MISSING_IDE" = true ]; then
    echo ""
    echo "🛑 提示: 缺少 IDE 不会阻止脚本运行，但会导致无法进行对应平台的开发。"
    read -p "是否忽略警告继续安装 Flutter SDK？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ 用户取消操作"
        exit 1
    fi
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

# ==================== 4. Flutter 检查 ====================
INSTALL_DIR="$HOME/Documents"
FLUTTER_PATH="$INSTALL_DIR/flutter"

echo ""
echo "📱 检查 Flutter SDK..."

# 检查是否已安装 Flutter
if [ -d "$FLUTTER_PATH" ]; then
    echo "✅ 检测到 Flutter 已安装: $FLUTTER_PATH"
else
    echo ""
    echo "❌ 未检测到 Flutter SDK"
    echo ""
    echo "=================================================="
    echo "📥 请手动下载并安装 Flutter"
    echo "=================================================="
    echo ""
    echo "📝 安装步骤："
    echo "   1. 访问 Flutter 官网下载对应版本的 SDK"
    if [ "$IS_ARM" = true ]; then
        echo "      Apple Silicon 下载地址示例:"
        echo "      https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.38.3-stable.zip"
    else
        echo "      Intel 下载地址示例:"
        echo "      https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.38.3-stable.zip"
    fi
    echo ""
    echo "   2. 解压下载的 zip 文件"
    echo "   3. 将解压后的 flutter 文件夹移动到: $INSTALL_DIR"
    echo "      最终路径应为: $FLUTTER_PATH"
    echo ""
    echo "   完成后重新运行本脚本即可。"
    echo "=================================================="
    exit 1
fi

# ==================== 5. 配置环境变量 ====================
echo ""
echo "🔧 正在更新环境变量..."

# 5.1 备份配置
cp "$SHELL_RC" "${SHELL_RC}.backup.$(date +%Y%m%d_%H%M%S)"

# 5.2 清理旧的 Flutter 配置
grep -v "flutter/bin" "$SHELL_RC" > "${SHELL_RC}.tmp" || true
grep -v ".pub-cache/bin" "${SHELL_RC}.tmp" > "${SHELL_RC}.new" || true
mv "${SHELL_RC}.new" "$SHELL_RC"
rm -f "${SHELL_RC}.tmp"

# 5.3 写入新配置
# 这里使用了单引号防止变量立即展开，除了 $FLUTTER_PATH 需要展开
echo "" >> "$SHELL_RC"
echo "# Flutter SDK Config - $(date)" >> "$SHELL_RC"
echo "export PATH=\"$FLUTTER_PATH/bin:\$PATH\"" >> "$SHELL_RC"
echo "export PATH=\"\$HOME/.pub-cache/bin:\$PATH\"" >> "$SHELL_RC"

# 临时应用路径给当前脚本后续步骤使用
export PATH="$FLUTTER_PATH/bin:$PATH"

echo "✅ Flutter 路径已写入配置文件"

# ==================== 6. JDK 17 配置 ====================
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
    echo "📦 未找到 JDK 17，准备安装..."
    
    # 检查 Homebrew
    if ! command -v brew &> /dev/null; then
        echo "❌ 错误: 未检测到 Homebrew。"
        echo "   请先运行: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi

    echo "   正在通过 Homebrew 安装 temurin@17..."
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

# ==================== 7. CocoaPods (iOS 依赖) ====================
echo ""
echo "💎 检查 CocoaPods..."

if ! command -v pod >/dev/null 2>&1; then
    echo "📦 正在安装 CocoaPods (使用 Homebrew)..."
    if command -v brew &> /dev/null; then
        brew install cocoapods
    else
        echo "⚠️  Homebrew 未找到，尝试使用 gem 安装 (可能需要密码)..."
        sudo gem install cocoapods
    fi
else
    echo "✅ CocoaPods 已安装"
fi

# ==================== 8. Android SDK 配置 (如果有) ====================
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