# oovrage-client

Plugin Claude Code pour parler au Correspondant d'un projet Oovrage.

## Installation

Dans Claude Code :

```
/plugin marketplace add gkfa-solutions/oovrage-client
/plugin install oovrage-client@oovrage-client
```

## Utilisation

1. Crée un dossier par projet (par exemple `atlas`), et lance Claude Code dedans.
2. Tape `/oovrage-client:correspondant`. La première fois, Claude te demande le nom court du projet
   (donné par le pilote) et crée le fichier `.oovrage-client.json`.
3. Tape `/mcp`, choisis `plugin:oovrage-client:correspondant` et connecte-le : la connexion se fait dans
   le navigateur, avec ton adresse e-mail (lien de connexion).
4. Relance `/oovrage-client:correspondant` : la conversation démarre sur ton projet.

La connexion vaut pour tous tes projets : dans un autre dossier, seul le nom du projet change.

Plateforme autre que `https://oovrage-platform.vercel.app` : définis la variable `OOVRAGE_PLATEFORME`
avec son adresse avant de lancer Claude Code.

## Ce que le plugin n'écrit jamais

Le plugin ne crée qu'un seul fichier, `.oovrage-client.json`, dans le dossier du projet. Il contient
l'adresse de la plateforme et le nom du projet, jamais de jeton : la connexion est gardée par Claude Code.

Dans un dossier qui contient ce fichier, un garde-fou bloque toute autre écriture et toute commande shell.
Ailleurs, il ne fait rien.
