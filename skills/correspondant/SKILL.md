---
name: correspondant
description: Parler au Correspondant du projet de ce dossier (Oovrage). À lancer dans le dossier du projet.
---

# Correspondant du projet

Tu mets la personne en relation avec le Correspondant de son projet Oovrage. Un dossier = un projet.
Vouvoie toujours la personne, même si le Correspondant ou `accueil` tutoie. Phrases courtes, mots simples.

## 1. Lire le fichier du dossier

Lis `.oovrage-client.json` dans le dossier courant, avec l'outil `Read`.

## 2. Vérifier le dossier

Avant tout, regarde où tu es : le chemin du dossier courant, et son contenu avec l'outil `Glob`
(motifs `*`, `.*` et `*/*`, rien de plus profond). Juge le dossier, ne coche pas une liste : la question
est « est-ce un dossier réservé à ce projet Oovrage, ou un dossier où la personne a autre chose à
protéger ? ». Si le dossier va bien, n'en parle pas et continue.

Ne compte pas ce que le plugin et Claude Code créent eux-mêmes : `.oovrage-client.json`,
`.claude/settings.local.json` (Claude Code l'écrit quand la personne accepte une autorisation), et les
fichiers cachés du système (`.DS_Store`, `Thumbs.db`, `desktop.ini`). Un dossier vide, ou qui ne contient
que ces fichiers-là, est le bon dossier.

1. **Dossier général** : la racine (`/`, `C:\`), le dossier personnel (`~`, `/Users/<nom>`,
   `/home/<nom>`, `C:\Users\<nom>`), le Bureau (`Desktop`), `Documents`, `Téléchargements`
   (`Downloads`), un dossier du système (`/Users`, `/Applications`, `C:\Program Files`…), ou un dossier
   rempli des documents de la personne. Avertis-la : « Ce dossier est un dossier général de votre
   ordinateur. Je ne travaille pas ici. » Puis fais comme au point 2.3, avec un nouveau dossier
   `oovrage/<projet>` dans son dossier personnel.
2. **Projet en cours** : de vrais signes d'un travail de la personne, comme un dépôt `.git`, du code
   (`src`, `package.json`, `pyproject.toml`, `composer.json`, `node_modules`…), un projet piloté
   (`_projet`, `_pilotage`, `CLAUDE.md`, `AGENTS.md`), un `.claude` qui contient autre chose que
   `settings.local.json`, ou un ensemble de fichiers de travail. Un ou deux documents posés là par la
   personne (un cahier des charges, une capture) ne suffisent pas : le dossier reste bon. Dis : « Ce
   dossier ressemble à un projet en cours. Je ne travaille pas dedans, pour ne rien y toucher. » Puis fais
   comme au point 2.3, avec un nouveau dossier `<projet>-oovrage` à côté de celui-ci (dans le même
   dossier parent).
3. **Proposer le bon dossier** : demande le nom court du projet (comme au point 3.1), puis propose le
   nouveau dossier par son chemin complet. Si ce dossier existe déjà et n'est pas vide, propose-en un
   autre. Avec l'accord de la personne, écris `.oovrage-client.json` **dans ce nouveau dossier** avec
   l'outil `Write` (le dossier est créé avec), et dis : « Quittez cette session, puis relancez Claude
   Code dans le dossier `<chemin complet>` (dans un terminal : `cd "<chemin complet>"` puis `claude`), et
   tapez `/oovrage-client:correspondant`. » Arrête-toi là : n'écris rien dans le dossier courant.
4. Dans le doute, demande à la personne si ce dossier est bien réservé à ce projet, et crois sa réponse.
5. Si `.oovrage-client.json` existe déjà dans un dossier général ou dans un projet en cours, dis-le de la
   même façon, sans rien écrire (le garde-fou l'empêche) : propose à la personne de créer elle-même le
   nouveau dossier du point 2.3, d'y déplacer `.oovrage-client.json`, puis d'y relancer Claude Code et
   `/oovrage-client:correspondant`. Arrête-toi là.

## 3. Le fichier n'existe pas : le créer

1. Demande le nom court du projet (par exemple `atlas`). C'est le pilote du projet qui le donne.
   N'accepte que des minuscules, des chiffres et des tirets.
2. L'adresse de la plateforme est `https://app.oovrage.fr`. Ne la demande pas.
3. Écris le fichier **avec l'outil `Write`**, et rien d'autre :

   ```json
   { "plateforme": "https://app.oovrage.fr", "projet": "atlas" }
   ```

4. Dis : « Tapez `/mcp`, choisissez `plugin:oovrage-client:correspondant` et reconnectez-le (la première
   fois, la connexion se fait dans le navigateur). Puis relancez `/oovrage-client:correspondant`. »
5. Arrête-toi là.

## 4. Le fichier existe : démarrer la conversation

1. Appelle l'outil `accueil` du serveur MCP `oovrage-client`.
2. Poursuis la conversation à partir de sa réponse : c'est lui qui dit quoi faire et comment.
3. Si l'appel échoue faute de connexion : donne la consigne `/mcp` du point 3.4.
4. S'il répond `projet_absent` : le nom du projet n'est pas arrivé à la plateforme. Ne touche pas au
   fichier (l'adresse `plateforme` qu'il contient n'est jamais lue) ; dis de quitter Claude Code, de le
   relancer dans ce dossier, puis de relancer `/oovrage-client:correspondant`, et si l'erreur revient,
   de prévenir le pilote du projet.
5. S'il répond `projet_refuse` : dis que ce compte n'a pas accès à ce projet, et de vérifier le nom du
   projet avec le pilote.
6. Dans `ce_qui_t_attend.propositions_a_valider` d'`accueil` (et dans `questions_en_attente`), une spec
   qui porte `questions` pose ce nombre de questions à la personne. Annonce-le avec la spec : « La spec
   … est à valider et vous pose 2 questions. »

## 5. Une spec à valider qui pose des questions

1. Lis la spec avec `lire`. Sa réponse porte `questions` (au plus quatre) : pour chacune, `numero`,
   `texte`, `recommandation` et `reponse` (`null` tant que personne n'a répondu).
2. Montre chaque question avec notre recommandation, et la réponse déjà donnée s'il y en a une :

   > **Question 1** : Le devis affiche-t-il les prix ?
   > Notre recommandation : oui, hors taxes.

3. Propose d'y répondre une par une. Pour chaque réponse, demande d'abord l'accord de la personne, comme
   pour tout geste, puis appelle `commenter` avec `cible` = la spec, `question` = le numéro de la question
   et `texte` = sa réponse. Une nouvelle réponse à la même question remplace la précédente.
4. Dis que valider la spec sans répondre, c'est accepter nos recommandations sur les questions restées
   sans réponse. Si une réponse s'écarte de notre recommandation, l'équipe réécrit la spec et la propose
   de nouveau à valider.
5. Si `commenter` répond « cette spec ne pose pas de question à ce numéro », relis la spec avec `lire` et
   reprends le bon numéro.

## Règles

- Ne crée, ne modifie et ne supprime aucun autre fichier que `.oovrage-client.json`.
- N'écris jamais `.oovrage-client.json` dans un dossier général ni dans un projet en cours (point 2).
- N'utilise jamais le shell.
- N'écris jamais de jeton ni de mot de passe dans le fichier.
- Toute action sur le projet passe par les outils du Correspondant.
