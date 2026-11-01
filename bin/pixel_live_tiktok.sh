#!/usr/bin/env bash
# PIXEL — Restream TikTok LIVE sans caméra (Termux / S24)
# Pousse une source vidéo (flux NASA public par défaut) vers TikTok en RTMP via ffmpeg.
#
# PREREQUIS TikTok :
#   1) Compte avec acces LIVE.
#   2) URL d'ingest RTMP + Stream Key (TikTok LIVE Studio ou "diffuser via logiciel tiers").
# PREREQUIS Termux :
#   pkg install ffmpeg
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
#   MODE=copy bin/pixel_live_tiktok.sh            # pas de re-encodage (plus leger, moins compatible)

set -Eeuo pipefail; IFS=$'\n\t'

cyan(){ printf "\033[36m%s\033[0m\n" "$*"; }
green(){ printf "\033[32m%s\033[0m\n" "$*"; }
red(){ printf "\033[31m%s\033[0m\n" "$*" >&2; }

# --- Source : NASA Public TV (HLS, domaine public). Remplacable en argument ou via $SOURCE.
NASA_DEFAULT="https://ntv1.akamaihd.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8"
SOURCE="${1:-${SOURCE:-$NASA_DEFAULT}}"

# --- Cible TikTok
TIKTOK_URL="${TIKTOK_URL:-}"
TIKTOK_KEY="${TIKTOK_KEY:-}"

# --- Mode d'encodage : reencode (defaut, compatible TikTok) ou copy
MODE="${MODE:-reencode}"

command -v ffmpeg >/dev/null 2>&1 || { red "[ERR] ffmpeg absent. -> pkg install ffmpeg"; exit 1; }

if [ -z "$TIKTOK_URL" ] || [ -z "$TIKTOK_KEY" ]; then
  red "[ERR] TIKTOK_URL et TIKTOK_KEY requis."
  red "      Recupere-les dans TikTok LIVE Studio / option 'logiciel tiers', puis :"
  red '      export TIKTOK_URL="rtmp://.../live"; export TIKTOK_KEY="ta_cle"'
  exit 2
fi

# Concatenation propre URL + key (gere le / final ou non)
case "$TIKTOK_URL" in
  */) TARGET="${TIKTOK_URL}${TIKTOK_KEY}";;
  *)  TARGET="${TIKTOK_URL}/${TIKTOK_KEY}";;
esac

cyan "[PIXEL-LIVE] Source : $SOURCE"
cyan "[PIXEL-LIVE] Cible  : ${TIKTOK_URL}/********  (mode=$MODE)"
cyan "[PIXEL-LIVE] Ctrl-C pour arreter."

# -re : lecture au rythme reel. -stream_loop -1 : reboucle un fichier local.
LOOP=()
[ -f "$SOURCE" ] && LOOP=(-stream_loop -1)

if [ "$MODE" = "copy" ]; then
  # Rediffusion sans re-encodage : plus leger pour le S24, mais le GOP de la source
  # peut ne pas convenir a TikTok (coupures possibles).
  exec ffmpeg -hide_banner -loglevel warning -re "${LOOP[@]}" -i "$SOURCE" \
    -c copy -f flv "$TARGET"
else
  # Re-encodage H.264/AAC avec keyframe toutes les 2s (requis TikTok).
  # Reglages 720p30 raisonnables pour un telephone.
  exec ffmpeg -hide_banner -loglevel warning -re "${LOOP[@]}" -i "$SOURCE" \
    -c:v libx264 -preset veryfast -tune zerolatency -profile:v main \
    -b:v 2500k -maxrate 2500k -bufsize 5000k \
    -vf "scale=-2:720,format=yuv420p" -r 30 -g 60 -keyint_min 60 \
    -c:a aac -b:a 128k -ar 44100 \
    -f flv "$TARGET"
fi
