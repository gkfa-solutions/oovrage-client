#!/bin/bash
# scripts/entete-projet : en-tête X-Oovrage-Projet calculé depuis .oovrage-client.json.
. "$(dirname "$0")/lib.sh"
E="$RACINE/scripts/entete-projet"

# cas <nom> <contenu du fichier ou __AUCUN__> <sortie attendue>
cas() {
  local d sortie code
  d="$(mktemp -d)"
  [ "$2" != "__AUCUN__" ] && printf '%s' "$2" > "$d/.oovrage-client.json"
  sortie="$(bash "$E" "$d" 2>/dev/null)"
  code=$?
  egal "$1" "$3" "$sortie"
  egal "$1 (code 0)" "0" "$code"
  rm -rf "$d"
}

cas "sans fichier" "__AUCUN__" '{}'
cas "fichier valide" '{"plateforme":"https://plateforme.example","projet":"atlas"}' '{"X-Oovrage-Projet":"atlas"}'
cas "plusieurs lignes, espaces" '{
  "plateforme" : "https://plateforme.example",
  "projet"  :   "atlas"
}' '{"X-Oovrage-Projet":"atlas"}'
cas "slug avec tiret" '{"projet":"cobalt-2"}' '{"X-Oovrage-Projet":"cobalt-2"}'
cas "chemin relatif" '{"projet":"../atlas"}' '{}'
cas "majuscule" '{"projet":"Atlas"}' '{}'
cas "projet absent" '{"plateforme":"https://plateforme.example"}' '{}'
cas "fichier vide" '' '{}'
cas "JSON cassé" '{"projet":"atl' '{}'
cas "deux champs projet" '{"projet":"atlas","projet":"bistro"}' '{}'
cas "guillemet injecté" '{"projet":"atlas\",\"X":"y"}' '{}'

# Sans argument : le dossier courant.
d="$(mktemp -d)"
printf '%s' '{"projet":"bistro"}' > "$d/.oovrage-client.json"
egal "sans argument : dossier courant" '{"X-Oovrage-Projet":"bistro"}' "$(cd "$d" && bash "$E")"
rm -rf "$d"

# Argument vide ou laissé tel quel (variable non développée) : CLAUDE_PROJECT_DIR, puis le dossier courant.
d="$(mktemp -d)"
printf '%s' '{"projet":"cobalt"}' > "$d/.oovrage-client.json"
egal "argument vide : CLAUDE_PROJECT_DIR" '{"X-Oovrage-Projet":"cobalt"}' "$(cd / && CLAUDE_PROJECT_DIR="$d" bash "$E" "")"
egal "argument non développé : CLAUDE_PROJECT_DIR" '{"X-Oovrage-Projet":"cobalt"}' "$(cd / && CLAUDE_PROJECT_DIR="$d" bash "$E" '${CLAUDE_PROJECT_DIR}')"
egal "argument non développé, sans variable : dossier courant" '{"X-Oovrage-Projet":"cobalt"}' "$(cd "$d" && env -u CLAUDE_PROJECT_DIR bash "$E" '${CLAUDE_PROJECT_DIR}')"
rm -rf "$d"

fin
