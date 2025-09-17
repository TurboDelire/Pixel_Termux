SHELL:=/usr/bin/env bash
.PHONY: push status count clean-cache

push:
\tbin/pixel_push_ssh.sh

status:
\tgit status --short || true

count:
\t@echo "Fichiers suivis:"; git ls-files | wc -l
\t@echo "Top tailles:"; du -sh ./* 2>/dev/null | sort -h | tail -n 10

clean-cache:
\tgit rm -r --cached . 2>/dev/null || true
\tgit status --short
