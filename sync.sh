#!/bin/bash
# Copies live configs from ~/.config into the repo. Run before committing.
# The lists below are a whitelist: anything not listed stays out of the repo.

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
# Scripts from ~/.local/bin, copied into bin/.
BINS=(
  screenshot-window-mac
  gpu-screen-recorder
)
# The Monaco 2024 wallpapers (11–14) aren't freely licensed: personal use only.
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

# Don't publish photographers' EXIF/XMP (names, emails, addresses, camera
# serials): keep only the color profile. jpegtran rewrites the file losslessly.
for jpg in "$REPO"/config/omarchy/themes/*/backgrounds/*.jpg; do
  jpegtran -copy icc -optimize -outfile "$jpg.tmp" "$jpg"
  touch -r "$jpg" "$jpg.tmp" && mv "$jpg.tmp" "$jpg"
done

echo "Synced. Review with: git -C '$REPO' status && git -C '$REPO' diff"
