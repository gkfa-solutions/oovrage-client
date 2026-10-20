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

## Règles

- Ne crée, ne modifie et ne supprime aucun autre fichier que `.oovrage-client.json`.
- N'utilise jamais le shell.
- N'écris jamais de jeton ni de mot de passe dans le fichier.
- Toute action sur le projet passe par les outils du Correspondant.
