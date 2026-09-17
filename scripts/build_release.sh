#!/usr/bin/env bash

# 切换到项目根目录，确保后续脚本引用的相对路径 (如 scripts/generate_all.dart) 都正确
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR/.."

if [[ ! -x "scripts/build_release.sh" ]]; then
  echo "⚠️  Script is not executable."
  echo "Please run:"
  echo ""
  echo "  chmod +x scripts/build_release.sh"
  echo ""
  echo "Then run:"
  echo ""
  echo "  ./scripts/build_release.sh android"
  echo ""
fi

set -euo pipefail

usage() {
  echo "Usage: scripts/build_release.sh android [--light|--standard|--deep|--no-morph] [--seed <value>] [--anchors <count>] [--touches <count>] [--reshape <level>] [--reshape-profile <mode>] [--no-touch] [--no-asset-morph]"
  echo ""
  echo "Important:"
  echo "  --seed must be followed by a non-empty value, for example:"
  echo "    --seed siren-android-20260720-v1"
  echo ""
  echo "Recommended Android morph build:"
  echo "  ./scripts/build_release.sh android --deep --seed siren-android-20260720-v1 --touches 5 --anchors 32 --reshape 1 --reshape-profile cold-heavy"
  echo ""
  echo "Morph options:"
  echo "  --light / --standard / --deep     Morph intensity. Use --deep for strongest release diffing."
  echo "  --seed <value>                    Deterministic seed. Change it for each release variant."
  echo "  --touches <count>                 Touch call sites per instrumented function. Recommended: 5."
  echo "  --anchors <count>                 Anchor functions per file. Recommended: 32."
  echo "  --reshape <level>                 Wrapper/dispatch depth. Recommended: 1."
  echo "  --reshape-profile <mode>          flat, tiered, or cold-heavy. Recommended: cold-heavy."
  echo "  --no-touch                        Disable method-level touch injection."
  echo "  --no-asset-morph                  Disable assets/images MD5 morphing."
  echo "  --no-morph                        Disable release morph entirely."
  echo ""
  echo "Examples:"
  echo "  ./scripts/build_release.sh android"
  echo "  ./scripts/build_release.sh android --deep"
  echo "  ./scripts/build_release.sh android --deep --seed siren-android-20260720-v1 --touches 5 --anchors 32 --reshape 1 --reshape-profile cold-heavy"
  echo "  ./scripts/build_release.sh android --seed siren-20260720"
  echo "  ./scripts/build_release.sh android --no-morph"
}

PLATFORM="${1:-}"

if [[ -z "$PLATFORM" || "$PLATFORM" == "--help" || "$PLATFORM" == "-h" ]]; then
  usage
  exit 0
fi

shift || true

MORPH_ENABLED="${RELEASE_MORPH:-1}"
MORPH_INTENSITY="${RELEASE_MORPH_INTENSITY:-standard}"
MORPH_SEED="${RELEASE_MORPH_SEED:-siren-release}"
MORPH_ANCHORS="${RELEASE_MORPH_ANCHORS:-}"
MORPH_TOUCHES="${RELEASE_MORPH_TOUCHES:-}"
MORPH_RESHAPE="${RELEASE_MORPH_RESHAPE:-}"
MORPH_RESHAPE_PROFILE="${RELEASE_MORPH_RESHAPE_PROFILE:-}"
MORPH_TOUCH_ENABLED="${RELEASE_MORPH_TOUCH:-1}"
ASSET_MORPH_ENABLED="${RELEASE_ASSET_MORPH:-1}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --light)
      MORPH_INTENSITY="light"
      ;;
    --standard)
      MORPH_INTENSITY="standard"
      ;;
    --deep)
      MORPH_INTENSITY="deep"
      ;;
    --no-morph)
      MORPH_ENABLED="0"
      ;;
    --touches)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --touches"
        exit 1
      fi
      MORPH_TOUCHES="$2"
      shift
      ;;
    --anchors)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --anchors"
        exit 1
      fi
      MORPH_ANCHORS="$2"
      shift
      ;;
    --reshape)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --reshape"
        exit 1
      fi
      MORPH_RESHAPE="$2"
      shift
      ;;
    --reshape-profile)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --reshape-profile"
        exit 1
      fi
      MORPH_RESHAPE_PROFILE="$2"
      shift
      ;;
    --no-touch)
      MORPH_TOUCH_ENABLED="0"
      ;;
    --no-asset-morph)
      ASSET_MORPH_ENABLED="0"
      ;;
    --seed)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --seed"
        exit 1
      fi
      MORPH_SEED="$2"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if [[ -z "$MORPH_SEED" ]]; then
  echo "Error: --seed must not be empty"
  exit 1
fi

for numeric_option in MORPH_TOUCHES MORPH_ANCHORS MORPH_RESHAPE; do
  value="${!numeric_option}"
  if [[ -n "$value" && ! "$value" =~ ^[0-9]+$ ]]; then
    echo "Error: $numeric_option must be a non-negative integer"
    exit 1
  fi
done

case "$PLATFORM" in
  android)
    ;;
  *)
    echo "Unsupported platform: $PLATFORM"
    usage
    exit 1
    ;;
esac

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter not found"
  exit 1
fi

for command_name in dart git zip; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Error: $command_name not found"
    exit 1
  fi
done

if [[ ! -f "pubspec.yaml" ]]; then
  echo "Error: pubspec.yaml not found"
  exit 1
fi

if [[ ! -d "lib" ]]; then
  echo "Error: lib directory not found"
  exit 1
fi

if [[ ! -d "$PLATFORM" ]]; then
  echo "Error: platform directory not found: $PLATFORM"
  exit 1
fi

ASSET_BACKUP_DIR=""
ASSET_RESTORE_PENDING="0"

restore_directory() {
  local source_dir="$1"
  local target_dir="$2"
  local label="$3"
  local staged_dir="${target_dir}.release-restore.$$"

  rm -rf "$staged_dir"
  if ! cp -R "$source_dir" "$staged_dir"; then
    echo "Error: failed to stage $label restore" >&2
    return 1
  fi
  if ! rm -rf "$target_dir" || ! mv "$staged_dir" "$target_dir"; then
    echo "Error: failed to restore $label" >&2
    return 1
  fi
}

cleanup() {
  local status=$?
  trap - EXIT
  set +e
  if [[ "$ASSET_RESTORE_PENDING" == "1" && -n "$ASSET_BACKUP_DIR" ]]; then
    echo "♻️  Restoring assets/images..."
    if ! restore_directory "$ASSET_BACKUP_DIR/images" "assets/images" "assets/images"; then
      status=1
    fi
  fi
  if [[ -n "$ASSET_BACKUP_DIR" ]]; then
    rm -rf "$ASSET_BACKUP_DIR"
  fi
  exit "$status"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

echo "🧹 flutter clean"
flutter clean

echo "📦 flutter pub get"
flutter pub get

echo "🔐 Running consolidated pre-build generator (AES-128-CBC)..."

if [[ -f "scripts/generate_all.dart" ]]; then
  dart run scripts/generate_all.dart --release
else
  echo "⏭️  Optional generator not found, skipping: scripts/generate_all.dart"
fi

echo "🔀 Checking and applying API/data obfuscation..."
if [[ ! -f "scripts/obfuscate_api_data.dart" ]]; then
  echo "Error: required obfuscation script not found: scripts/obfuscate_api_data.dart" >&2
  exit 1
fi
dart run scripts/obfuscate_api_data.dart --check
dart run scripts/obfuscate_api_data.dart --apply

if [[ "$MORPH_ENABLED" == "1" ]]; then
  if [[ -f "scripts/release_morph.dart" ]]; then
    echo "🧬 Running release morph ($MORPH_INTENSITY)..."
    MORPH_MANIFEST="build/release_morph_${PLATFORM}_$(date +%Y%m%d_%H%M%S).json"
    MORPH_ARGS=(
      --root lib \
      --seed "$MORPH_SEED" \
      --intensity "$MORPH_INTENSITY" \
      --manifest "$MORPH_MANIFEST"
    )
    if [[ -n "$MORPH_TOUCHES" ]]; then
      MORPH_ARGS+=(--touches "$MORPH_TOUCHES")
    fi
    if [[ -n "$MORPH_ANCHORS" ]]; then
      MORPH_ARGS+=(--anchors "$MORPH_ANCHORS")
    fi
    if [[ -n "$MORPH_RESHAPE" ]]; then
      MORPH_ARGS+=(--reshape "$MORPH_RESHAPE")
    fi
    if [[ -n "$MORPH_RESHAPE_PROFILE" ]]; then
      MORPH_ARGS+=(--reshape-profile "$MORPH_RESHAPE_PROFILE")
    fi
    if [[ "$MORPH_TOUCH_ENABLED" == "0" ]]; then
      MORPH_ARGS+=(--no-touch)
    fi
    dart run scripts/release_morph.dart "${MORPH_ARGS[@]}"
    flutter analyze --no-fatal-infos --no-fatal-warnings lib
  else
    echo "⏭️  Optional source morph not found, skipping: scripts/release_morph.dart"
  fi

  if [[ "$ASSET_MORPH_ENABLED" == "1" ]]; then
    if [[ ! -f "scripts/release_asset_morph.dart" ]]; then
      echo "⏭️  Optional asset morph not found, skipping: scripts/release_asset_morph.dart"
    elif [[ ! -d "assets/images" ]]; then
      echo "⏭️  Optional asset root not found, skipping: assets/images"
    else
      echo "🖼️  Morphing assets/images MD5 values..."
      ASSET_BACKUP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/siren-release-assets.XXXXXX")
      cp -R "assets/images" "$ASSET_BACKUP_DIR/images"
      ASSET_RESTORE_PENDING="1"
      ASSET_MANIFEST="build/release_assets_${PLATFORM}_$(date +%Y%m%d_%H%M%S).json"
      dart run scripts/release_asset_morph.dart \
        --root assets/images \
        --seed "$MORPH_SEED" \
        --manifest "$ASSET_MANIFEST"
    fi
  else
    echo "⏭️  Asset morph disabled"
  fi
else
  echo "⏭️  Release source and asset morph disabled"
fi


# 读取版本号
VERSION_LINE=$(grep '^version:' pubspec.yaml | awk '{print $2}')
if [[ -z "$VERSION_LINE" || "$VERSION_LINE" != *+* ]]; then
  echo "Error: pubspec.yaml version must use <build-name>+<build-number>"
  exit 1
fi
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

  if [[ ! -f "$AAB_PATH" ]]; then
    echo "Error: Android build output not found: $AAB_PATH"
    exit 1
  fi
  if [[ ! -d "$SYMBOL_DIR" || -z "$(find "$SYMBOL_DIR" -type f -print -quit)" ]]; then
    echo "Error: Android symbol files not found: $SYMBOL_DIR"
    exit 1
  fi

  cp "$AAB_PATH" "$RELEASE_DIR/app.aab"

  cp -r "$SYMBOL_DIR" "$RELEASE_DIR/symbols"

  generate_changelog "$RELEASE_DIR"

  cd "$RELEASE_BASE"
  zip -r "android_${VERSION_TAG}.zip" "android_${VERSION_TAG}" >/dev/null
  cd - >/dev/null

  echo "📦 Android package:"
  echo "$RELEASE_BASE/android_${VERSION_TAG}.zip"
}

case "$PLATFORM" in
  android)
    build_android
    ;;
  *)
    echo "Unsupported platform: $PLATFORM"
    exit 1
    ;;
esac

echo ""
echo "✅ Build completed"
echo "ℹ️  Generated lib source changes were kept for manual comparison and restoration"
