#!/bin/bash
# Ставит сетап поверх Omarchy: копирует config/ в ~/.config и bin/ в ~/.local/bin,
# заменённые файлы сохраняет в ~/.config/dotfiles-backup-<время>, затем
# применяет тему.

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

[[ -d $BACKUP ]] && echo "Старые файлы сохранены в $BACKUP"

omarchy theme set ferrari
omarchy restart shell
hyprctl reload >/dev/null && hyprctl configerrors
echo "Готово. Терминалы foot подхватят прозрачность в новых окнах."
