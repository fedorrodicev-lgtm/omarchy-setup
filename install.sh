#!/bin/bash
# Installs the setup on top of Omarchy: copies config/ into ~/.config and bin/
# into ~/.local/bin, saves replaced files to ~/.config/dotfiles-backup-<time>,
# then applies the theme.

set -euo pipefail
REPO="$(dirname "$(readlink -f "$0")")"
DST="$HOME/.config"
BACKUP="$DST/dotfiles-backup-$(date +%s)"

cd "$REPO/config"
while IFS= read -r -d '' f; do
  f="${f#./}"
  if [[ -e "$DST/$f" ]] && ! cmp -s "$f" "$DST/$f"; then
    install -Dm644 "$DST/$f" "$BACKUP/$f"
  fi
  install -D -m "$(stat -c %a "$f")" "$f" "$DST/$f"
done < <(find . -type f -print0)

for b in "$REPO"/bin/*; do
  dst="$HOME/.local/bin/$(basename "$b")"
  if [[ -e $dst ]] && ! cmp -s "$b" "$dst"; then
    install -Dm755 "$dst" "$BACKUP/local-bin/$(basename "$b")"
  fi
  install -Dm755 "$b" "$dst"
done

[[ -d $BACKUP ]] && echo "Old files saved to $BACKUP"

omarchy theme set ferrari
omarchy restart shell
hyprctl reload >/dev/null && hyprctl configerrors
echo "Done. foot terminals pick up the transparency in new windows."
