#!/data/data/com.termux/files/usr/bin/python
"""
atv.py — Télécommande Freebox Player Pop (Android TV) depuis Termux.
Protocole Android TV Remote v2 via la lib androidtvremote2.

Installation (Termux) :
    pkg install python python-cryptography
    pip install androidtvremote2

Première utilisation (appairage, une seule fois) :
    python atv.py pair --host 192.168.x.x
    -> un code à 6 caractères s'affiche sur la TV, tape-le.

Ensuite :
    python atv.py key home ok              # séquence de touches
    python atv.py key 1 4                   # chaîne 14
    python atv.py tui                       # mode interactif (clavier)

L'IP est mémorisée après l'appairage (~/.freebox_atv/config.json).
Certs TLS stockés dans ~/.freebox_atv/ — ne pas supprimer sinon ré-appairage.
"""
import asyncio
import argparse
import json
import os
import sys

CONFIG_DIR = os.path.expanduser("~/.freebox_atv")
CERT = os.path.join(CONFIG_DIR, "cert.pem")
KEY = os.path.join(CONFIG_DIR, "key.pem")
CFG = os.path.join(CONFIG_DIR, "config.json")
CLIENT_NAME = "freebox-termux"

# Alias conviviaux -> keycode Android (sans le préfixe KEYCODE_)
ALIASES = {
    "power": "POWER", "on": "POWER", "off": "POWER", "onoff": "POWER",
    "up": "DPAD_UP", "haut": "DPAD_UP",
    "down": "DPAD_DOWN", "bas": "DPAD_DOWN",
    "left": "DPAD_LEFT", "gauche": "DPAD_LEFT",
    "right": "DPAD_RIGHT", "droite": "DPAD_RIGHT",
    "ok": "DPAD_CENTER", "enter": "DPAD_CENTER", "center": "DPAD_CENTER",
    "home": "HOME", "accueil": "HOME",
    "back": "BACK", "retour": "BACK",
    "menu": "MENU",
    "vol+": "VOLUME_UP", "volup": "VOLUME_UP", "v+": "VOLUME_UP",
    "vol-": "VOLUME_DOWN", "voldown": "VOLUME_DOWN", "v-": "VOLUME_DOWN",
    "mute": "VOLUME_MUTE", "muet": "VOLUME_MUTE",
    "ch+": "CHANNEL_UP", "p+": "CHANNEL_UP",
    "ch-": "CHANNEL_DOWN", "p-": "CHANNEL_DOWN",
    "play": "MEDIA_PLAY_PAUSE", "pause": "MEDIA_PLAY_PAUSE", "playpause": "MEDIA_PLAY_PAUSE",
    "stop": "MEDIA_STOP",
    "next": "MEDIA_NEXT", "suivant": "MEDIA_NEXT",
    "prev": "MEDIA_PREVIOUS", "precedent": "MEDIA_PREVIOUS",
    "fwd": "MEDIA_FAST_FORWARD", "avance": "MEDIA_FAST_FORWARD",
    "bwd": "MEDIA_REWIND", "rewind": "MEDIA_REWIND", "recul": "MEDIA_REWIND",
    "search": "SEARCH", "recherche": "SEARCH",
    "mic": "VOICE_ASSIST", "assistant": "VOICE_ASSIST",
}
for _d in "0123456789":
    ALIASES[_d] = _d


def resolve(name):
    k = name.strip()
    return ALIASES.get(k.lower(), k.upper())


def load_host(cli_host):
    if cli_host:
        return cli_host
    env = os.environ.get("FBX_ATV_HOST")
    if env:
        return env
    if os.path.exists(CFG):
        try:
            return json.load(open(CFG)).get("host")
        except Exception:
            pass
    return None


def save_host(host):
    os.makedirs(CONFIG_DIR, exist_ok=True)
    json.dump({"host": host}, open(CFG, "w"))


def _import():
    try:
        from androidtvremote2 import AndroidTVRemote, InvalidAuth, CannotConnect
        return AndroidTVRemote, InvalidAuth, CannotConnect
    except ImportError:
        sys.exit("Lib manquante. Installe : pip install androidtvremote2 "
                 "(et au besoin : pkg install python-cryptography)")


async def do_pair(host):
    AndroidTVRemote, InvalidAuth, CannotConnect = _import()
    os.makedirs(CONFIG_DIR, exist_ok=True)
    r = AndroidTVRemote(CLIENT_NAME, CERT, KEY, host)
    await r.async_generate_cert_if_missing()
    try:
        await r.async_start_pairing()
    except CannotConnect:
        sys.exit(f"Connexion impossible à {host}:6467. Vérifie l'IP et le même Wi-Fi.")
    code = input("Code affiché sur la TV (6 caractères) : ").strip()
    try:
        await r.async_finish_pairing(code)
    except InvalidAuth:
        sys.exit("Code invalide.")
    save_host(host)
    print(f"✅ Appairé. Config et certs dans {CONFIG_DIR}")


async def connect(host):
    AndroidTVRemote, InvalidAuth, CannotConnect = _import()
    if not host:
        sys.exit("Pas d'hôte. Lance d'abord : python atv.py pair --host <IP>")
    r = AndroidTVRemote(CLIENT_NAME, CERT, KEY, host)
    if await r.async_generate_cert_if_missing():
        sys.exit("Pas encore appairé. Lance : python atv.py pair --host <IP>")
    try:
        await r.async_connect()
    except InvalidAuth:
        sys.exit("Auth refusée. Ré-appaire : python atv.py pair --host <IP>")
    except CannotConnect:
        sys.exit(f"Connexion impossible à {host}. Player éteint ou mauvaise IP ?")
    return r


async def do_keys(host, keys):
    r = await connect(host)
    for k in keys:
        r.send_key_command(resolve(k))
        print("→", resolve(k))
        await asyncio.sleep(0.25)
    r.disconnect()


TUI_HELP = """
Mode interactif — Freebox Player Pop
  Flèches      : navigation        Entrée : OK
  Retour arr.  : Back              h : Accueil (Home)
  + / -        : Volume            m : Muet
  Espace / p   : Play/Pause        s : Stop
  n / b        : Suivant / Précédent
  0-9          : chiffres          P : Power
  q / Échap    : quitter
"""


async def do_tui(host):
    import termios
    import tty
    r = await connect(host)
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    print(TUI_HELP)
    print("Connecté. En attente des touches…")
    loop = asyncio.get_event_loop()
    stop = asyncio.Event()

    def send(k):
        try:
            r.send_key_command(k)
            sys.stdout.write(f"\r→ {k}        ")
            sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(f"\r! {e}\n")

    buf = []

    def on_key():
        ch = sys.stdin.read(1)
        if not ch:
            return
        # séquences d'échappement (flèches)
        if ch == "\x1b":
            buf.clear()
            buf.append(ch)
            return
        if buf:
            buf.append(ch)
            seq = "".join(buf)
            if seq == "\x1b[A": send("DPAD_UP"); buf.clear(); return
            if seq == "\x1b[B": send("DPAD_DOWN"); buf.clear(); return
            if seq == "\x1b[C": send("DPAD_RIGHT"); buf.clear(); return
            if seq == "\x1b[D": send("DPAD_LEFT"); buf.clear(); return
            if len(buf) >= 3:
                buf.clear()
            if seq == "\x1b":  # Échap seul
                stop.set()
            return
        if ch in ("q", "\x1b"):
            stop.set(); return
        if ch in ("\r", "\n"): send("DPAD_CENTER"); return
        if ch in ("\x7f", "\x08"): send("BACK"); return
        if ch == " ": send("MEDIA_PLAY_PAUSE"); return
        m = {
            "h": "HOME", "+": "VOLUME_UP", "-": "VOLUME_DOWN", "m": "VOLUME_MUTE",
            "p": "MEDIA_PLAY_PAUSE", "s": "MEDIA_STOP", "n": "MEDIA_NEXT",
            "b": "MEDIA_PREVIOUS", "P": "POWER",
        }
        if ch in m: send(m[ch]); return
        if ch.isdigit(): send(ch); return

    try:
        tty.setcbreak(fd)
        loop.add_reader(fd, on_key)
        await stop.wait()
    finally:
        loop.remove_reader(fd)
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
        r.disconnect()
        print("\nDéconnecté.")


def main():
    ap = argparse.ArgumentParser(description="Télécommande Freebox Player Pop (Android TV)")
    ap.add_argument("--host", help="IP du Player (sinon config/env FBX_ATV_HOST)")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("pair", help="Appairer (code PIN à l'écran)")
    kp = sub.add_parser("key", help="Envoyer une ou plusieurs touches")
    kp.add_argument("keys", nargs="+", help="ex: home ok  |  1 4  |  vol+")
    sub.add_parser("tui", help="Mode interactif clavier")
    sub.add_parser("keys", help="Lister les alias de touches")
    args = ap.parse_args()

    if args.cmd == "keys":
        for a in sorted(set(ALIASES)):
            print(f"{a:12} -> {ALIASES[a]}")
        return

    host = load_host(args.host)
    if args.cmd == "pair":
        if not host:
            sys.exit("Donne l'IP : python atv.py pair --host <IP>")
        asyncio.run(do_pair(host))
    elif args.cmd == "key":
        asyncio.run(do_keys(host, args.keys))
    elif args.cmd == "tui":
        asyncio.run(do_tui(host))


if __name__ == "__main__":
    main()
