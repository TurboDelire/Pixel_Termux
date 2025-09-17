#!/usr/bin/env bash
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends python3 python3-pip git git-lfs curl jq nmap ca-certificates
git lfs install || true
python3 -m pip install --upgrade pip wheel
[ -f requirements.txt ] && python3 -m pip install -r requirements.txt || true
echo "[SETUP] ok"
