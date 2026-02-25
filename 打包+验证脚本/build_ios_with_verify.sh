

######################################
# 1️⃣ 保存脚本
# mkdir -p tools
# vim tools/build_ios_with_verify.sh
# chmod +x tools/build_ios_with_verify.sh
# 2️⃣ 本地直接跑
# sh tools/build_ios_with_verify.sh appstore
# 3️⃣ 看结果（关键）
# 🧬 __TEXT,__const HASH : a3f1c8...
# ✅ AOT Snapshot changed (binary DNA differs)
# 🎉 Build & Verify SUCCESS
# ❌ 异常（直接 fail）
# ❌ AOT Snapshot NOT changed!
# ❌ __TEXT,__const hash identical to last build
######################################


#!/bin/bash
set -e

######################################
# 1. 基础配置
######################################

CHANNEL=${1:-local}
DATE=$(date +%Y%m%d)
BUILD_NO=$(date +%H%M%S)

BUILD_SALT="${CHANNEL}-${DATE}-${BUILD_NO}"

PROJECT_ROOT=$(pwd)
VERIFY_DIR="$PROJECT_ROOT/.verify"
IPA_DIR="$PROJECT_ROOT/build/ios/ipa"

echo "=============================="
echo "🚀 Flutter iOS Build Pipeline"
echo "CHANNEL    : $CHANNEL"
echo "BUILD_SALT : $BUILD_SALT"
echo "=============================="

######################################
# 2. Dart 层关键调用校验（新增）
######################################

echo "🔍 Verifying SegmentManager usage in Dart code..."

INIT_CALL_COUNT=$(grep -R "SegmentManager\.instance\.init" lib | wc -l)
RANDOM_CALL_COUNT=$(grep -R "SegmentManager\.instance\.randomAction" lib | wc -l)

if [ "$INIT_CALL_COUNT" -eq 0 ]; then
  echo "❌ SegmentManager.instance.init() NOT found in lib/"
  echo "❌ Generator output will NOT be AOT-reachable"
  exit 1
fi

if [ "$RANDOM_CALL_COUNT" -eq 0 ]; then
  echo "⚠️ SegmentManager.instance.randomAction() not found"
  echo "⚠️ This is allowed, but binary similarity effect will be weaker"
else
  echo "✅ randomAction() call detected ($RANDOM_CALL_COUNT)"
fi

echo "✅ init() call detected ($INIT_CALL_COUNT)"

######################################
# 3. 注入 BUILD_SALT
######################################

export BUILD_SALT=$BUILD_SALT

######################################
# 4. 运行 Segment Generator
######################################

echo "🔧 Running segment generator..."
dart scripts/segment_generator.dart

######################################
# 5. Flutter Build IPA
######################################

echo "📦 Building IPA..."
flutter build ipa \
  --release \
  --obfuscate \
  --split-debug-info=out/ios/debug-info/$BUILD_SALT \
  --dart-define=BUILD_SALT=$BUILD_SALT

######################################
# 6. 查找 IPA
######################################

IPA_PATH=$(ls -t $IPA_DIR/*.ipa | head -n 1)

if [ ! -f "$IPA_PATH" ]; then
  echo "❌ IPA not found!"
  exit 1
fi

echo "✅ IPA generated: $IPA_PATH"

######################################
# 7. 解包 IPA
######################################

rm -rf $VERIFY_DIR
mkdir -p $VERIFY_DIR

unzip -q "$IPA_PATH" -d $VERIFY_DIR

BIN="$VERIFY_DIR/Payload/Runner.app/Runner"

######################################
# 8. Mach-O 校验
######################################

RUNNER_HASH=$(shasum -a 256 "$BIN" | awk '{print $1}')
CONST_HASH=$(otool -s __TEXT __const "$BIN" | shasum -a 256 | awk '{print $1}')

echo "🔐 Runner SHA256        : $RUNNER_HASH"
echo "🧬 __TEXT,__const HASH : $CONST_HASH"

######################################
# 9. 历史对比
######################################

RECORD_FILE="$PROJECT_ROOT/.binary_verify_record"

if [ -f "$RECORD_FILE" ]; then
  LAST_CONST_HASH=$(tail -n 1 "$RECORD_FILE" | awk '{print $2}')

  if [ "$LAST_CONST_HASH" == "$CONST_HASH" ]; then
    echo "❌ AOT Snapshot NOT changed!"
    exit 1
  else
    echo "✅ AOT Snapshot changed"
  fi
else
  echo "ℹ️ No previous record, skipping diff"
fi

echo "$BUILD_SALT $CONST_HASH" >> "$RECORD_FILE"

echo "=============================="
echo "🎉 Build & Verify SUCCESS"
echo "=============================="