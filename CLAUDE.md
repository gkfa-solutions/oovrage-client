# CLAUDE.md — oovrage-client

Plugin Claude Code que les **clients** installent pour parler au Correspondant d'un projet oovrage.
Lis d'abord `SPEC.md` : le besoin, les choix déjà faits et l'ordre de travail.

## Contexte

- Dépôt principal : `../oovrage` (plugin pilote `plugins/oovrage/plugin`, plateforme `apps/platform`).
  Avant de toucher la plateforme, lis `../oovrage/CLAUDE.md`, `../oovrage/_meta/ETAT.md` et
  `../oovrage/apps/platform/docs/CORRESPONDANT_MCP.md`.
- Les changements de plateforme se font dans `../oovrage`, sur une branche de ce dépôt-là ; ce dépôt-ci ne
  contient que le plugin client.

## Règles non négociables

- **Aucun nom réel** de client, de projet ou de personne : code, commentaires, tests, docs. Noms fictifs
  seulement (atlas, bistro, cobalt, ember, fjord…).
- Le plugin ne crée **qu'un seul fichier** : `.oovrage-client.json` dans le dossier où le client le lance.
- Le garde-fou n'agit **que** dans un dossier qui contient `.oovrage-client.json`.
- **Pas d'estimation de temps.** Critères : valeur, complexité, sûreté.
- **Vérifier par les tests**, puis par un scénario sur un projet d'essai jetable.
- Avant tout geste de production (base, déploiement, domaine, réglage comme `OAUTH_ALLOW_LOOPBACK`) :
  montrer la commande exacte et attendre le go.

## Première étape

Point 1 de l'ordre de `SPEC.md` : vérifier si Claude Code sait ajouter à un serveur MCP de plugin un
en-tête calculé depuis le dossier courant. Le résultat tranche entre la piste A et la piste B ; mets-le à
jour dans `SPEC.md` avant d'aller plus loin.
