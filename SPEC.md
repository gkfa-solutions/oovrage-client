# SPEC — plugin oovrage-client

**Date** : 2026-10-19 — **Statut** : cadrée (piste A vérifiée le 2026-10-19)

## Le besoin

Aujourd'hui, le client parle au Correspondant en ajoutant un connecteur personnalisé dans claude.ai, avec
une adresse par projet (`https://<plateforme>/mcp/<slug>`). Quand un client a plusieurs projets, il a
plusieurs connecteurs aux outils identiques (mêmes noms, descriptions qui ne nomment pas le projet) :
Claude peut se tromper de projet ou n'en appeler aucun, et le client ne sait pas quoi dire pour déclencher
un geste (dépôt d'un ticket, revue, vote…).

Idée retenue : un plugin Claude Code à part, **oovrage-client**, que le client installe une fois. Il
travaille dans un dossier par projet ; un fichier de config dans ce dossier dit de quel projet il s'agit.

## Ce que fait le plugin

- Un skill `/oovrage-client:correspondant` que le client lance dans le dossier de son choix.
  - Dossier **sans** fichier de config : le skill demande le projet (adresse de la plateforme + projet),
    puis écrit le fichier de config. C'est le **seul fichier** que le plugin a le droit de créer.
  - Avant tout, le skill vérifie le dossier (son chemin, et son contenu par `Glob`). Dossier général de
    l'ordinateur (racine, dossier personnel, Bureau, Documents, Téléchargements, dossier du système) ou
    dossier d'un projet en cours (`.git`, `_projet`, `package.json`, `src`, fichiers de travail…). Le
    skill juge, il ne coche pas une liste : ce que le plugin et Claude Code créent eux-mêmes
    (`.oovrage-client.json`, `.claude/settings.local.json`, `.DS_Store`…) ne compte pas, un ou deux
    documents posés par la personne non plus, et un dossier qui va bien passe sans un mot.
    Sinon : il avertit, n'y écrit rien, propose un nouveau dossier (`~/oovrage/<projet>` pour un dossier
    général, `<projet>-oovrage` à côté pour un projet en cours), y écrit le fichier de config
    avec l'accord de la personne, et lui demande de relancer Claude Code dedans. Si le fichier de config
    est déjà dans un tel dossier, le garde-fou empêche d'écrire ailleurs : le skill demande à la personne
    de déplacer le fichier elle-même.
  - Dossier **avec** fichier de config : le skill lit le projet, appelle `accueil`, et la conversation
    démarre sur ce projet.
  - Spec de bloc à valider qui pose des questions (au plus quatre, chacune avec notre recommandation) :
    `accueil` et `questions_en_attente` en donnent le nombre (`propositions_a_valider[].questions`), `lire`
    les rend (`questions`, `questions_note`). Le skill annonce ce nombre, montre chaque question avec notre
    recommandation, propose d'y répondre une par une par `commenter` avec `question` = son numéro (après
    l'accord de la personne, comme tout geste), et dit que valider sans répondre accepte nos
    recommandations. Une réponse qui s'écarte de la recommandation fait réécrire la spec, republiée à
    valider.
- Le plugin embarque son connecteur MCP (déclaré dans le plugin, pas à ajouter à la main).
- Interdiction de créer, modifier ou supprimer tout autre fichier : un garde-fou (hook `PreToolUse` sur
  Write / Edit / NotebookEdit et sur les commandes shell qui écrivent) bloque tout le reste.
  - **Le garde-fou n'agit que dans un dossier qui contient le fichier de config.** Ailleurs, il ne fait
    rien : le propriétaire a aussi le plugin `oovrage` (pilote) et ne doit jamais être bloqué dans son
    travail de pilote.

## Le fichier de config

Nom proposé : `.oovrage-client.json` (jamais `_projet/`, `_suivi.yaml`, `.claude/` ni rien que le plugin
`oovrage` reconnaît comme un projet piloté). Contenu proposé :

```json
{ "plateforme": "https://plateforme.example", "projet": "atlas" }
```

Aucun jeton dedans : la connexion est gardée par Claude Code dans son propre stockage, hors du dossier.

## Changements côté plateforme (dépôt `oovrage`, `apps/platform`)

1. **Adresse unique** `/mcp` (en plus de `/mcp/<slug>`, qui reste pour claude.ai). Le projet n'est plus dans
   l'adresse : il arrive avec chaque requête.
   - Piste A : un en-tête (ex. `X-Oovrage-Projet`) que Claude Code construit depuis le fichier de config.
     **À vérifier en premier** : Claude Code sait-il ajouter à un serveur MCP de plugin un en-tête calculé
     à partir du dossier courant (variable d'environnement, `headersHelper` ou équivalent) ?
   - Piste B, de repli : chaque outil prend un argument `projet` ; le skill le lit dans le fichier de config
     et consigne à Claude de le passer à chaque appel.
   - **Résultat de l'essai (2026-10-19, Claude Code 2.1.303) : piste A retenue.** Syntaxe qui marche dans
     le `.mcp.json` du plugin :
     `"headersHelper": "${CLAUDE_PLUGIN_ROOT}/bin/entete-projet \"${CLAUDE_PROJECT_DIR}\""`.
     `${CLAUDE_PROJECT_DIR}` est remplacé par Claude Code dans la config (le helper reçoit le chemin du
     dossier de la session en `$1`) ; la variable n'est pas dans l'environnement du helper, et le helper
     tourne dans le dossier du plugin (son `pwd` ne sert donc pas). L'en-tête part sur chaque requête,
     y compris celles de découverte OAuth (`/.well-known/…`, `/register`) : sans effet.
   - Décisions prises par le plan : nom du skill `correspondant` ; nom du serveur MCP `oovrage-client` (pas `correspondant`, qui se
     confondait avec un ancien connecteur du même nom chez le client) ; adresse du connecteur
     `https://app.oovrage.fr/mcp`, en dur (une adresse variable empêchait la connexion depuis
     `/mcp` dans l'application de bureau : « points at a different server URL ») ; sans en-tête, `/mcp` répond
     `400 projet_absent` ; projet inconnu ou dont la personne n'est pas membre : `403 projet_refuse`
     (même message) ; portée OAuth `correspondant`, ressource `<origine>/mcp` ; dans un dossier client,
     **toute** commande shell est bloquée (reconnaître sûrement une commande qui écrit est impossible, et
     le client n'en a pas besoin).
2. **Jeton lié à la personne**, plus au projet : aujourd'hui `resolveMcpToken(token, slug)`
   (`src/lib/correspondant/auth.ts`) refuse un jeton d'un autre projet. Avec l'adresse unique, le jeton
   porte l'email ; à chaque requête la plateforme vérifie que la personne est membre du projet demandé, puis
   résout l'instance comme aujourd'hui. Les métadonnées OAuth (`resource`, `scope`) suivent l'adresse unique.
3. **Connexion depuis Claude Code** : le code accepte déjà la boucle locale (`OAUTH_ALLOW_LOOPBACK=1`,
   `src/lib/oauth/config.ts`), coupée en production. L'allumer en production est un geste de production :
   montrer la commande exacte et attendre le go du propriétaire.

La porte du corpus, les portées (dont `code`), les gestes, le journal et l'accord avant écriture restent
ceux d'aujourd'hui : rien ne change dans les droits.

## Compatibilité avec le plugin `oovrage`

- Plugin à part, sans dépendance au plugin `oovrage` ; son code vit dans ce dépôt (`oovrage-client`). Pour la marketplace : soit
  une source qui pointe vers ce dépôt git, soit une marketplace propre à ce dépôt. Tranché : **une marketplace propre à ce dépôt**
  (`.claude-plugin/marketplace.json`, source `./`) ; installation par
  `/plugin marketplace add gkfa-solutions/oovrage-client` puis `/plugin install oovrage-client@oovrage-client`.
  Une entrée dans la marketplace de `oovrage` écrirait le compte GitHub de la société dans ce dépôt-là, ce
  que son test d'anonymat refuse.
- Préfixes séparés : les commandes sont `/oovrage-client:…`, aucune collision avec `/oovrage:…`.
- Le garde-fou ne s'active que là où il y a `.oovrage-client.json` (voir plus haut).
- Rien de nouveau dans le plugin `oovrage` : le pilote continue de gérer les instances par
  `oovrage correspondant`.

## Limites connues

- Le client doit avoir Claude Code, ou l'application de bureau en mode Cowork (à vérifier : plugins et
  connecteur distant y fonctionnent-ils ?). Il perd l'usage depuis claude.ai web et mobile ; le connecteur
  claude.ai reste disponible pour ceux qui le préfèrent.
- Le code lu reste l'instantané publié à la mise en prod (`oovrage code publier`), pas le dépôt.

## Règles du dépôt

- **Aucun nom réel** de client, de projet ou de personne : exemples sur des noms fictifs (atlas, bistro,
  cobalt, ember, fjord…).
- Pas d'estimation de temps ; arbitrer par valeur, complexité et sûreté.
- Vérifier par des tests automatisés, et par un scénario sur un projet d'essai jetable.

## Ordre proposé

1. Essai : un plugin minimal qui déclare un serveur MCP HTTP et tente la piste A (en-tête depuis le dossier).
   Le résultat tranche entre A et B.
2. Plateforme : adresse `/mcp` unique, jeton lié à la personne, tests.
3. Plugin : skill `/correspondant`, fichier de config, garde-fou, tests.
4. Scénario de bout en bout sur un projet d'essai (cobalt), boucle locale allumée en local seulement.
   **Joué le 2026-10-19 en local** : écran de consentement « Correspondant Oovrage pour tous tes projets »
   (cobalt, hôte de retour `127.0.0.1:33418`) ; ancien écran `/mcp/cobalt` inchangé ; flux OAuth en boucle
   locale jusqu'au jeton (`api_tokens` kind `mcp`, `project_slug` NULL) ; `accueil` sur `/mcp` avec
   `X-Oovrage-Projet: cobalt` (journal `correspondant_journal` : `accueil`, `ok`) ; sans en-tête → 400,
   autre projet → 403 ; le skill crée seul `.oovrage-client.json` ; dans ce dossier, `Write notes.md` et
   `ls` sont refusés par le garde-fou ; ailleurs, l'écriture passe. Claude Code atteint `/mcp` avec l'en-tête
   et l'adresse tirée de `OOVRAGE_PLATEFORME`. Défauts trouvés et corrigés : `/mcp` renvoyé vers `/sign-in`
   par le proxy de la plateforme ; entrée de marketplace dans `oovrage` refusée par son test d'anonymat
   (marketplace propre à ce dépôt). Non joué : la connexion `/mcp` dans une session interactive
   (`docs/suivi/DETTE.md`).
5. Go du propriétaire pour la production.
