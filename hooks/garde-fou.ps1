# Garde-fou du plugin client, pour Windows sans bash (hook PreToolUse sur Write,
# Edit, MultiEdit, NotebookEdit, Bash et PowerShell). Mêmes règles que
# `garde-fou`, son jumeau en bash.
#
# N'agit QUE dans un dossier client, c'est-à-dire un dossier qui contient
# `.oovrage-client.json` ($env:CLAUDE_PROJECT_DIR, sinon le `cwd` du hook) :
# ailleurs (session du pilote, autre projet), il sort en 0 sans rien dire.
# Dans un dossier client, seul ce fichier, par un chemin absolu, peut être
# écrit (Write, Edit, MultiEdit), et une seule commande passe : l'envoi à
# Oovrage d'un fichier par `curl`, selon le gabarit exact du skill, vers
# `https://app.oovrage.fr/api/envois/<jeton>`. Tout le reste est bloqué
# (code 2), y compris un appel illisible.
# PowerShell 5.1 (celui de Windows), rien à installer.

$ErrorActionPreference = 'Stop'
$MESSAGE = "Dossier client Oovrage : seul .oovrage-client.json peut être écrit ici, et la seule commande admise est l'envoi d'un fichier à Oovrage. Le Correspondant agit par ses outils, pas par des fichiers."
$ADRESSE = 'https://app.oovrage.fr/api/envois/'

function Chemin([string]$c) {
  if ($null -eq $c) { return '' }
  return $c.Replace('\', '/')
}

function Bloque {
  [Console]::Error.WriteLine($MESSAGE)
  exit 2
}

# Compte les clés `"<nom>":` du texte brut : une clé répétée rend l'appel illisible.
function NombreDeCles([string]$texte, [string]$nom) {
  return ([regex]::Matches($texte, '"' + [regex]::Escape($nom) + '"\s*:')).Count
}

$entree = [Console]::In.ReadToEnd()
$json = $null
try { $json = $entree | ConvertFrom-Json } catch { $json = $null }

$dossier = Chemin $env:CLAUDE_PROJECT_DIR
if (-not $dossier -and $null -ne $json -and $json.cwd -is [string]) { $dossier = Chemin $json.cwd }
if (-not $dossier) { exit 0 }
if (-not (Test-Path -LiteralPath "$dossier/.oovrage-client.json" -PathType Leaf)) { exit 0 }

if ($null -eq $json -or -not ($json.tool_name -is [string])) { Bloque }
if ((NombreDeCles $entree 'tool_name') -ne 1) { Bloque }

function Absolu([string]$c) {
  return ($c -cmatch '^/' -or $c -match '^[A-Za-z]:/')
}

function MemeDossier([string]$a, [string]$b) {
  if ($a -ceq $b) { return $true }
  try {
    $pa = [IO.Path]::GetFullPath($a).TrimEnd('/', '\')
    $pb = [IO.Path]::GetFullPath($b).TrimEnd('/', '\')
  } catch { return $false }
  if ([IO.Path]::DirectorySeparatorChar -eq '\') {
    return [string]::Equals($pa, $pb, [StringComparison]::OrdinalIgnoreCase)
  }
  return $pa -ceq $pb
}

# Chemin absolu, sans caractère qui sorte des apostrophes ou que curl lise comme
# une option, sans segment qui commence par un point, hors des emplacements
# sensibles (clés, profils de navigateur, réglages du système).
function CheminEnvoyable([string]$brut) {
  $c = Chemin $brut
  if (-not (Absolu $c)) { return $false }
  if ($c -match '[''";,$`|&<>%]' -or $c -match '[\x00-\x1f\x7f]') { return $false }
  $bas = ($c.ToLowerInvariant()) -replace '^[a-z]:', ''
  $tete = $bas.TrimStart('/')
  if ($tete -eq 'etc' -or $tete -match '^(etc|private|proc|sys|dev|boot|root|var|usr|bin|sbin|opt|system|windows|programdata|program files|program files \(x86\))/') { return $false }
  foreach ($seg in $bas.Split('/')) {
    if ($seg.StartsWith('.')) { return $false }
    if (@('library', 'appdata', 'application data', 'keychains') -contains $seg) { return $false }
    if ($seg -match '\.(pem|key|p12|pfx|kdbx|keychain|keychain-db|gpg)$' -or $seg -match '^id_(rsa|dsa|ecdsa|ed25519)') { return $false }
  }
  return $true
}

# La commande est exactement le gabarit d'envoi de cet outil (Bash :
# `curl … /dev/null`, PowerShell : `curl.exe … NUL`).
function Envoi([string]$outil, $commande) {
  if (-not ($commande -is [string])) { return $false }
  if ($outil -ceq 'Bash') { $prefixe = 'curl'; $nul = '/dev/null' }
  elseif ($outil -ceq 'PowerShell') { $prefixe = 'curl\.exe'; $nul = 'NUL' }
  else { return $false }
  $re = '^' + $prefixe + ' -sS -o ' + [regex]::Escape($nul) + " -w '%\{http_code\}' -F 'fichier=@([^']+)' '([^']+)'$"
  $m = [regex]::Match($commande, $re)
  if (-not $m.Success -or $m.Value.Length -ne $commande.Length) { return $false }
  $fin = $m.Groups[2].Value
  if (-not $fin.StartsWith($ADRESSE, [StringComparison]::Ordinal)) { return $false }
  $jeton = $fin.Substring($ADRESSE.Length)
  if ($jeton -cnotmatch '^[A-Za-z0-9_-]{20,400}$') { return $false }
  return (CheminEnvoyable $m.Groups[1].Value)
}

$outil = $json.tool_name
$entreeOutil = $json.tool_input
switch -CaseSensitive ($outil) {
  { $_ -cin @('Write', 'Edit', 'MultiEdit') } {
    if ((NombreDeCles $entree 'file_path') -ne 1 -or $null -eq $entreeOutil -or -not ($entreeOutil.file_path -is [string])) { Bloque }
    $cible = Chemin $entreeOutil.file_path
    if (-not (Absolu $cible)) { Bloque }
    $i = $cible.LastIndexOf('/')
    if ($cible.Substring($i + 1) -ceq '.oovrage-client.json' -and (MemeDossier $cible.Substring(0, $i) $dossier)) { exit 0 }
    Bloque
  }
  { $_ -cin @('Bash', 'PowerShell') } {
    if ((NombreDeCles $entree 'command') -ne 1 -or $null -eq $entreeOutil) { Bloque }
    if (Envoi $outil $entreeOutil.command) { exit 0 }
    Bloque
  }
  default { Bloque }
}
Bloque
