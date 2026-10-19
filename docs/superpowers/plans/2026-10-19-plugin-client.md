# Plugin oovrage-client — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** un client lance `/oovrage-client:correspondant` dans un dossier par projet et parle au Correspondant de ce projet, sans pouvoir écrire autre chose que `.oovrage-client.json`.

**Architecture:** la plateforme ajoute une adresse unique `/mcp` dont le jeton OAuth est lié à la personne (plus au projet) ; le projet arrive à chaque requête dans l'en-tête `X-Oovrage-Projet` (piste A). Le plugin déclare ce serveur MCP avec un `headersHelper` qui lit `.oovrage-client.json` dans le dossier de la session, un skill qui crée ce fichier ou démarre la conversation, et un hook `PreToolUse` qui bloque toute écriture dans un dossier client.

**Tech Stack:** plateforme Next.js 16 + drizzle + vitest/PGlite (`../oovrage/apps/platform`) ; plugin Claude Code en bash pur (aucune dépendance chez le client : ni jq, ni node, ni python).

**Spec:** `SPEC.md` (ce dépôt). Lire aussi `CLAUDE.md` (ce dépôt), `../oovrage/CLAUDE.md`, `../oovrage/apps/platform/docs/CORRESPONDANT_MCP.md`.

## Global Constraints

- **Aucun nom réel** de client, de projet ou de personne : noms fictifs seulement (atlas, bistro, cobalt, ember, fjord…). `test_anonymat.py` du dépôt `oovrage` le vérifie.
- Le plugin ne crée **qu'un seul fichier** : `.oovrage-client.json` dans le dossier où le client le lance. Contenu : `{ "plateforme": "https://…", "projet": "<slug>" }`, **aucun jeton**.
- Le garde-fou n'agit **que** dans un dossier qui contient `.oovrage-client.json` ; ailleurs il sort en 0 sans rien faire.
- `/mcp/<slug>` reste tel quel pour claude.ai : ses tests existants (`correspondant-mcp.test.ts`) doivent rester verts sans modification.
- Rien ne change dans les droits : porte du corpus, portées (dont `code`), gestes, journal, accord avant écriture.
- Rien de nouveau dans le plugin `oovrage` (pilote).
- Pas d'estimation de temps.
- `OAUTH_ALLOW_LOOPBACK=1` : seulement dans `../oovrage/apps/platform/.env.local`. En production : montrer la commande exacte et attendre le go (tâche 7). Aucun déploiement, aucune migration en production dans ce plan.
- Git : dans `../oovrage`, branche `feature/mcp-adresse-unique` depuis `develop`, PR vers `develop` (jamais vers `main`). `../oovrage` a des modifications non commitées (`_meta/ETAT.md`, `plugins/oovrage/plugin/.claude-plugin/plugin.json`) qui ne sont pas à toi : ne les commite pas, ne les annule pas. Dans ce dépôt (`oovrage-client`, aucun commit encore) : premier commit de `CLAUDE.md` + `SPEC.md` + ce plan sur `main`, création de `develop` depuis `main`, puis branche `feature/plugin-client` depuis `develop`, PR vers `develop` ; aucune PR vers `main`.
- Après tout changement du contrat MCP/OAuth : mettre à jour `../oovrage/apps/platform/docs/CORRESPONDANT_MCP.md`, `../oovrage/_meta/ETAT.md` et la section « Plugin client » de `../oovrage/_meta/BACKLOG.md`.

## Décisions prises par ce plan (à reporter dans `SPEC.md`, tâche 1)

- Nom du skill : `correspondant` → `/oovrage-client:correspondant`.
- Marketplace : une entrée dans `../oovrage/.claude-plugin/marketplace.json` dont la source est le dépôt git `gkfa-solutions/oovrage-client` (plugin à la racine de ce dépôt).
- Adresse du connecteur : `${OOVRAGE_PLATEFORME:-https://oovrage-platform.vercel.app}/mcp`. Le champ `plateforme` du fichier de config est écrit avec cette adresse par défaut ; le skill ne la demande au client que s'il en donne une autre, et prévient alors qu'il faut définir `OOVRAGE_PLATEFORME`.
- Garde-fou shell : dans un dossier client, **toute** commande `Bash` est bloquée (plus strict que « les commandes qui écrivent », impossible à reconnaître sûrement ; le client n'a pas besoin du shell).
- Sans en-tête `X-Oovrage-Projet`, `/mcp` (jeton valide) répond `400 projet_absent` ; projet dont la personne n'est pas membre (ou inexistant) : `403 projet_refuse`, même message dans les deux cas.
- Portée OAuth de l'adresse unique : `correspondant` ; ressource : `<origine>/mcp`.

## Review Focus

- **Dossier sans config, session du propriétaire (pilote)** : le connecteur ne doit jamais bloquer le travail ; le garde-fou sort en 0 et `entete-projet` rend `{}`. Tests : tâche 5 (`garde-fou` hors dossier client) et tâche 4 (`entete-projet` sans fichier).
- **Config illisible ou trafiquée** (`projet` absent, `"../x"`, JSON cassé) : `entete-projet` rend `{}` (jamais un en-tête invalide), le garde-fou bloque quand même (le fichier existe). Tests : tâche 4 et tâche 5.
- **Jeton de personne présenté sur `/mcp/<slug>`, ou jeton de projet sur `/mcp`** : refusé (401) dans les deux sens. Tests : tâche 2.
- **Personne retirée d'un projet après la connexion** : la requête suivante sur ce projet est refusée (403) alors que ses autres projets répondent. Test : tâche 3.
- **Écriture qui vise le fichier de config d'un AUTRE dossier, ou un chemin relatif** (`Write` sur `../bistro/.oovrage-client.json`, `Edit` sur `./.oovrage-client.json`) : seul le chemin absolu exact `<dossier>/.oovrage-client.json` est permis. Test : tâche 5.

---

### Task 1: Essai de la piste A (en-tête calculé depuis le dossier)

**But :** prouver qu'un serveur MCP HTTP déclaré par un plugin reçoit un en-tête produit par un `headersHelper` qui lit le dossier de la session. Le résultat tranche entre A et B.

**Files:**
- Create (jetable, scratchpad, pas commité) : `essai/plugin/.claude-plugin/plugin.json`, `essai/plugin/.mcp.json`, `essai/plugin/bin/entete`, `essai/serveur.mjs`
- Modify: `SPEC.md`

- [ ] **Step 1: Commit initial de ce dépôt sur `main`** : `git add CLAUDE.md SPEC.md docs/ && git commit -m "docs: spec et plan du plugin client"`, `git push -u origin main`, puis `git switch -c develop && git push -u origin develop`, puis `git switch -c feature/plugin-client`.
- [ ] **Step 2: Monter l'essai** dans un dossier du scratchpad :
  - `serveur.mjs` : serveur HTTP node sur le port 4999 qui écrit chaque requête (méthode, chemin, en-têtes) dans `requetes.log` et répond `401` sans corps.
  - `.mcp.json` : `{"mcpServers":{"essai":{"type":"http","url":"http://localhost:4999/mcp","headersHelper":"${CLAUDE_PLUGIN_ROOT}/bin/entete \"${CLAUDE_PROJECT_DIR}\""}}}`
  - `bin/entete` : lit `$1/.oovrage-client.json`, extrait `projet`, imprime `{"X-Oovrage-Projet":"<projet>"}` (ou `{}`), et ajoute `pwd` et `$1` dans `entete.log`.
  - Un dossier `dossier-cobalt/` contenant `.oovrage-client.json` = `{"plateforme":"http://localhost:4999","projet":"cobalt"}`.
- [ ] **Step 3: Lancer** depuis `dossier-cobalt/` : `claude --plugin-dir <essai>/plugin -p "Liste tes serveurs MCP"`.
  Attendu (piste A validée) : `requetes.log` contient `x-oovrage-projet: cobalt` ; `entete.log` montre que `$1` vaut le chemin de `dossier-cobalt`.
- [ ] **Step 4: Si `${CLAUDE_PROJECT_DIR}` n'est pas substitué**, réessayer sans argument et lire `pwd` dans `entete.log` (le helper tourne peut-être dans le dossier de la session). Si l'un des deux marche, garder celui-là pour la tâche 4.
- [ ] **Step 5: Consigner le résultat dans `SPEC.md`** (section « Changements côté plateforme », point 1) : piste retenue, syntaxe exacte qui marche, et les « Décisions prises par ce plan » ci-dessus. Mettre le statut de la spec à « cadrée ».
- [ ] **Step 6: Si ni A ni le repli `pwd` ne marchent : STOP.** Écrire le constat dans `SPEC.md`, commiter, et rendre la main au propriétaire : la piste B change les tâches 2 à 5, ce plan ne la couvre pas.
- [ ] **Step 7: Commit** : `git add SPEC.md && git commit -m "docs: piste A vérifiée pour le plugin client"`.

### Task 2: Plateforme — jeton lié à la personne, OAuth de l'adresse unique

Dépôt `../oovrage`, `apps/platform`. Branche : `git -C ../oovrage switch develop && git -C ../oovrage switch -c feature/mcp-adresse-unique`.

**Files:**
- Create: `apps/platform/drizzle/migrations/0007_mcp_personne.sql` (générée par `npm run db:generate` puis relue)
- Modify: `apps/platform/src/lib/db/schema.ts` (`api_tokens` : retirer `api_tokens_mcp_scope_check` ; `oauth_codes.project_slug` et `oauth_refresh.project_slug` deviennent nullables ; commentaires mis à jour : `NULL` = jeton de la personne, adresse `/mcp`)
- Modify: `apps/platform/src/lib/oauth/config.ts`
- Modify: `apps/platform/src/lib/oauth/service.ts`, `apps/platform/src/lib/oauth/authorize.ts`, `apps/platform/src/app/oauth/authorize/page.tsx`
- Modify: `apps/platform/src/lib/correspondant/auth.ts`, `apps/platform/src/lib/correspondant/instance.ts`
- Create: `apps/platform/src/app/.well-known/oauth-protected-resource/mcp/route.ts`
- Test: `apps/platform/src/lib/__tests__/correspondant-mcp-personne.test.ts` (même préambule de mocks et helpers que `correspondant-mcp.test.ts` ; `process.env.OAUTH_ALLOW_LOOPBACK = "1"` dans ce fichier ; projets fictifs atlas et cobalt, personne `fabio@atlas.example` membre des deux)

**Interfaces:**
- Produces (`oauth/config.ts`) :
  - `PERSONNE_SCOPE = "correspondant"`
  - `personResourceUrl(origin: string): string` → `${origin}/mcp`
  - `personResourceMetadataUrl(origin: string): string` → `${origin}/.well-known/oauth-protected-resource/mcp`
  - `slugFromRequest(origin, resource, scope)` rend désormais `{ slug: string | null; resource: string } | { error: string }` : `resource` = `<origine>/mcp` exactement, ou `scope` contient `correspondant` sans `projet:` → `{ slug: null, resource: personResourceUrl(origin) }`. `/mcp` + `projet:<x>` → erreur `"resource et scope désignent deux cibles"`. Le reste inchangé.
  - `CORS_HEADERS["Access-Control-Allow-Headers"]` gagne `x-oovrage-projet`.
- Produces (`correspondant/instance.ts`) : `projetsCorrespondant(email: string): Promise<string[]>` — slugs où `memberRoleForCorrespondant` serait non nul (membre, ni admin, ni `oovrage_admin`).
- Produces (`correspondant/auth.ts`) :
  - `resolvePersonToken(token: string | null): Promise<{ email: string; tokenId: number } | null>` — jeton `mcp` valide **avec `project_slug` NULL** uniquement ; met à jour `lastUsedAt`.
  - `unauthorized(origin: string, slug: string | null, tokenPresented: boolean)` — `slug` null → `resource_metadata` = `personResourceMetadataUrl`, `scope="correspondant"`.
  - `resolveMcpToken` inchangé (un jeton à `project_slug` NULL y est déjà refusé : vérifier par test).
- `ValidAuthorize.slug` devient `string | null` ; `issueAuthorizationCode`/`issueTokens` écrivent `projectSlug: null` dans ce cas.
- `exchangeAuthorizationCode` / `refreshAccessToken` : si `row.projectSlug` est null, la condition « encore membre » devient `(await projetsCorrespondant(row.email)).length > 0`.
- Consentement (`gate`) quand `slug` est null : refus `"Ce compte n'est membre d'aucun projet servi par un Correspondant."` si aucun projet de `projetsCorrespondant` n'a d'instance ouverte (`resoudrePourPersonne`) ; sinon `ConsentView` avec `projet: "Tous tes projets"`, `slug: ""`, et `autres` = noms des projets ouverts. `csrf` signé avec `slug: ""`. La page affiche « Correspondant Oovrage pour tous tes projets » puis la liste.

- [ ] **Step 1: Écrire les tests qui échouent** dans `correspondant-mcp-personne.test.ts` :
  - `métadonnées /mcp` : `GET /.well-known/oauth-protected-resource/mcp` → `{ resource: ORIGIN + "/mcp", authorization_servers: [ORIGIN], scopes_supported: ["correspondant"] }`.
  - `flux complet personne` : DCR avec `redirect_uris: ["http://127.0.0.1:33418/callback"]` → `prepareConsent` avec `resource=ORIGIN/mcp` → `kind: "consent"`, `view.autres` contient les noms d'atlas et cobalt → `decideConsent(approve)` → `/oauth/token` → `scope === "correspondant"` ; la ligne `api_tokens` a `projectSlug === null`.
  - `refresh personne` : le refresh rend un nouveau jeton à `projectSlug` null ; après retrait de fabio de **tous** ses projets → `invalid_grant`.
  - `resource /mcp + scope projet:atlas` → `invalid_target`.
  - `jeton de personne sur /mcp/atlas` → 401 ; `resolvePersonToken` sur un jeton de projet atlas → `null`.
  - `consentement sans projet servi` : personne membre d'aucun projet ouvert → `kind: "refuse"`.
- [ ] **Step 2: Lancer** `cd ../oovrage/apps/platform && npx vitest run src/lib/__tests__/correspondant-mcp-personne.test.ts` → FAIL.
- [ ] **Step 3: Implémenter** schéma + migration (`npm run db:generate`, relire le SQL : seulement le retrait de la contrainte et les deux `DROP NOT NULL`), puis les interfaces ci-dessus.
- [ ] **Step 4: Lancer** le fichier → PASS, puis `npx vitest run` et `npm run typecheck` → tout vert (dont `correspondant-mcp.test.ts` inchangé).
- [ ] **Step 5: Commit** : `git add -A apps/platform && git commit -m "feat(oauth): jeton du Correspondant lié à la personne pour l'adresse /mcp"` (vérifier avant que `_meta/ETAT.md` et `plugins/oovrage/plugin/.claude-plugin/plugin.json` ne sont pas dans le commit).

### Task 3: Plateforme — route `/mcp` avec le projet dans l'en-tête

**Files:**
- Create: `apps/platform/src/lib/correspondant/servir.ts`
- Create: `apps/platform/src/app/mcp/route.ts`
- Modify: `apps/platform/src/app/mcp/[slug]/route.ts` (ne garde que la résolution du jeton de projet, puis délègue à `servirCorrespondant`)
- Test: `apps/platform/src/lib/__tests__/correspondant-mcp-personne.test.ts`

**Interfaces:**
- Consumes: `resolvePersonToken`, `unauthorized(origin, null, …)`, `memberRoleForCorrespondant`, `PERSONNE_SCOPE` (tâche 2).
- Produces: `servirCorrespondant(request: Request, a: { slug: string; email: string; role: SessionRole; token: string; scopes: string[]; origin: string }): Promise<Response>` — tout ce que fait aujourd'hui `[slug]/route.ts` après l'authentification (405 hors POST, `resoudrePourPersonne`, 403 `correspondant_inactif` / `personne_retiree`, `enrollPersonne`, `buildCorrespondantServer`, transport sans état), à l'identique.
- `/mcp` : jeton via `resolvePersonToken` sinon `unauthorized(origin, null, Boolean(token))` ; en-tête `x-oovrage-projet` absent → `400 { error: "projet_absent", detail: "Aucun projet : lance /oovrage-client:correspondant dans le dossier du projet." }` ; mal formé (`!isSlug`), projet inconnu ou personne non membre → `403 { error: "projet_refuse", detail: "Ce compte n'a pas accès à ce projet." }` ; sinon `servirCorrespondant(..., scopes: [PERSONNE_SCOPE])`. Mêmes exports `POST/GET/DELETE/OPTIONS` que `[slug]`.

- [ ] **Step 1: Écrire les tests qui échouent** (helper `rpcPersonne(projet: string | null, token, method)` qui POSTe sur `/mcp` avec l'en-tête) :
  - sans jeton → 401, `www-authenticate` contient `resource_metadata="${ORIGIN}/.well-known/oauth-protected-resource/mcp"` et `scope="correspondant"`.
  - jeton de personne + `x-oovrage-projet: atlas` → `tools/list` 200, contient `accueil` ; `tools/call accueil` nomme le projet atlas ; même jeton + `cobalt` → répond pour cobalt.
  - sans en-tête → 400 `projet_absent` ; `x-oovrage-projet: ../atlas` → 403 `projet_refuse` ; `x-oovrage-projet: ember` (inexistant) → 403 `projet_refuse`, même corps.
  - fabio retiré d'atlas (ligne `intervenants_projects` supprimée) → atlas 403 `projet_refuse`, cobalt toujours 200.
  - jeton de projet atlas sur `/mcp` → 401.
- [ ] **Step 2: Lancer** le fichier → FAIL.
- [ ] **Step 3: Extraire `servirCorrespondant`** de `[slug]/route.ts`, puis écrire `mcp/route.ts`.
- [ ] **Step 4: Lancer** `npx vitest run && npm run typecheck` → tout vert.
- [ ] **Step 5: Docs** : `docs/CORRESPONDANT_MCP.md` (tableau des points : `/mcp` et ses métadonnées ; § Droits : jeton de personne, en-tête `X-Oovrage-Projet`, codes 400/403), `_meta/BACKLOG.md` section « Plugin client » (ce qui reste : boucle locale en production), `_meta/ETAT.md` (une entrée « Adresse MCP unique pour le plugin client »). Les modifications non commitées déjà présentes dans `_meta/ETAT.md` ne sont pas à toi : ajoute ton entrée sans les toucher et commite seulement tes lignes (`git add -p`).
- [ ] **Step 6: Commit** : `git commit -m "feat(mcp): adresse unique /mcp, projet passé par X-Oovrage-Projet"` ; message qui mentionne la reprise côté `oovrage-client`.

### Task 4: Plugin — squelette, connecteur et en-tête

Dépôt `oovrage-client`, branche `feature/plugin-client`.

**Files:**
- Create: `.claude-plugin/plugin.json` (`name: "oovrage-client"`, `version: "0.1.0"`, description « Parler au Correspondant d'un projet Oovrage. »)
- Create: `.mcp.json` : serveur `correspondant`, `type: "http"`, `url: "${OOVRAGE_PLATEFORME:-https://oovrage-platform.vercel.app}/mcp"`, `headersHelper` = la syntaxe validée en tâche 1 appelant `${CLAUDE_PLUGIN_ROOT}/bin/entete-projet`
- Create: `bin/entete-projet` (bash, exécutable)
- Create: `tests/lib.sh` (fonctions `ok`/`ko`, compteur, code de sortie), `tests/run.sh` (lance tous les `tests/test-*.sh`), `tests/test-entete-projet.sh`
- Modify: `../oovrage/.claude-plugin/marketplace.json` : deuxième plugin `{"name":"oovrage-client","source":{"source":"github","repo":"gkfa-solutions/oovrage-client"},"description":"Parler au Correspondant d'un projet Oovrage.", "category":"productivity"}` (commit sur `feature/mcp-adresse-unique`)

**Interfaces:**
- Produces: `bin/entete-projet [dossier]` — dossier = `$1` sinon `pwd` ; imprime sur stdout `{"X-Oovrage-Projet":"<slug>"}` si `<dossier>/.oovrage-client.json` existe et que son `projet` respecte `^[a-z0-9][a-z0-9-]{0,62}$` ; sinon `{}`. Toujours code 0. Lecture du champ par `sed`/`grep` (pas de jq).

- [ ] **Step 1: Écrire `tests/test-entete-projet.sh`** (chaque cas dans un `mktemp -d`) :
  - sans fichier → `{}` ;
  - `{"plateforme":"https://plateforme.example","projet":"atlas"}` → `{"X-Oovrage-Projet":"atlas"}` ;
  - même contenu sur plusieurs lignes et espaces autour des `:` → `atlas` ;
  - `"projet":"../atlas"`, `"projet":"Atlas"`, `projet` absent, fichier vide, JSON cassé → `{}` ;
  - code de sortie 0 dans tous les cas.
- [ ] **Step 2: Lancer** `bash tests/run.sh` → FAIL.
- [ ] **Step 3: Écrire** `bin/entete-projet`, `plugin.json`, `.mcp.json`.
- [ ] **Step 4: Lancer** `bash tests/run.sh` → PASS ; `claude plugin validate .` → aucune erreur.
- [ ] **Step 5: Commit** : `git add -A && git commit -m "feat: connecteur MCP et en-tête du projet"`.

### Task 5: Plugin — garde-fou

**Files:**
- Create: `hooks/hooks.json` : `PreToolUse`, matcher `Write|Edit|MultiEdit|NotebookEdit|Bash`, commande `${CLAUDE_PLUGIN_ROOT}/hooks/garde-fou`
- Create: `hooks/garde-fou` (bash, exécutable)
- Test: `tests/test-garde-fou.sh`

**Interfaces:**
- Produces: `hooks/garde-fou` — lit le JSON du hook sur stdin ; dossier = `$CLAUDE_PROJECT_DIR`, sinon le champ `cwd` du JSON.
  - `<dossier>/.oovrage-client.json` absent → exit 0, rien sur stdout ni stderr.
  - présent et `tool_name` = `Write`, `Edit` ou `MultiEdit` dont `tool_input.file_path` est exactement `<dossier>/.oovrage-client.json` → exit 0.
  - tout le reste (dont `Bash`, `NotebookEdit`, un champ illisible) → exit 2, stderr : `Dossier client Oovrage : seul .oovrage-client.json peut être écrit ici. Le Correspondant agit par ses outils, pas par des fichiers.`

- [ ] **Step 1: Écrire `tests/test-garde-fou.sh`** (JSON de hook construits à la main, `CLAUDE_PROJECT_DIR` = un `mktemp -d`) :
  - dossier sans config : `Write` sur `<d>/x.md` → 0 ; `Bash` `rm -rf x` → 0 ; aucune sortie.
  - dossier avec config : `Write` sur `<d>/.oovrage-client.json` → 0 ; `Edit` idem → 0.
  - dossier avec config : `Write` sur `<d>/notes.md` → 2 et le message ; `Edit` sur `<d>/sous/.oovrage-client.json` → 2 ; `Write` sur `<autre>/.oovrage-client.json` → 2 ; `Write` sur `.oovrage-client.json` (relatif) → 2 ; `NotebookEdit` → 2 ; `Bash` `ls` → 2 ; `Bash` `echo x > y` → 2.
  - dossier avec config dont le contenu est cassé → `Write` sur `<d>/notes.md` → 2.
  - `CLAUDE_PROJECT_DIR` vide, `cwd` du JSON = dossier avec config → `Write` sur `notes.md` → 2.
- [ ] **Step 2: Lancer** `bash tests/run.sh` → FAIL.
- [ ] **Step 3: Écrire** `hooks/hooks.json` et `hooks/garde-fou`.
- [ ] **Step 4: Lancer** `bash tests/run.sh` → PASS ; `claude plugin validate .` → OK.
- [ ] **Step 5: Commit** : `git commit -m "feat: garde-fou d'écriture dans un dossier client"`.

### Task 6: Plugin — skill `/oovrage-client:correspondant` et README

**Files:**
- Create: `skills/correspondant/SKILL.md`
- Create: `README.md` (installation : `/plugin marketplace add gkfa-solutions/oovrage` puis `/plugin install oovrage-client@oovrage` ; usage : un dossier par projet, lancer `/oovrage-client:correspondant` ; première connexion par `/mcp` ; ce que le plugin n'écrit jamais)
- Test: `tests/test-skill.sh`

**Contenu du skill** (frontmatter `name: correspondant`, `description: Parler au Correspondant du projet de ce dossier (Oovrage). À lancer dans le dossier du projet.`), en tutoiement, phrases courtes :
1. Lire `.oovrage-client.json` du dossier courant (outil `Read`).
2. **Absent** : demander le nom court du projet (le slug, donné par le pilote) ; ne demander l'adresse de la plateforme que si le client en mentionne une autre que `https://oovrage-platform.vercel.app`. Écrire **avec l'outil `Write`** `.oovrage-client.json` = `{ "plateforme": "<adresse>", "projet": "<slug>" }`, rien d'autre. Puis dire : « Tape `/mcp`, choisis `plugin:oovrage-client:correspondant` et reconnecte-le (première fois : connexion dans le navigateur). Puis relance `/oovrage-client:correspondant`. » S'arrêter là.
3. **Présent** : appeler l'outil MCP `accueil` du serveur `correspondant` et poursuivre la conversation à partir de sa réponse. Si l'appel échoue faute de connexion, donner la consigne `/mcp` ci-dessus ; s'il répond `projet_refuse`, dire que ce compte n'a pas accès à ce projet et de vérifier le nom avec le pilote.
4. Règles : ne jamais créer, modifier ni supprimer d'autre fichier ; ne jamais utiliser le shell ; ne jamais écrire de jeton dans le fichier ; toute action sur le projet passe par les outils du Correspondant.

- [ ] **Step 1: Écrire `tests/test-skill.sh`** : le fichier existe ; frontmatter `name: correspondant` ; il mentionne `.oovrage-client.json`, `accueil`, `/mcp`, `Write` ; il ne contient aucun nom hors de la liste fictive (grep sur une liste d'interdits partagée avec le dépôt `oovrage` si elle est lisible, sinon vérifier que seuls atlas/bistro/cobalt/ember/fjord apparaissent comme exemples de projet).
- [ ] **Step 2: Lancer** `bash tests/run.sh` → FAIL. **Step 3:** écrire `SKILL.md` et `README.md`. **Step 4:** `bash tests/run.sh` → PASS ; `claude plugin validate .` → OK.
- [ ] **Step 5: Commit** : `git commit -m "feat: skill correspondant et README"`.

### Task 7: Scénario de bout en bout (cobalt, en local) et vérification visuelle

**Préparation :**
- Dans `../oovrage/apps/platform/.env.local` (local seulement), ajouter s'ils manquent : `OAUTH_ALLOW_LOOPBACK=1` et `TEST_CLIENT_EMAIL=client@cobalt.example` (compte de test : connexion par lien magique, affiché sur `/sign-in` en local sans clé Resend — pas de mot de passe).
- `npm run db:local:start` puis `npm run db:local:reset` ; créer le projet cobalt, rendre `client@cobalt.example` membre (rôle client, non admin) et ouvrir une instance permanente du Correspondant, par les routes existantes (`/admin/projects`, `POST /api/projects/cobalt/correspondants` avec un jeton de pilote) ou en SQL local. Rien en production.
- `npm run dev` (port 3000).

- [ ] **Step 1: Vérification visuelle (claude-in-chrome)** : enregistrer un client par `curl -X POST localhost:3000/oauth/register -H 'content-type: application/json' -d '{"redirect_uris":["http://127.0.0.1:33418/callback"],"client_name":"Essai"}'`, construire l'URL `/oauth/authorize?response_type=code&client_id=…&redirect_uri=…&code_challenge=<43 car.>&code_challenge_method=S256&resource=http://localhost:3000/mcp`, se connecter avec `TEST_CLIENT_EMAIL` (lien affiché sur `/sign-in`), puis vérifier à l'écran : titre « Correspondant Oovrage pour tous tes projets », la liste des projets (cobalt), l'e-mail, l'hôte de retour `127.0.0.1:33418`, les boutons Autoriser / Refuser, la charte de la plateforme respectée (pas d'emoji, pas de tiret cadratin). Capture d'écran. Vérifier aussi l'ancien écran `/mcp/cobalt` (resource `…/mcp/cobalt`) : inchangé.
- [ ] **Step 2: Scénario dans un dossier jetable** `mktemp -d` → `dossier-cobalt`, avec `OOVRAGE_PLATEFORME=http://localhost:3000` :
  - lancer `claude --plugin-dir /Users/antoinesouesme/dev/projets/oovrage-client` ; `/oovrage-client:correspondant` → le skill demande le projet → répondre `cobalt` → seul `.oovrage-client.json` est créé (`ls -A`).
  - `/mcp` → reconnecter → connexion dans le navigateur avec `TEST_CLIENT_EMAIL` → relancer le skill → `accueil` répond pour cobalt.
  - demander « écris un fichier notes.md » → refusé par le garde-fou ; demander « lance ls » → refusé.
  - dans un autre dossier sans config, avec le plugin chargé : écrire un fichier → permis (garde-fou muet).
  Joue ce que tu peux sans session interactive : `claude --plugin-dir … -p "…" --permission-mode acceptEdits` pour la création du fichier et les refus du garde-fou. Pour la connexion OAuth, joue le flux en boucle locale toi-même : `curl` pour la DCR, page `/oauth/authorize` dans claude-in-chrome avec `TEST_CLIENT_EMAIL`, petit serveur local sur `127.0.0.1:33418` pour recevoir le `code`, échange sur `/oauth/token`, puis `curl` sur `/mcp` avec le jeton et `x-oovrage-projet: cobalt` (`tools/call accueil`). Vérifie côté base : `api_tokens` kind `mcp` à `project_slug` NULL, `correspondant_journal` contient l'appel `accueil` pour cobalt. La connexion par `/mcp` dans une session `claude` interactive, si tu ne peux pas la piloter, va dans `docs/suivi/DETTE.md` (ne la demande pas au propriétaire).
- [ ] **Step 3: Consigner** le déroulé et les défauts trouvés dans `SPEC.md` (section « Ordre proposé », points 4) et dans `../oovrage/_meta/ETAT.md`. Corriger chaque défaut avec son test avant de continuer.
- [ ] **Step 4: Geste de production — NE PAS EXÉCUTER.** Écrire dans le compte rendu final la commande exacte à faire valider, par exemple `vercel env add OAUTH_ALLOW_LOOPBACK production` (valeur `1`) suivie du redéploiement, et la migration `0007` à appliquer en production, puis attendre le go du propriétaire.
- [ ] **Step 5: Livraison** : pousser `feature/mcp-adresse-unique` et ouvrir la PR vers `develop` dans `gkfa-solutions/oovrage` ; commit final de `SPEC.md` mis à jour, pousser `feature/plugin-client` et ouvrir la PR vers `develop` dans `gkfa-solutions/oovrage-client`. Jamais de PR vers `main`.
