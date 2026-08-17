# ZetBot AI Installer

Official bootstrap script for **ZetBot AI**.

## Purpose

This repository provides the single, official entry point for installing
**and starting** ZetBot AI with one command, on Termux (Android) or a
Linux VPS.

It is intentionally a *thin bootstrapper*: it only makes sure `git` and
`curl` are available, clones (or updates) the
[zetbot-ai](https://github.com/EVOZXLabs/zetbot-ai) repository, then hands
off to that repository's own `install.sh` / `quickstart.sh`. Those scripts
already know how to correctly provision the current state of the project
(Termux package quirks such as needing `tur-repo` for `python-pandas`,
native build dependencies, the Python virtualenv, `.env` setup, and a
self-check). This installer never re-implements that logic, so it can't
drift out of sync with the project the way a duplicated package list
eventually does.

## Requirements

- One of the following Linux distributions:
  - Ubuntu
  - Debian
  - Linux Mint
- Termux (Android)
- `bash`
- `sudo` privileges (only needed if `git`/`curl` must be installed; not
  required on Termux)
- An active internet connection

> Ubuntu Proot support is planned for a future release.

## Installation

**One command — install and start the bot (paper trading, safe):**

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash
```

This clones ZetBot AI, installs everything it needs for the current
Termux/Linux environment, creates `.env` (paper trading by default — no
real funds, no API key required), and starts the bot. On a fresh `.env`
you'll be asked one simple question (Indodax/IDR or Binance/USDT); an
existing `.env` is never touched.

**Prepare the environment only, without starting the bot:**

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash -s -- --install-only
```

**For development (tracks the `dev` branch):**

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash -s -- --branch dev
```

You can combine flags, e.g.:

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash -s -- --dir /opt/zetbot-ai --install-only --yes
```

### What install.sh does

1. Detects your operating system (Termux / Ubuntu / Debian / Linux Mint).
2. Checks your internet connection.
3. Installs `git` and `curl` if missing — nothing else. All project
   dependencies (Python, virtualenv, `pandas`/`numpy`, native build
   tooling, etc.) are installed by the cloned repo's own `install.sh`,
   which is kept in sync with the project itself.
4. Asks where to install ZetBot AI (default: `~/zetbot-ai`).
5. Clones the repository, or safely fast-forwards an existing
   installation without overwriting your `.env` or local changes.
6. Runs the project's own `install.sh` (system packages, virtualenv,
   dependencies, `.env`, data folders, self-check).
7. **By default**, also runs the project's own `quickstart.sh`, which
   asks one question for a fresh `.env` (exchange choice) and starts the
   bot in paper trading mode. Pass `--install-only` to skip this step.

The installer is idempotent — running it again on an existing
installation updates the code and dependencies without overwriting your
configuration or local data.

## Options

| Flag | Description |
|---|---|
| `--branch <name>` | Install a specific branch (default: `main`) |
| `--dir <path>` | Installation directory (default: `~/zetbot-ai`) |
| `--install-only` | Prepare the environment but don't start the bot |
| `--yes`, `--noninteractive` | Accept defaults without prompting |
| `-h`, `--help` | Show help |

## After installation

If you used `--install-only`, or want to manage the bot afterward:

```bash
cd ~/zetbot-ai
bash run.sh        # start the bot (paper trading by default)
bash setup.sh       # optional: health check / diagnostics
bash update.sh      # update to the latest version
bash uninstall.sh   # remove the bot (config/data preserved)
nano .env           # edit exchange / Telegram credentials
```

## Troubleshooting

**"Unable to detect operating system"**
Your system is missing `/etc/os-release`. This installer currently
targets Ubuntu, Debian, Linux Mint, and Termux.

**"No internet connection detected"**
Check your network connection and DNS settings, then re-run the
installer.

**"This script requires root privileges or sudo"**
Install `sudo`, or run the installer as root (not needed on Termux).

**Installation directory already exists and is not empty**
Choose a different directory with `--dir`, or point the installer at an
existing ZetBot AI installation to update it instead.

**Something failed inside the project's own `install.sh`/`quickstart.sh`**
Those steps print a detailed PASS/FAIL report. Fix what's listed, then
re-run this installer (or `bash install.sh` / `bash quickstart.sh`
directly from inside `~/zetbot-ai`) — both are safe to re-run.

## License

See [LICENSE](LICENSE).
