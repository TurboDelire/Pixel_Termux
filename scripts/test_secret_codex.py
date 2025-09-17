import os
print("✅ GITHUB_TOKEN présent" if os.environ.get("GITHUB_TOKEN") else "❌ GITHUB_TOKEN absent")
