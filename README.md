# oovrage-client

Plugin Claude Code pour parler au Correspondant d'un projet Oovrage.

## Installation

Dans Claude Code :

```
/plugin marketplace add gkfa-solutions/oovrage-client
/plugin install oovrage-client@oovrage-client
```

## Utilisation

1. Créez un dossier par projet (par exemple `atlas`), et lancez Claude Code dedans.
2. Tapez `/oovrage-client:correspondant`. La première fois, Claude vous demande le nom court du projet
   (donné par le pilote) et crée le fichier `.oovrage-client.json`.
3. Tapez `/mcp`, choisissez `plugin:oovrage-client:correspondant` et connectez-le : la connexion se fait
   dans le navigateur, avec votre adresse e-mail (lien de connexion).
4. Relancez `/oovrage-client:correspondant` : la conversation démarre sur votre projet.

Quand une spec à valider vous pose des questions, Claude vous les montre avec notre recommandation et vous
propose d'y répondre une par une. Valider la spec sans répondre, c'est accepter nos recommandations.

La connexion vaut pour tous vos projets : dans un autre dossier, seul le nom du projet change.

Plateforme autre que `https://oovrage-platform.vercel.app` : définissez la variable `OOVRAGE_PLATEFORME`
avec son adresse avant de lancer Claude Code.

## Ce que le plugin n'écrit jamais

Le plugin ne crée qu'un seul fichier, `.oovrage-client.json`, dans le dossier du projet. Il contient
l'adresse de la plateforme et le nom du projet, jamais de jeton : la connexion est gardée par Claude Code.

Dans un dossier qui contient ce fichier, un garde-fou bloque toute autre écriture et toute commande shell.
Ailleurs, il ne fait rien.
