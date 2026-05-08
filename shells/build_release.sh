!/usr/bin/env bash

if [[ ! -x "$0" ]]; then
  echo "⚠️  Script is not executable."
  echo "Please run:"
  echo ""
  echo "  chmod +x scripts/build_release.sh"
  echo ""
  echo "Then run:"
  echo ""
  echo "  ./scripts/build_release.sh android"
  echo "  ./scripts/build_release.sh ios"
  echo ""
fi

set -euo pipefail

PLATFORM="${1:-}"

if [[ -z "$PLATFORM" ]]; then
  echo "Usage: scripts/build_release.sh <android|ios>"
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter not found"
  exit 1
fi

echo "🧹 flutter clean"
flutter clean

echo "📦 flutter pub get"
flutter pub get

echo "⚙️ Running pre-build generate..."

dart scripts/generate_api.dart
dart scripts/generate_app_cache_key.dart
dart scripts/generate_app_config.dart
dart scripts/generate_app_event.dart
dart scripts/generate_app_guard.dart
dart scripts/generate_app_key.dart
dart scripts/generate_app_l10n.dart
dart scripts/generate_enum.dart

echo "🔐 Running pre-build obfuscate..."

dart scripts/obfuscate_api.dart
dart scripts/obfuscate_model.dart


# 读取版本号
VERSION_LINE=$(grep '^version:' pubspec.yaml | awk '{print $2}')
BUILD_NAME=${VERSION_LINE%%+*}
BUILD_NUMBER=${VERSION_LINE##*+}

DATE=$(date +%Y%m%d_%H%M%S)
COMMIT=$(git rev-parse --short HEAD)

VERSION_TAG="${BUILD_NAME}+${BUILD_NUMBER}_${DATE}_${COMMIT}"

echo "📦 Version: $VERSION_TAG"

SYMBOL_BASE="build/symbols"
RELEASE_BASE="build/release"

mkdir -p "$RELEASE_BASE"

generate_changelog() {
  git log -20 --pretty=format:"- %s (%h)" > "$1/changelog.txt"
}

build_android() {

  echo "🚀 Building Android..."

  SYMBOL_DIR="$SYMBOL_BASE/android/$VERSION_TAG"
  RELEASE_DIR="$RELEASE_BASE/android_$VERSION_TAG"

  mkdir -p "$RELEASE_DIR"

  flutter build appbundle \
    --release \
    --build-name="$BUILD_NAME" \
    --build-number="$BUILD_NUMBER" \
    --obfuscate \
    --split-debug-info="$SYMBOL_DIR"

  AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

  cp "$AAB_PATH" "$RELEASE_DIR/app.aab"

  cp -r "$SYMBOL_DIR" "$RELEASE_DIR/symbols"

  generate_changelog "$RELEASE_DIR"

  cd "$RELEASE_BASE"
  zip -r "android_${VERSION_TAG}.zip" "android_${VERSION_TAG}" >/dev/null
  cd - >/dev/null

  echo "📦 Android package:"
  echo "$RELEASE_BASE/android_${VERSION_TAG}.zip"
}

build_ios() {

  echo "🚀 Building iOS..."

  SYMBOL_DIR="$SYMBOL_BASE/ios/$VERSION_TAG"
  RELEASE_DIR="$RELEASE_BASE/ios_$VERSION_TAG"

  mkdir -p "$RELEASE_DIR"

  flutter build ipa \
    --release \
    --build-name="$BUILD_NAME" \
    --build-number="$BUILD_NUMBER" \
    --obfuscate \
    --split-debug-info="$SYMBOL_DIR"

  IPA_PATH=$(ls build/ios/ipa/*.ipa | head -n 1)

  cp "$IPA_PATH" "$RELEASE_DIR/app.ipa"

  cp -r "$SYMBOL_DIR" "$RELEASE_DIR/symbols"

  generate_changelog "$RELEASE_DIR"

  cd "$RELEASE_BASE"
  zip -r "ios_${VERSION_TAG}.zip" "ios_${VERSION_TAG}" >/dev/null
  cd - >/dev/null

  echo "📦 iOS package:"
  echo "$RELEASE_BASE/ios_${VERSION_TAG}.zip"
}

case "$PLATFORM" in
  android)
    build_android
    ;;
  ios)
    build_ios
    ;;
  *)
    echo "Unsupported platform: $PLATFORM"
    exit 1
    ;;
esac

echo ""
echo "✅ Build completed"