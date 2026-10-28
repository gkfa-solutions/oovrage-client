#!/bin/bash
# skills/correspondant/SKILL.md et README.md : présents, frontmatter, consignes clés,
# et aucun nom réel dans le dépôt (empreintes partagées avec le dépôt oovrage).
. "$(dirname "$0")/lib.sh"
S="$RACINE/skills/correspondant/SKILL.md"

if [ -f "$S" ]; then ok "skill présent"; else ko "skill présent" "$S absent"; fi
egal "frontmatter : name" "name: correspondant" "$(sed -n '2,6p' "$S" 2>/dev/null | grep '^name:')"
if sed -n '2,6p' "$S" 2>/dev/null | grep -q '^description: .'; then ok "description"; else ko "description" "absente"; fi
for mot in ".oovrage-client.json" "accueil" "l'argument \`projet\`" "/mcp" "Write" "projet_refuse" "plugin:oovrage-client:correspondant" \
  "propositions_a_valider" "questions_en_attente" "lire" "recommandation" "commenter" "\`question\`" \
  "valider la spec sans répondre, c'est accepter nos recommandations" \
  "Vérifier le dossier" "Glob" "Dossier général" "Projet en cours" "<projet>-oovrage" "oovrage/<projet>" \
  "relancez Claude" "n'écris rien dans le dossier courant" \
  "Juge le dossier" ".claude/settings.local.json" ".DS_Store" "n'en parle pas et continue" \
  "show_widget" "reprendre" "À faire pour vous" "Depuis votre dernière visite" "Le projet" "sendPrompt" \
  "livraisons_recentes" "lien_plateforme" \
  "mes_projets" "Ne demande jamais le nom court" "phrase complète" "jamais une lettre seule" \
  "Enchaîner" "Ne demande pas « Voulez-vous continuer ? »"; do
  if grep -qF -- "$mot" "$S" 2>/dev/null; then ok "skill mentionne $mot"; else ko "skill mentionne $mot"; fi
done
if grep -qF "https://app.oovrage.fr" "$S" 2>/dev/null; then ok "adresse par défaut"; else ko "adresse par défaut"; fi

R="$RACINE/README.md"
ORG="$(git -C "$RACINE" remote get-url origin 2>/dev/null | sed -n 's#.*github\.com[:/]\([^/]*\)/.*#\1#p')"
for mot in "/plugin marketplace add $ORG/oovrage-client" "/plugin install oovrage-client@oovrage-client" "/oovrage-client:correspondant" "/mcp" "Valider la spec sans répondre" "refuse d'y travailler"; do
  if grep -qF -- "$mot" "$R" 2>/dev/null; then ok "README mentionne $mot"; else ko "README mentionne $mot"; fi
done

# Anonymat : la liste d'empreintes du dépôt oovrage, appliquée à ce dépôt-ci. Seule
# exception : le compte GitHub du dépôt (`<compte>/…`), sans lequel le client ne peut pas
# installer le plugin ; il est lu dans le remote, jamais écrit ici.
A="$RACINE/../oovrage/plugins/oovrage/plugin/scripts/tests/test_anonymat.py"
if [ -f "$A" ] && command -v python3 > /dev/null; then
  trouves="$(python3 - "$A" "$RACINE" "$ORG" <<'PY'
import importlib.util, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("anonymat", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
racine = Path(sys.argv[2])
org = sys.argv[3]
for f in sorted(racine.rglob("*")):
    if not f.is_file() or m.IGNORES.intersection(f.parts) or ".superpowers" in f.parts:
        continue
    try:
        lignes = f.read_text(encoding="utf-8").splitlines()
    except (UnicodeDecodeError, OSError):
        continue
    for n, ligne in enumerate(lignes, 1):
        if org:
            ligne = ligne.replace(org + "/", "")
        if any(m.empreinte(c) in m.INTERDITS for c in m.candidats(ligne)):
            print(f"{f.relative_to(racine)}:{n}")
PY
)"
  egal "aucun nom réel" "" "$trouves"
else
  printf 'test-skill.sh : liste d'"'"'empreintes du dépôt oovrage introuvable, anonymat non vérifié\n' >&2
fi

fin
