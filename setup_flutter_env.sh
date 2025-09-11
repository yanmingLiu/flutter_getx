#!/bin/bash

set -e

echo "🚀 Flutter 开发环境一键配置脚本"
echo "=================================="
echo ""

# 配置变量
FLUTTER_VERSION="3.32.0"
INSTALL_DIR="$HOME/Documents"
FLUTTER_PATH="$INSTALL_DIR/flutter"

# 检测操作系统
OS="$(uname -s)"
case "${OS}" in
    Darwin*)    MACHINE=Mac;;
    Linux*)     MACHINE=Linux;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo "🖥️  检测到操作系统: $MACHINE"

# 检测 shell 类型
CURRENT_SHELL=$(basename "$SHELL")
echo "🐚 当前 Shell: $CURRENT_SHELL ($SHELL)"

if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="Zsh"
elif [ -n "$BASH_VERSION" ] || [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ]; then
    SHELL_RC="$HOME/.bashrc"
    SHELL_NAME="Bash"
elif [ "$MACHINE" = "Mac" ]; then
    # macOS 默认使用 zsh (从 Catalina 开始)
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="Zsh (macOS 默认)"
else
    SHELL_RC="$HOME/.profile"
    SHELL_NAME="通用 Profile"
fi

echo "🔧 配置文件: $SHELL_RC ($SHELL_NAME)"
echo ""

# ==================== Flutter 安装检查 ====================
echo "📱 检查 Flutter 安装状态..."

FLUTTER_INSTALLED=false
FLUTTER_CURRENT_PATH=""

# 检查是否已有 flutter 命令
if command -v flutter >/dev/null 2>&1; then
    FLUTTER_CURRENT_PATH=$(which flutter)
    FLUTTER_CURRENT_VERSION=$(flutter --version | head -n 1 | grep -o 'Flutter [0-9.]*' | cut -d' ' -f2)
    echo "✅ 检测到已安装的 Flutter: $FLUTTER_CURRENT_VERSION"
    echo "📍 安装路径: $FLUTTER_CURRENT_PATH"
    
    read -p "是否要重新安装 Flutter $FLUTTER_VERSION？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 将重新安装 Flutter..."
        FLUTTER_INSTALLED=false
    else
        echo "⏭️  保留现有 Flutter 版本，继续配置环境变量"
        FLUTTER_INSTALLED=true
        # 获取现有 Flutter 的安装目录
        FLUTTER_PATH=$(dirname $(dirname "$FLUTTER_CURRENT_PATH"))
    fi
else
    echo "❌ 未检测到 Flutter 安装"
    FLUTTER_INSTALLED=false
fi

echo ""

# ==================== Flutter 安装和配置 ====================
if [ "$FLUTTER_INSTALLED" = false ]; then
    echo "📦 开始安装 Flutter $FLUTTER_VERSION..."
    
    # 检查是否已存在目录
    if [ -d "$FLUTTER_PATH" ]; then
        echo "⚠️  Flutter 目录已存在: $FLUTTER_PATH"
        read -p "是否要删除现有目录并重新安装？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🗑️  删除现有 Flutter 目录..."
            rm -rf "$FLUTTER_PATH"
        else
            echo "⏭️  保留现有目录，跳过下载，继续配置环境变量"
            FLUTTER_INSTALLED=true
        fi
    fi
    
    # 只有在需要重新安装时才下载
    if [ "$FLUTTER_INSTALLED" = false ]; then
        # 创建安装目录
        if [ ! -d "$INSTALL_DIR" ]; then
            echo "📁 创建安装目录: $INSTALL_DIR"
            mkdir -p "$INSTALL_DIR"
        fi
        
        # 克隆 Flutter 仓库
        echo "📥 正在下载 Flutter $FLUTTER_VERSION..."
        cd "$INSTALL_DIR"
        git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION"
        
        if [ $? -eq 0 ]; then
            echo "✅ Flutter 下载完成"
        else
            echo "❌ Flutter 下载失败"
            exit 1
        fi
    fi
fi

# 配置 Flutter 环境变量（无论是新安装还是使用现有的）
echo "🔧 配置 Flutter 环境变量..."

# 备份原配置文件
if [ -f "$SHELL_RC" ]; then
    cp "$SHELL_RC" "${SHELL_RC}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "📋 已备份原配置文件"
fi

# 移除旧的 Flutter 配置
if [ -f "$SHELL_RC" ]; then
    grep -v "flutter/bin" "$SHELL_RC" > "${SHELL_RC}.tmp" || true
    grep -v ".pub-cache/bin" "${SHELL_RC}.tmp" > "${SHELL_RC}.new" || true
    mv "${SHELL_RC}.new" "$SHELL_RC"
    rm -f "${SHELL_RC}.tmp"
fi

# 添加新的 Flutter 配置
echo "" >> "$SHELL_RC"
echo "# Flutter SDK 路径配置 - $(date)" >> "$SHELL_RC"
echo "export PATH=\"$FLUTTER_PATH/bin:\$PATH\"" >> "$SHELL_RC"
echo "export PATH=\"\$HOME/.pub-cache/bin:\$PATH\"" >> "$SHELL_RC"

# 添加 Android SDK 环境变量
if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ]; then
    echo "" >> "$SHELL_RC"
    echo "# Android SDK 配置 - $(date)" >> "$SHELL_RC"
    echo "export ANDROID_HOME=\"$ANDROID_HOME\"" >> "$SHELL_RC"
    echo "export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$PATH\"" >> "$SHELL_RC"
    echo "export PATH=\"\$ANDROID_HOME/platform-tools:\$PATH\"" >> "$SHELL_RC"
    echo "export PATH=\"\$ANDROID_HOME/emulator:\$PATH\"" >> "$SHELL_RC"
fi

# 立即应用配置到当前会话
export PATH="$FLUTTER_PATH/bin:$PATH"
export PATH="$HOME/.pub-cache/bin:$PATH"

echo "✅ Flutter 环境配置完成"

echo ""

# ==================== JDK 17 安装检查 ====================
echo "☕ 检查 JDK 17 安装状态..."

JDK_INSTALLED=false
JDK_PATH=""

# 检查 Java 版本
if command -v java >/dev/null 2>&1; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | grep -o '"[0-9.]*"' | tr -d '"' | cut -d'.' -f1)
    if [ "$JAVA_VERSION" = "17" ]; then
        if [ "$MACHINE" = "Mac" ]; then
            JDK_PATH=$(/usr/libexec/java_home -v 17 2>/dev/null || echo "")
        else
            JDK_PATH="$JAVA_HOME"
        fi
        
        if [ -n "$JDK_PATH" ]; then
            echo "✅ 检测到 JDK 17: $JDK_PATH"
            read -p "是否要重新配置 JDK 17？(y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "🔄 将重新配置 JDK 17..."
                JDK_INSTALLED=false
            else
                echo "⏭️  保留现有 JDK 17 配置，继续后续流程"
                JDK_INSTALLED=true
                # 确保 JAVA_HOME 设置正确
                if [ "$MACHINE" = "Mac" ]; then
                    export JAVA_HOME=$(/usr/libexec/java_home -v 17)
                else
                    export JAVA_HOME="$JDK_PATH"
                fi
            fi
        else
            echo "⚠️  检测到 Java 17 但 JAVA_HOME 未正确配置"
            JDK_INSTALLED=false
        fi
    else
        echo "⚠️  检测到 Java $JAVA_VERSION，需要 JDK 17"
        JDK_INSTALLED=false
    fi
else
    echo "❌ 未检测到 Java 安装"
    JDK_INSTALLED=false
fi

echo ""

# ==================== JDK 17 安装和配置 ====================
if [ "$JDK_INSTALLED" = false ]; then
    echo "☕ 开始安装和配置 JDK 17..."
    
    if [ "$MACHINE" = "Mac" ]; then
        # macOS 安装
        echo "🍎 macOS 系统 - 使用 Homebrew 安装 JDK 17"
        
        # 检查 Homebrew
        if ! command -v brew &> /dev/null; then
            echo "❌ 未检测到 Homebrew，请先安装 Homebrew:"
            echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
        
        echo "📦 使用 Homebrew 安装 temurin@17..."
        brew install --cask temurin@17
        
        # 获取 JDK 17 路径
        JDK_PATH=$(/usr/libexec/java_home -v 17)
        echo "✅ JDK 17 路径: $JDK_PATH"
        
    elif [ "$MACHINE" = "Linux" ]; then
        # Linux 安装
        echo "🐧 Linux 系统 - 安装 OpenJDK 17"
        
        # 检测 Linux 发行版
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        else
            echo "❌ 无法检测 Linux 发行版"
            exit 1
        fi
        
        echo "📋 检测到发行版: $DISTRO"
        
        case $DISTRO in
            ubuntu|debian)
                echo "📦 使用 apt 安装 OpenJDK 17..."
                sudo apt update
                sudo apt install openjdk-17-jdk -y
                JDK_PATH="/usr/lib/jvm/java-17-openjdk-amd64"
                ;;
            centos|rhel|fedora)
                echo "📦 使用 yum/dnf 安装 OpenJDK 17..."
                if command -v dnf &> /dev/null; then
                    sudo dnf install java-17-openjdk-devel -y
                else
                    sudo yum install java-17-openjdk-devel -y
                fi
                JDK_PATH="/usr/lib/jvm/java-17-openjdk"
                ;;
            arch)
                echo "📦 使用 pacman 安装 OpenJDK 17..."
                sudo pacman -S jdk17-openjdk --noconfirm
                JDK_PATH="/usr/lib/jvm/java-17-openjdk"
                ;;
            *)
                echo "❌ 不支持的 Linux 发行版: $DISTRO"
                echo "请手动安装 JDK 17"
                exit 1
                ;;
        esac
    else
        echo "❌ 不支持的操作系统: $MACHINE"
        echo "请手动安装 JDK 17"
        exit 1
    fi
else
    echo "✅ 使用现有 JDK 17 安装"
    # 确保 JDK_PATH 正确设置
    if [ "$MACHINE" = "Mac" ]; then
        JDK_PATH=$(/usr/libexec/java_home -v 17)
    fi
fi

# 配置 JAVA_HOME 环境变量（无论是新安装还是使用现有的）
echo "🔧 配置 JAVA_HOME 环境变量..."

# 移除旧的 JAVA_HOME 配置
if [ -f "$SHELL_RC" ]; then
    grep -v "export JAVA_HOME" "$SHELL_RC" > "${SHELL_RC}.tmp" || true
    mv "${SHELL_RC}.tmp" "$SHELL_RC"
fi

# 添加新的 JAVA_HOME 配置
echo "" >> "$SHELL_RC"
echo "# JDK 17 配置 - $(date)" >> "$SHELL_RC"

if [ "$MACHINE" = "Mac" ]; then
    echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 17)' >> "$SHELL_RC"
else
    echo "export JAVA_HOME=\"$JDK_PATH\"" >> "$SHELL_RC"
fi

echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> "$SHELL_RC"

# 立即应用配置
if [ "$MACHINE" = "Mac" ]; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 17)
else
    export JAVA_HOME="$JDK_PATH"
fi
export PATH="$JAVA_HOME/bin:$PATH"

echo "✅ JDK 17 环境配置完成"

echo ""

# ==================== Ruby 和 CocoaPods 配置 (仅 macOS) ====================
if [ "$MACHINE" = "Mac" ]; then
    echo "💎 检查 Ruby 和 CocoaPods 安装状态 (iOS 开发必需)..."
    
    RUBY_INSTALLED=false
    COCOAPODS_INSTALLED=false
    
    # 检查当前 Ruby 版本
    if command -v ruby >/dev/null 2>&1; then
        CURRENT_RUBY_VERSION=$(ruby -v | grep -o 'ruby [0-9.]*' | cut -d' ' -f2)
        RUBY_MAJOR_VERSION=$(echo "$CURRENT_RUBY_VERSION" | cut -d'.' -f1)
        RUBY_MINOR_VERSION=$(echo "$CURRENT_RUBY_VERSION" | cut -d'.' -f2)
        
        echo "📍 当前 Ruby 版本: $CURRENT_RUBY_VERSION"
        
        # 检查 Ruby 版本是否满足要求 (>= 3.1.0)
        if [ "$RUBY_MAJOR_VERSION" -gt 3 ] || ([ "$RUBY_MAJOR_VERSION" -eq 3 ] && [ "$RUBY_MINOR_VERSION" -ge 1 ]); then
            echo "✅ Ruby 版本满足要求 (>= 3.1.0)"
            RUBY_INSTALLED=true
        else
            echo "⚠️  Ruby 版本过低 (需要 >= 3.1.0)，需要升级"
            RUBY_INSTALLED=false
        fi
    else
        echo "❌ 未检测到 Ruby 安装"
        RUBY_INSTALLED=false
    fi
    
    # 检查 CocoaPods
    if command -v pod >/dev/null 2>&1; then
        COCOAPODS_VERSION=$(pod --version)
        echo "✅ 检测到 CocoaPods: $COCOAPODS_VERSION"
        COCOAPODS_INSTALLED=true
    else
        echo "❌ 未检测到 CocoaPods 安装"
        COCOAPODS_INSTALLED=false
    fi
    
    # 如果需要安装或升级 Ruby
    if [ "$RUBY_INSTALLED" = false ]; then
        echo ""
        echo "💎 开始安装 rbenv 和 Ruby..."
        
        # 检查 Homebrew
        if ! command -v brew &> /dev/null; then
            echo "❌ 需要 Homebrew 来安装 rbenv，请先安装 Homebrew"
            exit 1
        fi
        
        # 安装 rbenv 和 ruby-build
        echo "📦 安装 rbenv 和 ruby-build..."
        brew update
        brew install rbenv ruby-build
        
        # 安装依赖库（解决编译问题）
        echo "📦 安装 Ruby 编译依赖..."
        brew install openssl readline libyaml
        
        # 配置 rbenv 到 shell
        echo "🔧 配置 rbenv 环境变量..."
        
        # 移除旧的 rbenv 配置
        if [ -f "$SHELL_RC" ]; then
            grep -v "rbenv" "$SHELL_RC" > "${SHELL_RC}.tmp" || true
            mv "${SHELL_RC}.tmp" "$SHELL_RC"
        fi
        
        # 添加 rbenv 配置到文件末尾
        echo "" >> "$SHELL_RC"
        echo "# rbenv 配置 - $(date)" >> "$SHELL_RC"
        echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> "$SHELL_RC"
        if [ "$SHELL_NAME" = "Zsh" ] || [[ "$SHELL_RC" == *".zshrc" ]]; then
            echo 'eval "$(rbenv init - zsh)"' >> "$SHELL_RC"
        else
            echo 'eval "$(rbenv init - bash)"' >> "$SHELL_RC"
        fi
        
        # 立即应用 rbenv 配置
        export PATH="$HOME/.rbenv/bin:$PATH"
        eval "$(rbenv init -)"
        
        # 列出可用的 Ruby 版本并让用户选择
        echo ""
        echo "📋 列出已安装的 Ruby 版本:"
        rbenv versions || echo "暂无已安装的版本"
        
        echo ""
        echo "🔍 推荐安装 Ruby 3.3.0 或更高版本"
        read -p "请输入要安装的 Ruby 版本 (例如: 3.3.0): " RUBY_VERSION
        
        if [ -z "$RUBY_VERSION" ]; then
            RUBY_VERSION="3.3.0"
            echo "使用默认版本: $RUBY_VERSION"
        fi
        
        echo "📥 安装 Ruby $RUBY_VERSION (这可能需要几分钟)..."
        rbenv install "$RUBY_VERSION"
        
        # 设置为全局默认版本
        echo "🔧 设置 Ruby $RUBY_VERSION 为全局默认版本..."
        rbenv global "$RUBY_VERSION"
        rbenv rehash
        
        # 验证安装
        echo "🧪 验证 Ruby 安装..."
        NEW_RUBY_VERSION=$(rbenv version | cut -d' ' -f1)
        echo "✅ 当前 Ruby 版本: $NEW_RUBY_VERSION"
        
        # 安装 Bundler
        echo "📦 安装 Bundler..."
        gem install bundler
        
        RUBY_INSTALLED=true
    else
        echo "✅ Ruby 版本满足要求，跳过安装"
    fi
    
    # 安装 CocoaPods
    if [ "$COCOAPODS_INSTALLED" = false ]; then
        echo ""
        echo "🍫 开始安装 CocoaPods..."
        
        # 确保使用正确的 Ruby 环境
        if command -v rbenv >/dev/null 2>&1; then
            eval "$(rbenv init -)"
            rbenv rehash
        fi
        
        # 安装 CocoaPods
        echo "📦 安装 CocoaPods..."
        if command -v rbenv >/dev/null 2>&1; then
            # 使用 rbenv 管理的 Ruby
            gem install cocoapods
        else
            # 使用系统 Ruby (需要 sudo)
            sudo gem install -n /usr/local/bin cocoapods
        fi
        
        # 验证安装
        echo "🧪 验证 CocoaPods 安装..."
        if command -v pod >/dev/null 2>&1; then
            POD_VERSION=$(pod --version)
            echo "✅ CocoaPods 安装成功: $POD_VERSION"
        else
            echo "⚠️  CocoaPods 安装可能有问题，请手动验证"
        fi
    else
        echo "✅ CocoaPods 已安装，跳过安装"
    fi
    
    echo ""
    echo "💡 Ruby 和 CocoaPods 配置提示:"
    echo "- 如果 ruby -v 仍显示旧版本，请运行: exec \$SHELL"
    echo "- 或者重新打开终端窗口"
    echo "- 验证命令: ruby -v && pod --version"
    
    echo ""
else
    echo "⏭️  非 macOS 系统，跳过 Ruby 和 CocoaPods 配置"
fi

echo ""

# ==================== Android SDK 配置 ====================
echo "🤖 配置 Android 开发环境..."

# 检测 Android Studio 和 SDK
ANDROID_HOME=""
ANDROID_STUDIO_PATHS=(
    "/Applications/Android Studio.app"
    "$HOME/Library/Android/sdk"
    "$HOME/Android/Sdk"
    "/usr/local/android-sdk"
)

# 查找 Android SDK
for path in "${ANDROID_STUDIO_PATHS[@]}"; do
    if [ -d "$path" ]; then
        if [[ "$path" == *"Android Studio.app" ]]; then
            # 从 Android Studio 推断 SDK 路径
            ANDROID_HOME="$HOME/Library/Android/sdk"
        else
            ANDROID_HOME="$path"
        fi
        break
    fi
done

if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ]; then
    echo "✅ 检测到 Android SDK: $ANDROID_HOME"
    
    # 检查 cmdline-tools
    if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
        echo "⚠️  未找到 cmdline-tools，尝试自动配置..."
        
        # 检查是否有其他版本的 cmdline-tools
        if [ -d "$ANDROID_HOME/cmdline-tools" ]; then
            cd "$ANDROID_HOME/cmdline-tools"
            # 查找最新版本目录
            LATEST_VERSION=$(ls -1 | grep -E '^[0-9]+\.[0-9]+' | sort -V | tail -1)
            if [ -n "$LATEST_VERSION" ] && [ -d "$LATEST_VERSION" ]; then
                echo "📁 创建 latest 符号链接指向 $LATEST_VERSION"
                ln -sf "$LATEST_VERSION" latest
            fi
        fi
    fi
    
    # 配置 Android 环境变量
    echo "🔧 配置 Android 环境变量..."
    
    # 立即应用到当前会话
    export ANDROID_HOME="$ANDROID_HOME"
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
    export PATH="$ANDROID_HOME/platform-tools:$PATH"
    export PATH="$ANDROID_HOME/emulator:$PATH"
    
    # 检查并接受许可证
    if command -v sdkmanager >/dev/null 2>&1; then
        echo "📜 检查并接受 Android SDK 许可证..."
        yes | sdkmanager --licenses >/dev/null 2>&1 || true
        echo "✅ Android SDK 许可证已接受"
    else
        echo "⚠️  sdkmanager 不可用，请手动安装 cmdline-tools"
    fi
    
else
    echo "❌ 未检测到 Android SDK"
    echo "💡 请先安装 Android Studio 或手动安装 Android SDK"
    echo ""
    echo "📥 Android Studio 下载地址:"
    echo "   https://developer.android.com/studio"
    echo ""
    
    read -p "是否继续配置其他组件？(Y/n): " continue_setup
    if [[ "$continue_setup" =~ ^[Nn]$ ]]; then
        echo "❌ 用户选择退出"
        exit 1
    fi
fi

echo ""

# ==================== Flutter 配置 JDK ====================
echo "⚙️ 配置 Flutter 使用 JDK 17..."
if command -v flutter &> /dev/null; then
    flutter config --jdk-dir="$JAVA_HOME"
    echo "✅ Flutter JDK 配置完成"
else
    echo "⚠️  Flutter 命令不可用，跳过 JDK 配置"
fi

echo ""

# ==================== 环境验证 ====================
echo "🧪 验证开发环境..."

# 重新加载配置文件
if [ -f "$SHELL_RC" ]; then
    source "$SHELL_RC"
fi

echo ""
echo "📋 环境信息："

# 验证 Flutter
if command -v flutter >/dev/null 2>&1; then
    echo "✅ Flutter: $(flutter --version | head -n 1)"
else
    echo "❌ Flutter 命令不可用"
fi

# 验证 Java
if command -v java >/dev/null 2>&1; then
    JAVA_VER=$(java -version 2>&1 | head -n 1)
    echo "✅ Java: $JAVA_VER"
    echo "📍 JAVA_HOME: $JAVA_HOME"
else
    echo "❌ Java 命令不可用"
fi

# 验证 Ruby (仅 macOS)
if [ "$MACHINE" = "Mac" ]; then
    if command -v ruby >/dev/null 2>&1; then
        RUBY_VER=$(ruby -v | grep -o 'ruby [0-9.]*' | cut -d' ' -f2)
        echo "✅ Ruby: $RUBY_VER"
        if command -v rbenv >/dev/null 2>&1; then
            RBENV_VER=$(rbenv version | cut -d' ' -f1)
            echo "📍 rbenv 当前版本: $RBENV_VER"
        fi
    else
        echo "❌ Ruby 命令不可用"
    fi
    
    # 验证 CocoaPods
    if command -v pod >/dev/null 2>&1; then
        POD_VER=$(pod --version)
        echo "✅ CocoaPods: $POD_VER"
    else
        echo "❌ CocoaPods 命令不可用"
    fi

# 验证 Android SDK
if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ]; then
    echo "✅ Android SDK: $ANDROID_HOME"
    
    # 验证 cmdline-tools
    if command -v sdkmanager >/dev/null 2>&1; then
        echo "✅ Android cmdline-tools: 可用"
    else
        echo "❌ Android cmdline-tools 不可用"
    fi
    
    # 验证 platform-tools
    if command -v adb >/dev/null 2>&1; then
        ADB_VER=$(adb version | head -1)
        echo "✅ Android platform-tools: $ADB_VER"
    else
        echo "❌ Android platform-tools (adb) 不可用"
    fi
else
    echo "❌ Android SDK 未配置"
fi
fi

echo ""

# 运行 Flutter Doctor
if command -v flutter >/dev/null 2>&1; then
    echo "🏥 运行 Flutter Doctor 检查..."
    flutter doctor -v
else
    echo "⚠️  无法运行 Flutter Doctor，请检查 Flutter 安装"
fi

echo ""
echo "=================================="
echo "🎉 Flutter 开发环境配置完成！"
echo ""

# 最终状态检查和用户指导
ALL_READY=true

# 检查基本组件
if ! command -v flutter >/dev/null 2>&1; then
    ALL_READY=false
fi
if ! command -v java >/dev/null 2>&1; then
    ALL_READY=false
fi

# macOS 额外检查 Ruby 和 CocoaPods
if [ "$MACHINE" = "Mac" ]; then
    if ! command -v ruby >/dev/null 2>&1; then
        ALL_READY=false
    fi
    if ! command -v pod >/dev/null 2>&1; then
        ALL_READY=false
    fi
fi

if [ "$ALL_READY" = true ]; then
    echo "✅ 所有组件已成功配置并可以使用！"
    echo ""
    echo "📝 下一步："
    echo "1. 安装 Android Studio 和配置 Android SDK"
    if [ "$MACHINE" = "Mac" ]; then
        echo "2. 安装 Xcode (用于 iOS 开发)"
        echo "3. 创建新的 Flutter 项目: flutter create my_app"
        echo "4. 运行 Android 项目: cd my_app && flutter run"
        echo "5. 运行 iOS 项目: cd my_app && flutter run -d ios"
    else
        echo "2. 创建新的 Flutter 项目: flutter create my_app"
        echo "3. 运行项目: cd my_app && flutter run"
    fi
else
    echo "⚠️  部分组件需要重新加载环境变量才能使用"
    echo ""
    echo "请选择以下任一方式使配置生效："
    echo "方式1 (推荐): 重新打开终端窗口"
    echo "方式2: 在当前终端运行: source $SHELL_RC"
    if [ "$MACHINE" = "Mac" ] && command -v rbenv >/dev/null 2>&1; then
        echo "方式3: 强制重新加载 Shell: exec \$SHELL"
    fi
    echo ""
    echo "配置生效后，请运行以下命令验证："
    echo "  flutter --version"
    echo "  java -version"
    if [ "$MACHINE" = "Mac" ]; then
        echo "  ruby -v"
        echo "  pod --version"
    fi
    echo "  flutter doctor -v"
fi

echo ""
echo "💡 提示:"
echo "- 配置文件: $SHELL_RC ($SHELL_NAME)"
echo "- Flutter 路径: $FLUTTER_PATH"
echo "- JDK 路径: $JAVA_HOME"
if [ -n "$ANDROID_HOME" ]; then
    echo "- Android SDK: $ANDROID_HOME"
fi
if [ "$MACHINE" = "Mac" ] && command -v rbenv >/dev/null 2>&1; then
    RBENV_ROOT=$(rbenv root 2>/dev/null || echo "$HOME/.rbenv")
    echo "- rbenv 路径: $RBENV_ROOT"
fi
echo "- 如遇问题，请查看备份的配置文件"

# 特别提示 macOS 用户
if [ "$MACHINE" = "Mac" ]; then
    echo ""
    echo "🍎 macOS 用户提示:"
    echo "- 如果您使用的是 Zsh (推荐)，配置已正确写入 ~/.zshrc"
    echo "- 如果您使用的是 Bash，请手动将配置复制到 ~/.bashrc"
    echo "- 可以通过 'echo \$SHELL' 命令查看当前使用的 Shell"
    
    if command -v rbenv >/dev/null 2>&1; then
        echo ""
        echo "💎 Ruby 环境提示:"
        echo "- rbenv 配置已添加到配置文件末尾，避免被其他 PATH 覆盖"
        echo "- 如果 ruby -v 仍显示系统版本，请运行: exec \$SHELL"
        echo "- 或者运行: rbenv rehash && rbenv global \$(rbenv versions --bare | tail -1)"
        echo "- 验证 Ruby: ruby -v (应显示 >= 3.1.0)"
        echo "- 验证 CocoaPods: pod --version"
    fi
fi

echo ""
echo "📚 更多帮助: https://flutter.dev/docs/get-started/install"