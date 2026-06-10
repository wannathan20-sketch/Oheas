#!/bin/bash
# 生成 Xcode 项目并写入 DeepSeek API Key
# 用法: ./configure.sh
#
# Key 从 deepseek.env 文件读取（gitignore 了，不提交）
# 格式: DEEPSEEK_API_KEY=sk-xxx

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME_FILE="$SCRIPT_DIR/OHeas.xcodeproj/xcshareddata/xcschemes/OHeas.xcscheme"
ENV_FILE="$SCRIPT_DIR/deepseek.env"

# 读取 key
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

if [ -z "$DEEPSEEK_API_KEY" ]; then
    echo "⚠️  DEEPSEEK_API_KEY 未设置。请在 deepseek.env 文件中填写:"
    echo "   DEEPSEEK_API_KEY=sk-你的key"
    DEEPSEEK_API_KEY=""
fi

# 生成 Xcode 项目
echo "🔧 生成 Xcode 项目..."
xcodegen generate

# 替换占位符
if [ -f "$SCHEME_FILE" ]; then
    sed -i '' "s/DEEPSEEK_API_KEY_PLACEHOLDER/$DEEPSEEK_API_KEY/g" "$SCHEME_FILE"
    echo "✅ API Key 已写入 scheme"
else
    echo "⚠️  未找到 scheme 文件"
fi

echo "✅ 完成。运行: open OHeas.xcodeproj"
