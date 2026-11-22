# Télécommande Freebox Player

## ⚠️ Quel Player ?

- **Freebox Player Pop / Ultra (Android TV)** → utilise **`atv.py`** (protocole Android TV Remote v2).
  L'ancienne API HTTP `/pub/remote_control` **ne marche pas** sur ces modèles.
- **Anciens Players (Revolution/V6, Mini 4K…)** → `freebox_remote.html` + `fbx_key.sh` (API legacy HTTP).

Ton matériel = **Player Pop, Freebox OS v10 → `atv.py`.**

---

## atv.py — Player Pop (Android TV)

### Installation (Termux)
```bash
pkg install python python-cryptography
pip install androidtvremote2
```

### Appairage (une seule fois)
```bash
python atv.py pair --host 192.168.x.x
```
Un code à 6 caractères s'affiche sur la TV → tape-le. L'IP et les certs TLS
sont mémorisés dans `~/.freebox_atv/`.

### Envoyer des touches
```bash
python atv.py key home ok          # séquence
python atv.py key 1 4              # chaîne 14
python atv.py key vol+ vol+ mute
python atv.py keys                 # liste tous les alias
```

### Mode interactif (clavier = télécommande)
```bash
python atv.py tui
```
Flèches = navigation · Entrée = OK · Retour arrière = Back · `h` = Accueil ·
`+`/`-` = volume · `m` = muet · Espace/`p` = play/pause · `s` = stop ·
`n`/`b` = suivant/précédent · `0-9` = chiffres · `P` = power · `q` = quitter.

### Alias de touches
`power up down left right ok home back menu vol+ vol- mute ch+ ch- play stop
next prev fwd bwd search mic 0-9` (+ noms Android bruts type `DPAD_UP`).

### Limites connues
- **Allumage** : POWER ne rallume pas toujours un Pop éteint (limite du protocole,
  confirmée côté Home Assistant). Le reste fonctionne.
- Player et téléphone doivent être sur le **même réseau Wi-Fi**.
- Ne supprime pas `~/.freebox_atv/` sinon il faut ré-appairer.

---

## Legacy (anciens Players uniquement)

### freebox_remote.html
Page tactile à ouvrir dans le navigateur. Config IP + code télécommande
(Player → Réglages → Système). N'a d'effet que sur les Players pré-Android TV.

### fbx_key.sh
```bash
export FBX_IP=192.168.x.x ; export FBX_CODE=12345678
./fbx_key.sh ok
```
