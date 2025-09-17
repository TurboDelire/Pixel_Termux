import os

token = os.environ.get("GITHUB_TOKEN")

if token:
    print("✅ GITHUB_TOKEN est bien présent dans l'environnement.")
else:
    print("❌ Aucun GITHUB_TOKEN trouvé (vérifier config Codex).")
