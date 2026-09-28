#!/usr/bin/env bash
# One-time GitHub auth for: git push to jazzmonger/Victron_Cerbo_GX_local_app
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

REMOTE_SSH="git@github.com:jazzmonger/Victron_Cerbo_GX_local_app.git"
KEY="$HOME/.ssh/id_ed25519"

echo "=== GitHub push setup (SSH) ==="
echo "Repo: $REPO_ROOT"
echo

if [[ ! -f "$KEY" ]]; then
  echo "Creating SSH key at $KEY (no passphrase)."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$KEY" -N "" -C "jeffstevenson-github-mac"
else
  echo "Using existing key: $KEY"
fi

echo
echo "Add this key to GitHub (copy the whole line):"
echo "  https://github.com/settings/ssh/new"
echo
cat "${KEY}.pub"
echo
read -r -p "Press Enter after you have added the key on GitHub..."

ssh-keyscan -t ed25519,rsa github.com 2>/dev/null >> "$HOME/.ssh/known_hosts" || true

echo "Testing SSH to GitHub..."
ssh -T git@github.com || true

git remote set-url origin "$REMOTE_SSH"
echo "Remote set to: $REMOTE_SSH"
echo
git push -u origin main
echo
echo "Done."
