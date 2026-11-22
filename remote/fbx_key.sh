#!/data/data/com.termux/files/usr/bin/bash
# fbx_key.sh — télécommande réseau Freebox Player en ligne de commande (Termux)
# Usage:
#   export FBX_IP=192.168.x.x        # IP locale du Player (ou hd1.freebox.fr)
#   export FBX_CODE=XXXXXXXX         # code télécommande (Player > Réglages > Système)
#   ./fbx_key.sh power
#   ./fbx_key.sh up up ok            # séquence
#   ./fbx_key.sh 1 4                 # chaîne 14
set -u

IP="${FBX_IP:-}"
CODE="${FBX_CODE:-}"

if [ -z "$IP" ] || [ -z "$CODE" ]; then
  echo "Erreur: définis FBX_IP et FBX_CODE." >&2
  echo "  export FBX_IP=192.168.x.x ; export FBX_CODE=12345678" >&2
  exit 1
fi
if [ $# -eq 0 ]; then
  echo "Usage: $0 <touche> [touche ...]" >&2
  echo "touches: power up down left right ok home list epg info options swap" >&2
  echo "         vol_inc vol_dec mute prgm_inc prgm_dec play stop bwd fwd prev next rec" >&2
  echo "         red green yellow blue 0..9" >&2
  exit 1
fi

for key in "$@"; do
  url="http://${IP}/pub/remote_control?code=${CODE}&key=${key}"
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 4 "$url")
  if [ "$code" = "200" ]; then
    echo "ok   $key"
  else
    echo "FAIL $key (http $code)" >&2
  fi
  sleep 0.25
done
