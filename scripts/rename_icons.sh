#!/bin/bash

#  给权限
# chmod +x rename_icons.sh
# 用法: ./rename_icons.sh /path/to/your/folder

set -euo pipefail

DIR="$1"

if [ -z "$DIR" ]; then
  echo "❌ 请传入目录路径"
  echo "👉 用法: ./rename_icons.sh /你的路径"
  exit 1
fi

if [ ! -d "$DIR" ]; then
  echo "❌ 目录不存在: $DIR"
  exit 1
fi

echo "🚀 开始处理目录: $DIR"

cd "$DIR" || exit

shopt -s nullglob

processed=0

for file in *.{png,svg,jpg,jpeg,webp}; do
  [ -e "$file" ] || continue

  ext="${file##*.}"
  base="${file%.*}"
  ext_lower=$(printf '%s' "$ext" | tr 'A-Z' 'a-z')

  normalized_base=$(printf '%s' "$base" | tr 'A-Z' 'a-z')

  if printf '%s' "$normalized_base" | grep -Eq '^property[ _-]*1([ _-]*=|_)'; then
    new_base=$(printf '%s' "$normalized_base" \
      | sed -E '
        s/@[23]x//g;
        s/^property[ _-]*1[[:space:]]*=[[:space:]]*//;
        s/^property[ _-]*1_//;
        s/[[:space:]]*,[[:space:]]*property[ _-]*2[[:space:]]*=[[:space:]]*/_/;
        s/_property[ _-]*2_/_/g;
        s/[[:space:]]*,[[:space:]]*property[ _-]*[0-9]+[[:space:]]*=[[:space:]]*/_/g;
        s/_property[ _-]*[0-9]+_/_/g;
        s/[[:space:],=-]+/_/g;
        s/_+/_/g;
        s/^_+|_+$//g
      ')
  else
    new_base=$(printf '%s' "$base" \
      | sed -E 's/@[23]x//g; s/[[:space:]]*=[[:space:]]*/_/g; s/[[:space:],-]+/_/g; s/_+/_/g; s/^_+|_+$//g' \
      | tr 'A-Z' 'a-z')
  fi

  new_name="${new_base}.${ext_lower}"

  if [ "$file" != "$new_name" ]; then
    target="$new_name"
    count=1

    while [ -e "$target" ]; do
      target="${new_base}_${count}.${ext_lower}"
      count=$((count + 1))
    done

    echo "🔄 $file -> $target"
    mv "$file" "$target"
    processed=$((processed + 1))
  fi
done

if [ "$processed" -eq 0 ]; then
  echo "ℹ️ 没有发现需要重命名的图片文件"
fi

echo "✅ 处理完成"
