#!/bin/bash

echo "🔧 Flutter 环境配置修复工具"
echo "============================="
echo ""

# 检测操作系统
OS="$(uname -s)"
case "${OS}" in
    Darwin*)    MACHINE=Mac;;
    Linux*)     MACHINE=Linux;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

# 检测当前 Shell
CURRENT_SHELL=$(basename "$SHELL")
echo "🖥️  操作系统: $MACHINE"
echo "🐚 当前 Shell: $CURRENT_SHELL ($SHELL)"
echo ""

# 确定正确的配置文件
if [ "$CURRENT_SHELL" = "zsh" ]; then
    CORRECT_RC="$HOME/.zshrc"
    WRONG_RC="$HOME/.bashrc"
    SHELL_NAME="Zsh"
elif [ "$CURRENT_SHELL" = "bash" ]; then
    CORRECT_RC="$HOME/.bashrc"
    WRONG_RC="$HOME/.zshrc"
    SHELL_NAME="Bash"
else
    echo "❌ 不支持的 Shell: $CURRENT_SHELL"
    exit 1
fi

echo "✅ 检测到 $SHELL_NAME，正确的配置文件应该是: $CORRECT_RC"
echo ""

# 检查是否需要修复
NEED_FIX=false

# 检查错误的配置文件中是否有 Flutter 配置
if [ -f "$WRONG_RC" ] && grep -q "flutter/bin" "$WRONG_RC"; then
    echo "⚠️  发现 Flutter 配置在错误的文件中: $WRONG_RC"
    NEED_FIX=true
fi

# 检查正确的配置文件中是否缺少 Flutter 配置
if [ ! -f "$CORRECT_RC" ] || ! grep -q "flutter/bin" "$CORRECT_RC"; then
    echo "⚠️  正确的配置文件中缺少 Flutter 配置: $CORRECT_RC"
    NEED_FIX=true
fi

if [ "$NEED_FIX" = false ]; then
    echo "✅ 配置文件正确，无需修复"
    echo ""
    echo "🧪 验证环境:"
    if command -v flutter >/dev/null 2>&1; then
        echo "✅ Flutter: $(flutter --version | head -n 1)"
    else
        echo "❌ Flutter 命令不可用，请重新打开终端或运行: source $CORRECT_RC"
    fi
    exit 0
fi

echo ""
echo "🔧 开始修复配置..."

# 备份现有文件
if [ -f "$CORRECT_RC" ]; then
    cp "$CORRECT_RC" "${CORRECT_RC}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "📋 已备份 $CORRECT_RC"
fi

# 从错误的配置文件中提取 Flutter 相关配置
if [ -f "$WRONG_RC" ]; then
    echo "📥 从 $WRONG_RC 提取 Flutter 配置..."
    
    # 提取 Flutter 相关的配置行
    FLUTTER_CONFIG=$(grep -E "(flutter/bin|pub-cache/bin|JAVA_HOME)" "$WRONG_RC" | grep -v "^#")
    
    if [ -n "$FLUTTER_CONFIG" ]; then
        echo "📝 添加配置到 $CORRECT_RC..."
        echo "" >> "$CORRECT_RC"
        echo "# Flutter 环境配置 - 修复于 $(date)" >> "$CORRECT_RC"
        echo "$FLUTTER_CONFIG" >> "$CORRECT_RC"
        
        echo "✅ 配置已添加到正确的文件"
        
        # 询问是否清理错误文件中的配置
        read -p "是否要从 $WRONG_RC 中移除 Flutter 配置？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # 备份错误的配置文件
            cp "$WRONG_RC" "${WRONG_RC}.backup.$(date +%Y%m%d_%H%M%S)"
            
            # 移除 Flutter 相关配置
            grep -v -E "(flutter/bin|pub-cache/bin|JAVA_HOME)" "$WRONG_RC" > "${WRONG_RC}.tmp"
            mv "${WRONG_RC}.tmp" "$WRONG_RC"
            echo "🗑️  已从 $WRONG_RC 中移除 Flutter 配置"
        fi
    fi
else
    echo "❌ 未找到 $WRONG_RC 文件"
fi

# 如果正确的配置文件不存在或为空，添加基本配置
if [ ! -f "$CORRECT_RC" ] || [ ! -s "$CORRECT_RC" ]; then
    echo "📝 创建基本 Flutter 配置..."
    echo "# Flutter 环境配置 - 创建于 $(date)" >> "$CORRECT_RC"
    echo 'export PATH="$HOME/Documents/flutter/bin:$PATH"' >> "$CORRECT_RC"
    echo 'export PATH="$HOME/.pub-cache/bin:$PATH"' >> "$CORRECT_RC"
    
    # 如果能找到 JDK 17，也添加 JAVA_HOME
    if [ "$MACHINE" = "Mac" ] && /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
        echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 17)' >> "$CORRECT_RC"
    fi
fi

echo ""
echo "✅ 配置修复完成！"
echo ""
echo "📝 下一步："
echo "1. 重新加载配置: source $CORRECT_RC"
echo "2. 或者重新打开终端"
echo "3. 验证环境: flutter --version"
echo ""

# 立即验证
echo "🧪 验证修复结果..."
source "$CORRECT_RC"

if command -v flutter >/dev/null 2>&1; then
    echo "✅ Flutter 配置修复成功！"
    flutter --version | head -n 1
else
    echo "⚠️  请重新打开终端或手动运行: source $CORRECT_RC"
fi

echo ""
echo "💡 提示: 配置文件已备份，如有问题可以恢复"