#!/bin/bash
# Копирует живые конфиги из ~/.config в репо. Запускай перед коммитом.
# Список файлов — белый: всё, чего здесь нет, в репо не попадает.

set -euo pipefail
REPO="$(dirname "$(readlink -f "$0")")"
SRC="$HOME/.config"

FILES=(
  hypr/bindings.lua
  hypr/input.lua
  hypr/looknfeel.lua
  foot/foot.ini
  omarchy/shell.json
  omarchy/shell.toml
)
DIRS=(
  omarchy/themes/ferrari
  omarchy/plugins/fedor.bar
  omarchy/plugins/fedor.tray
  omarchy/plugins/fedor.indicators
  omarchy/plugins/fedor.f1
  omarchy/plugins/fedor.f1-next
  omarchy/plugins/fedor.music
  omarchy/plugins/fedor.network
)
# Скрипты из ~/.local/bin — попадают в bin/.
BINS=(
  screenshot-window-mac
)
# Обои Монако-2024 (11–14) без свободной лицензии — только для личного пользования.
EXCLUDE=(--exclude='*.bak.*' --exclude='backgrounds/1[1-4]-*')

for f in "${FILES[@]}"; do
  install -Dm644 "$SRC/$f" "$REPO/config/$f"
done
for d in "${DIRS[@]}"; do
  mkdir -p "$REPO/config/$d"
  rsync -a --delete "${EXCLUDE[@]}" "$SRC/$d/" "$REPO/config/$d/"
done
for b in "${BINS[@]}"; do
  install -Dm755 "$HOME/.local/bin/$b" "$REPO/bin/$b"
done

# EXIF/XMP фотографов (имена, почты, адреса, серийники камер) не публикуем —
# оставляем только цветовой профиль. jpegtran пересобирает без потери качества.
for jpg in "$REPO"/config/omarchy/themes/*/backgrounds/*.jpg; do
  jpegtran -copy icc -optimize -outfile "$jpg.tmp" "$jpg"
  touch -r "$jpg" "$jpg.tmp" && mv "$jpg.tmp" "$jpg"
done

echo "Синхронизировано. Проверь: git -C '$REPO' status && git -C '$REPO' diff"
