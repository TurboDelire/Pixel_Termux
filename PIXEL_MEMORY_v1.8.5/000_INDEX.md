# PIXEL — Mémoire Opérationnelle (modulaire)
Version pack: v1.8.5
- 100_v1.6.0_full.txt — FULL + Blueprint + Runbook
- 200_v1.7.0_full.txt — S24 mobile-first + galerie dir-first
- 300_v1.8.0_full.txt — Audit-first, ports ≥7000, stubs CORS, logging auto, wrapper same-origin

## Règle BIOS
- Ne JAMAIS écraser les mémoires.
- Toujours créer UNE NOUVELLE VERSION dans PIXEL_MEMORY_vX.Y.Z/.
- Générer à la demande le FULL concaténé (et compressé) via:
  ~/pixel_memory_build_full_v1.8.5.sh

## Build (exécuté quand tu veux)
- FULL concaténé: PIXEL_MEMORY_v1.8.5_FULL.txt
- FULL compressé: PIXEL_MEMORY_v1.8.5_FULL.txt.xz
