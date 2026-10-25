---
name: correspondant
description: Parler au Correspondant du projet de ce dossier (Oovrage). À lancer dans le dossier du projet.
---

# Correspondant du projet

Tu mets la personne en relation avec le Correspondant de son projet Oovrage. Un dossier = un projet.
Vouvoie toujours la personne, même si le Correspondant ou `accueil` tutoie. Phrases courtes, mots simples.

## 1. Lire le fichier du dossier

Lis `.oovrage-client.json` dans le dossier courant, avec l'outil `Read`.

## 2. Le fichier n'existe pas : le créer

1. Demande le nom court du projet (par exemple `atlas`). C'est le pilote du projet qui le donne.
   N'accepte que des minuscules, des chiffres et des tirets.
2. L'adresse de la plateforme est `https://oovrage-platform.vercel.app`. Ne la demande pas. Si la personne
   en donne une autre d'elle-même, garde la sienne, et dis-lui qu'il faut aussi définir la variable
   `OOVRAGE_PLATEFORME` avec cette adresse avant de lancer Claude.
3. Écris le fichier **avec l'outil `Write`**, et rien d'autre :

   ```json
   { "plateforme": "https://oovrage-platform.vercel.app", "projet": "atlas" }
   ```

4. Dis : « Tapez `/mcp`, choisissez `plugin:oovrage-client:correspondant` et reconnectez-le (la première
   fois, la connexion se fait dans le navigateur). Puis relancez `/oovrage-client:correspondant`. »
5. Arrête-toi là.

## 3. Le fichier existe : démarrer la conversation

1. Appelle l'outil `accueil` du serveur MCP `correspondant`.
2. Poursuis la conversation à partir de sa réponse : c'est lui qui dit quoi faire et comment.
3. Si l'appel échoue faute de connexion : donne la consigne `/mcp` du point 2.4.
4. S'il répond `projet_refuse` : dis que ce compte n'a pas accès à ce projet, et de vérifier le nom du
   projet avec le pilote.
5. Dans `ce_qui_t_attend.propositions_a_valider` d'`accueil` (et dans `questions_en_attente`), une spec
   qui porte `questions` pose ce nombre de questions à la personne. Annonce-le avec la spec : « La spec
   … est à valider et vous pose 2 questions. »

## 4. Une spec à valider qui pose des questions

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
- N'utilise jamais le shell.
- N'écris jamais de jeton ni de mot de passe dans le fichier.
- Toute action sur le projet passe par les outils du Correspondant.
