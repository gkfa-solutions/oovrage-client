# Dette — plugin oovrage-client

- **Connexion par `/mcp` dans une session Claude Code interactive : pas jouée.** Le scénario local l'a
  couverte par morceaux : Claude Code atteint `/mcp` avec `X-Oovrage-Projet: cobalt` et découvre l'OAuth
  (401 puis métadonnées), le flux OAuth en boucle locale a été joué à la main dans le navigateur jusqu'au
  jeton, et `accueil` répond pour cobalt avec ce jeton. Reste à le jouer d'un bout à l'autre dans une vraie
  session (`/mcp` → reconnecter → navigateur → `/oovrage-client:correspondant`).
