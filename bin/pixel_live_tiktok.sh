#!/usr/bin/env bash
# PIXEL — Restream TikTok LIVE sans caméra (Termux / S24)
# Pousse une source vidéo (flux NASA public par défaut) vers TikTok en RTMP via ffmpeg.
#
# PREREQUIS TikTok :
#   1) Compte avec acces LIVE.
#   2) URL d'ingest RTMP + Stream Key (TikTok LIVE Studio / "diffuser via logiciel tiers").
# PREREQUIS Termux :
#   pkg install ffmpeg
#   (optionnel) pkg install termux-api  -> pour termux-wake-lock
#
# LEGAL :
#   - NASA TV public = domaine public, rediffusable.
#   - Sen "Space Live" et autres chaines = NON libres. Ne pas rediffuser.
#
# USAGE :
#   export TIKTOK_URL="rtmp://.../live"     # URL d'ingest fournie par TikTok
#   export TIKTOK_KEY="xxxxxxxx"            # Stream Key fournie par TikTok
#   bin/pixel_live_tiktok.sh                      # source = NASA public (defaut)
#   bin/pixel_live_tiktok.sh <source_url_ou_fichier>
#   SOURCE=/sdcard/Movies/space.mp4 bin/pixel_live_tiktok.sh
#   MODE=copy  bin/pixel_live_tiktok.sh           # pas de re-encodage (plus leger, moins compatible)
#   BITRATE=1500k bin/pixel_live_tiktok.sh        # baisser si ca saccade
#   RETRY=0    bin/pixel_live_tiktok.sh           # desactive la reconnexion auto

set -Eeuo pipefail; IFS=$'\n\t'

cyan(){ printf "\033[36m%s\033[0m\n" "$*"; }
green(){ printf "\033[32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }
red(){ printf "\033[31m%s\033[0m\n" "$*" >&2; }

# --- Source : NASA Public TV (HLS, domaine public). Remplacable en argument ou via $SOURCE.
NASA_DEFAULT="https://ntv1.akamaihd.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8"
SOURCE="${1:-${SOURCE:-$NASA_DEFAULT}}"

# --- Cible TikTok
TIKTOK_URL="${TIKTOK_URL:-}"
TIKTOK_KEY="${TIKTOK_KEY:-}"

# --- Reglages
MODE="${MODE:-reencode}"     # reencode (defaut) | copy
BITRATE="${BITRATE:-2500k}"  # debit video cible
RETRY="${RETRY:-1}"          # 1 = reconnexion auto si le flux tombe

# --- Wake-lock : evite qu'Android tue le process ecran eteint
WAKE_LOCKED=0
cleanup(){
  [ "$WAKE_LOCKED" = "1" ] && command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock || true
  yellow "[PIXEL-LIVE] Arret."
}
trap cleanup EXIT INT TERM

command -v ffmpeg >/dev/null 2>&1 || { red "[ERR] ffmpeg absent. -> pkg install ffmpeg"; exit 1; }

if [ -z "$TIKTOK_URL" ] || [ -z "$TIKTOK_KEY" ]; then
  red "[ERR] TIKTOK_URL et TIKTOK_KEY requis."
  red "      Recupere-les dans TikTok LIVE Center / option 'logiciel tiers', puis :"
  red '      export TIKTOK_URL="rtmp://.../live"; export TIKTOK_KEY="ta_cle"'
  exit 2
fi

# --- Check reseau (best-effort, ne bloque pas si les outils manquent)
net_ok(){
  if command -v ping >/dev/null 2>&1; then
    ping -c1 -W3 push.tiktokcdn.com >/dev/null 2>&1 && return 0
    ping -c1 -W3 1.1.1.1          >/dev/null 2>&1 && return 0
    return 1
  fi
  return 0
}
if ! net_ok; then
  red "[ERR] Pas de reseau joignable. Verifie le Wi-Fi/4G puis relance."
  exit 3
fi
green "[PIXEL-LIVE] Reseau OK."

# --- Wake-lock si termux-api dispo
if command -v termux-wake-lock >/dev/null 2>&1; then
  termux-wake-lock && WAKE_LOCKED=1 && green "[PIXEL-LIVE] Wake-lock actif."
else
  yellow "[PIXEL-LIVE] termux-wake-lock absent (pkg install termux-api). Garde l'ecran allume."
fi

# Concatenation propre URL + key (gere le / final ou non)
case "$TIKTOK_URL" in
  */) TARGET="${TIKTOK_URL}${TIKTOK_KEY}";;
  *)  TARGET="${TIKTOK_URL}/${TIKTOK_KEY}";;
esac

cyan "[PIXEL-LIVE] Source : $SOURCE"
cyan "[PIXEL-LIVE] Cible  : ${TIKTOK_URL}/********  (mode=$MODE, bitrate=$BITRATE)"
cyan "[PIXEL-LIVE] Lance ffmpeg AVANT de cliquer 'Go LIVE'. Ctrl-C pour arreter."

# -re : lecture au rythme reel. -stream_loop -1 : reboucle un fichier local.
LOOP=()
[ -f "$SOURCE" ] && LOOP=(-stream_loop -1)

# Reconnexion auto cote lecture (sources HTTP/HLS)
IN_RECONNECT=(-reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -reconnect_delay_max 5)

run_ffmpeg(){
  if [ "$MODE" = "copy" ]; then
    # Sans re-encodage : plus leger, mais GOP source pas garanti -> coupures possibles.
    ffmpeg -hide_banner -loglevel warning "${IN_RECONNECT[@]}" -re "${LOOP[@]}" -i "$SOURCE" \
      -c copy -f flv "$TARGET"
  else
    # Re-encodage H.264/AAC, keyframe 2s (requis TikTok), 720p30.
    ffmpeg -hide_banner -loglevel warning "${IN_RECONNECT[@]}" -re "${LOOP[@]}" -i "$SOURCE" \
      -c:v libx264 -preset veryfast -tune zerolatency -profile:v main \
      -b:v "$BITRATE" -maxrate "$BITRATE" -bufsize "$BITRATE" \
      -vf "scale=-2:720,format=yuv420p" -r 30 -g 60 -keyint_min 60 \
      -c:a aac -b:a 128k -ar 44100 \
      -f flv "$TARGET"
  fi
}

# --- Boucle de supervision : relance ffmpeg si le flux tombe (sauf RETRY=0 ou Ctrl-C)
while true; do
  green "[PIXEL-LIVE] Demarrage du flux…"
  run_ffmpeg && break || true
  [ "$RETRY" = "1" ] || { red "[PIXEL-LIVE] Flux termine/erreur (RETRY=0)."; break; }
  yellow "[PIXEL-LIVE] Flux interrompu. Nouvelle tentative dans 3s… (Ctrl-C pour stopper)"
  sleep 3
done
