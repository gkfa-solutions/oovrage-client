# oovrage-client

Plugin Claude Code pour parler au Correspondant d'un projet Oovrage.

## Installation

Il vous faut un abonnement Claude payant et Claude Code 2.1.295 ou plus (le garde-fou du plugin en dépend,
sous Windows comme ailleurs).

Dans l'application de bureau (onglet Code) :

1. Créez un dossier vide pour votre projet (par exemple `atlas`) et choisissez-le avec « Project folder ».
2. Tapez `/plugin marketplace add gkfa-solutions/oovrage-client`.
3. Installez « oovrage-client » par **+**, puis « Add plugins ».
4. Tapez `/oovrage-client:correspondant`.
5. La première fois, tapez `/mcp`, choisissez `plugin:oovrage-client:oovrage-client` et connectez-vous dans
   le navigateur.

Dans le terminal, lancez `claude` dans le dossier du projet, puis :

```
/plugin marketplace add gkfa-solutions/oovrage-client
/plugin install oovrage-client@oovrage-client
```

Dès l'installation, activez la mise à jour automatique : tapez `/plugin`, ouvrez l'onglet des marketplaces,
choisissez `oovrage-client` et activez « Marketplace auto-update ». Le plus souvent, vous n'aurez alors
rien à faire quand une nouvelle version sort.

## Mettre à jour

Quand une nouvelle version du plugin est publiée, le Correspondant s'arrête et vous donne cette commande :

```
claude plugin update oovrage-client@oovrage-client
```

Dans l'application de bureau, cliquez sur « Run » sous la commande ; dans le terminal, tapez `!` suivi de
la commande. Puis tapez `/reload-plugins` et relancez `/oovrage-client:correspondant`. Si la commande
échoue : tapez `/plugin`, ouvrez l'onglet des plugins installés et mettez à jour oovrage-client.

Sur claude.ai, le plugin se redépose : demandez la nouvelle archive au builder du projet.

## Utilisation

1. Créez un dossier par projet (par exemple `atlas`), et lancez Claude Code dedans.
2. Tapez `/oovrage-client:correspondant`. La première fois, si vous n'êtes pas connecté, Claude vous
   demande de taper `/mcp`, de choisir `plugin:oovrage-client:oovrage-client` et de le connecter : la
   connexion se fait dans le navigateur, avec votre adresse e-mail (lien de connexion). Une fois connecté,
   dites « c'est fait » ; si le Correspondant ne répond toujours pas, relancez
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

Quand une question attend une réponse, Claude vous dit si votre réponse est retenue, proposée (en attente
de qui a le droit de trancher) ou défaite. Un commentaire n'est pas une réponse.

Pour joindre un petit fichier (4 Mo au plus) à une demande ou à un élément, donnez à Claude son chemin
complet : il l'envoie à Oovrage avec votre accord. Au-delà, il vous donne le lien de la page, où vous le
joignez vous-même, jusqu'à 1 Go.

La connexion vaut pour tous vos projets : dans un autre dossier, seul le nom du projet change.

## Ce que le plugin n'écrit jamais

Le plugin ne crée qu'un seul fichier, `.oovrage-client.json`, dans le dossier du projet. Il contient
l'adresse de la plateforme, votre organisation et le nom du projet, jamais de jeton : la connexion est gardée par Claude Code.

Dans un dossier qui contient ce fichier, un garde-fou bloque toute autre écriture et toute commande, sauf
une seule : l'envoi à Oovrage d'un fichier que vous avez désigné, à l'adresse d'envoi qu'Oovrage vient de
délivrer. Il tourne sous macOS, Linux et Windows, sans rien à installer (un script bash et un script
PowerShell aux mêmes règles). Ailleurs, il ne fait rien.
