import os
token = os.environ.get("GITHUB_TOKEN")
print("Has GITHUB_TOKEN:", bool(token))
if token:
    print("Premiers caractères du token:", token[:8] + "****")
else:
    print("Aucun token trouvé dans l'environnement (codex).")
