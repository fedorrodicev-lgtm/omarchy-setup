#!/bin/bash
# Ставит сетап поверх Omarchy: копирует config/ в ~/.config, заменённые файлы
# сохраняет в ~/.config/dotfiles-backup-<время>, затем применяет тему.

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

[[ -d $BACKUP ]] && echo "Старые файлы сохранены в $BACKUP"

omarchy theme set ferrari
omarchy restart shell
hyprctl reload >/dev/null && hyprctl configerrors
echo "Готово. Терминалы foot подхватят прозрачность в новых окнах."
