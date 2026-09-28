# Push this project to GitHub

Your commit is already on your Mac (`main`, commit `adedfec`). Pushing fails until GitHub knows who you are.

The repo exists: [jazzmonger/Victron_Cerbo_GX_local_app](https://github.com/jazzmonger/Victron_Cerbo_GX_local_app).

`secrets.yaml` is **not** in git (only `secrets.yaml.example`).

## Option A — SSH (recommended)

In **Terminal.app** (not inside a sandboxed tool):

```bash
cd '/Users/jeffstevenson/ESPHome_Projects/Cerbo_GX MQTT BLE bridge'
chmod +x scripts/setup-github-push.sh
./scripts/setup-github-push.sh
```

The script prints an SSH public key. Paste it at [GitHub → SSH keys](https://github.com/settings/ssh/new), press Enter in the terminal, then it runs `git push`.

## Option B — Personal access token (HTTPS)

1. Create a token: [GitHub → Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens) (classic: scope **repo**, or fine-grained: access to `Victron_Cerbo_GX_local_app`).
2. In Terminal:

```bash
cd '/Users/jeffstevenson/ESPHome_Projects/Cerbo_GX MQTT BLE bridge'
git remote set-url origin https://github.com/jazzmonger/Victron_Cerbo_GX_local_app.git
git push -u origin main
```

3. When prompted:
   - **Username:** `jazzmonger`
   - **Password:** paste the **token** (not your GitHub login password)

macOS Keychain (`credential.helper=osxkeychain`) should remember it for next time.

## Option C — GitHub CLI

`brew install gh` failed here without Xcode Command Line Tools. If you install CLT (`xcode-select --install`), then:

```bash
brew install gh
gh auth login
cd '/Users/jeffstevenson/ESPHome_Projects/Cerbo_GX MQTT BLE bridge'
git push -u origin main
```

## If you see a specific error

| Message | What to do |
|---------|------------|
| `could not read Username` / `Device not configured` | Use Option A or B in **Terminal.app** |
| `Permission denied (publickey)` | Add SSH key (Option A) |
| `Authentication failed` | Use a token as password (Option B), not account password |
| `Repository not found` | Log into GitHub as `jazzmonger` or fix repo name / access |

## After a successful push

Open: https://github.com/jazzmonger/Victron_Cerbo_GX_local_app
