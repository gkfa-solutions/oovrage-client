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
2. Tapez `/oovrage-client:correspondant`. La première fois, si vous n'êtes pas connecté, Claude vous
   demande de taper `/mcp`, de choisir `plugin:oovrage-client:correspondant` et de le connecter : la
   connexion se fait dans le navigateur, avec votre adresse e-mail (lien de connexion). Relancez ensuite
   `/oovrage-client:correspondant`.
3. Claude vous propose votre organisation (s'il y en a plusieurs), puis les projets auxquels vous avez accès. Choisissez le vôtre : il crée le fichier
   `.oovrage-client.json` et la conversation démarre sur votre projet.

Le dossier doit être réservé au projet. Si vous lancez le plugin dans un dossier général de l'ordinateur
(dossier personnel, Bureau, Documents, Téléchargements…) ou dans un dossier qui ressemble à un projet en
cours, il refuse d'y travailler : il vous propose un nouveau dossier, y crée le fichier avec votre accord,
et vous demande de relancer Claude Code dedans.

Quand une spec à valider vous pose des questions, Claude vous les montre avec notre recommandation et vous
propose d'y répondre une par une. Valider la spec sans répondre, c'est accepter nos recommandations.

Quand Claude vous propose des choix, un bouton par choix envoie directement votre réponse. Une fois un
élément traité, il passe tout seul au suivant de ce qui vous attend.

La connexion vaut pour tous vos projets : dans un autre dossier, seul le nom du projet change.

## Ce que le plugin n'écrit jamais

Le plugin ne crée qu'un seul fichier, `.oovrage-client.json`, dans le dossier du projet. Il contient
l'adresse de la plateforme, votre organisation et le nom du projet, jamais de jeton : la connexion est gardée par Claude Code.

Dans un dossier qui contient ce fichier, un garde-fou bloque toute autre écriture et toute commande shell.
Ailleurs, il ne fait rien.
