#!/bin/bash
# hooks/garde-fou : dans un dossier client (qui contient .oovrage-client.json),
# seul ce fichier peut être écrit ; ailleurs, rien n'est bloqué.
. "$(dirname "$0")/lib.sh"
G="$RACINE/hooks/garde-fou"
MESSAGE="Dossier client Oovrage : seul .oovrage-client.json peut être écrit ici. Le Correspondant agit par ses outils, pas par des fichiers."

# entree <outil> <champ tool_input en JSON> <cwd>
entree() {
  printf '{"session_id":"s1","transcript_path":"/tmp/t.jsonl","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":%s}' "$3" "$1" "$2"
}

# verifie <nom> <code attendu> <dossier projet (CLAUDE_PROJECT_DIR)> <outil> <tool_input> <cwd>
#   ou   <nom> <code attendu> <dossier projet> <entrée brute>
# (le JSON se construit ici : bash 3.2 développe les accolades d'un `"$(…"{a,b}"…)"`.)
verifie() {
  local out err code json
  if [ $# -eq 6 ]; then json="$(entree "$4" "$5" "$6")"; else json="$4"; fi
  out="$(mktemp)"; err="$(mktemp)"
  printf '%s' "$json" | CLAUDE_PROJECT_DIR="$3" bash "$G" > "$out" 2> "$err"
  code=$?
  egal "$1 (code)" "$2" "$code"
  if [ "$2" = 0 ]; then
    egal "$1 (muet)" "" "$(cat "$out" "$err")"
  else
    egal "$1 (message)" "$MESSAGE" "$(cat "$err")"
  fi
  rm -f "$out" "$err"
}

libre="$(mktemp -d)"
client="$(mktemp -d)"
autre="$(mktemp -d)"
casse="$(mktemp -d)"
printf '%s' '{"plateforme":"https://plateforme.example","projet":"atlas"}' > "$client/.oovrage-client.json"
printf '%s' '{"plateforme":"https://plateforme.example","projet":"bistro"}' > "$autre/.oovrage-client.json"
printf '%s' '{"projet":' > "$casse/.oovrage-client.json"

# Hors dossier client : jamais bloqué, jamais un mot.
verifie "libre : Write" 0 "$libre" Write "{\"file_path\":\"$libre/x.md\",\"content\":\"a\"}" "$libre"
verifie "libre : Bash rm" 0 "$libre" Bash '{"command":"rm -rf x"}' "$libre"
verifie "libre : JSON illisible" 0 "$libre" "pas du json"

# Dossier client : seul le fichier de config, par son chemin absolu exact.
verifie "client : Write config" 0 "$client" Write "{\"file_path\":\"$client/.oovrage-client.json\",\"content\":\"{}\"}" "$client"
verifie "client : Edit config" 0 "$client" Edit "{\"file_path\":\"$client/.oovrage-client.json\",\"old_string\":\"a\",\"new_string\":\"b\"}" "$client"
verifie "client : MultiEdit config" 0 "$client" MultiEdit "{\"file_path\":\"$client/.oovrage-client.json\",\"edits\":[]}" "$client"

verifie "client : Write notes.md" 2 "$client" Write "{\"file_path\":\"$client/notes.md\",\"content\":\"a\"}" "$client"
verifie "client : Edit sous/config" 2 "$client" Edit "{\"file_path\":\"$client/sous/.oovrage-client.json\",\"old_string\":\"a\",\"new_string\":\"b\"}" "$client"
verifie "client : Write config d'un autre dossier" 2 "$client" Write "{\"file_path\":\"$autre/.oovrage-client.json\",\"content\":\"{}\"}" "$client"
verifie "client : Write ../autre/config" 2 "$client" Write "{\"file_path\":\"$client/../$(basename "$autre")/.oovrage-client.json\",\"content\":\"{}\"}" "$client"
verifie "client : Write config relatif" 2 "$client" Write '{"file_path":".oovrage-client.json","content":"{}"}' "$client"
verifie "client : Edit ./config" 2 "$client" Edit '{"file_path":"./.oovrage-client.json","old_string":"a","new_string":"b"}' "$client"
verifie "client : NotebookEdit" 2 "$client" NotebookEdit "{\"notebook_path\":\"$client/n.ipynb\",\"new_source\":\"x\"}" "$client"
verifie "client : Bash ls" 2 "$client" Bash '{"command":"ls"}' "$client"
verifie "client : Bash echo > y" 2 "$client" Bash '{"command":"echo x > y"}' "$client"
verifie "client : JSON illisible" 2 "$client" "pas du json"
verifie "client : deux file_path" 2 "$client" Write "{\"file_path\":\"$client/.oovrage-client.json\",\"file_path\":\"$client/x\"}" "$client"
verifie "client : contenu qui imite file_path" 2 "$client" Write "{\"file_path\":\"$client/notes.md\",\"content\":\"\\\"file_path\\\":\\\"$client/.oovrage-client.json\\\"\"}" "$client"

# Config au contenu cassé : le dossier reste un dossier client.
verifie "casse : Write notes.md" 2 "$casse" Write "{\"file_path\":\"$casse/notes.md\",\"content\":\"a\"}" "$casse"

# CLAUDE_PROJECT_DIR vide : le cwd du JSON.
verifie "sans CLAUDE_PROJECT_DIR : cwd client" 2 "" Write '{"file_path":"notes.md","content":"a"}' "$client"
verifie "sans CLAUDE_PROJECT_DIR : cwd libre" 0 "" Write "{\"file_path\":\"$libre/x.md\",\"content\":\"a\"}" "$libre"

rm -rf "$libre" "$client" "$autre" "$casse"
fin
