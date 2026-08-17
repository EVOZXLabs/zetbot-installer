# ZetBot AI Installer

Official one-click installation script for **ZetBot AI**.

## Purpose

This repository provides the single, official installation method for
ZetBot AI. One command, zero manual steps — from nothing to a running
trading bot on Termux (Android) or a Linux VPS.

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash
```

## What It Does

The installer will:

1. Detect your environment (Termux, Ubuntu, Debian, Linux Mint).
2. Check internet connectivity.
3. Install required system packages (git, python, prebuilt numpy/pandas).
4. Clone or update the ZetBot AI repository (`~/zetbot-ai`).
5. Create a Python virtual environment.
6. Install Python dependencies (handles Termux build quirks automatically).
7. Create required data folders (`data/`, `logs/`, `backups/`).
8. Create a `.env` file with interactive exchange selection.
9. Create an optional Termux:Widget shortcut (Termux only).
10. Run a self-check to verify everything is ready.

After installation, review `.env` and start the bot:

```bash
cd ~/zetbot-ai
nano .env        # edit credentials (API keys, Telegram token, etc.)
bash run.sh      # start the bot
```

## Requirements

- **Termux** (Android) — primary target
- **Ubuntu / Debian / Linux Mint** — supported
- An active internet connection

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash
```

### Non-interactive (skip prompts)

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash -s -- --yes
```

### Custom install directory

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash -s -- --dir /opt/zetbot-ai
```

### Specific branch

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash -s -- --branch main
```

## Options

| Flag | Description |
|------|-------------|
| `--branch <name>` | Install a specific branch (default: `main`) |
| `--dir <path>` | Installation directory (default: `~/zetbot-ai`) |
| `--yes`, `--noninteractive` | Accept all defaults without prompting |
| `-h`, `--help` | Show help message |

## Idempotency

The installer is safe to re-run. Existing `.env`, `.venv`, `data/`, and
local changes are never overwritten. Re-running updates code and
dependencies.

## Troubleshooting

**"failed wheel build" on Termux**
The installer handles this automatically — numpy/pandas are installed
as prebuilt packages via `pkg` instead of compiling from source. If you
still see this error, re-run: `rm -rf ~/zetbot-ai && curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash`

**"No internet connection detected"**
Check your network and DNS settings, then re-run.

**"Python >= 3.10 is required"**
Install a newer Python version. On Termux: `pkg install python`

## License

See [LICENSE](LICENSE).
