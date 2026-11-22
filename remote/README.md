# Télécommande réseau Freebox Player

Pilote le Freebox Player via l'API HTTP locale `/pub/remote_control` (pas de Bluetooth).

## Prérequis
1. Player → **Réglages → Système → Télécommande réseau** : récupère le **code** (8 chiffres).
2. Note l'**IP locale** du Player (ou utilise `hd1.freebox.fr`).
3. Téléphone et Player sur le **même réseau Wi-Fi**.

## 1) Interface tactile (navigateur)
Ouvre `freebox_remote.html` dans le navigateur du téléphone (Chrome/Firefox).
- Renseigne IP + code dans ⚙️ Configuration → Enregistrer.
- Bouton **Tester** envoie `ok`.
- Section **Mes boutons / macros** : crée tes propres boutons (ex: `home,down,down,ok` ou `1,4` pour chaîne 14).
- Si rien ne se passe en mode *Image GET*, bascule sur *fetch no-cors* dans la config.
- Tout est stocké en local (localStorage), rien ne sort du téléphone.

## 2) Ligne de commande (Termux)
```bash
pkg install curl          # si besoin
export FBX_IP=192.168.x.x
export FBX_CODE=12345678
chmod +x fbx_key.sh
./fbx_key.sh ok
./fbx_key.sh up up ok
./fbx_key.sh 1 4          # chaîne 14
```

## Touches valides
`power up down left right ok home list epg info options swap vol_inc vol_dec mute prgm_inc prgm_dec play stop bwd fwd prev next rec red green yellow blue 0 1 2 3 4 5 6 7 8 9`

## Notes
- L'endpoint `/pub/remote_control` est l'API **legacy**. Sur firmwares récents elle peut être désactivée ; dans ce cas il faut passer par l'API authentifiée officielle (session + app_token). Dis-le moi si ça ne répond pas.
