#!/usr/bin/env bash
set -Eeuo pipefail; IFS=$'\n\t'
cyan(){ printf "\033[36m%s\033[0m\n" "$*"; }
green(){ printf "\033[32m%s\033[0m\n" "$*"; }
red(){ printf "\033[31m%s\033[0m\n" "$*"; }

REMOTE="git@github.com:TurboDelire/Pixel_Termux.git"
[ -d .git ] || git init
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE" || true
git branch -M main || true

# Ajout ciblé (évite l’aspirateur à 135k fichiers)
git rm -r --cached . 2>/dev/null || true
git add -v -- .gitignore .gitattributes .editorconfig 2>/dev/null || true
git add -v -- *.sh *.py *.md requirements*.txt *.yml *.yaml *.json 2>/dev/null || true
git add -v -- PIXEL_MEMORY* 2>/dev/null || true

git status --short || true
if ! git diff --cached --quiet; then
  git commit -m "repo v1.2.0: stricter ignore, tools, safe push ($(date +%F_%T))"
fi

cyan "[PUSH] origin/main (SSH)…"
git push -u origin main
green "[OK] https://github.com/TurboDelire/Pixel_Termux"
