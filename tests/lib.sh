# Petite bibliothèque de tests en bash pur (aucune dépendance chez le client).
# Usage : `. tests/lib.sh`, puis `ok "nom"` / `ko "nom" "détail"`, `egal`, et `fin` en dernier.

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REUSSIS=0
ECHECS=0

ok() {
  REUSSIS=$((REUSSIS + 1))
}

ko() {
  ECHECS=$((ECHECS + 1))
  printf 'ÉCHEC : %s\n' "$1" >&2
  [ -n "${2:-}" ] && printf '  %s\n' "$2" >&2
  return 0
}

# egal <nom> <attendu> <obtenu>
egal() {
  if [ "$2" = "$3" ]; then ok "$1"; else ko "$1" "attendu [$2], obtenu [$3]"; fi
}

fin() {
  printf '%s : %d réussis, %d échecs\n' "$(basename "$0")" "$REUSSIS" "$ECHECS"
  [ "$ECHECS" -eq 0 ]
}
