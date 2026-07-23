# ZetBot AI Installer

Official installation script for **ZetBot AI**.

## Purpose

This repository provides the single, official installation method for
ZetBot AI. It automates environment checks, dependency installation,
repository setup, and Python environment configuration so that
installation is consistent, repeatable, and safe to run more than once.

The installer never modifies the ZetBot AI application itself and
never starts the bot — it only prepares your system to run it.

## Requirements

- One of the following Linux distributions:
  - Ubuntu
  - Debian
  - Linux Mint
- `bash`
- `sudo` privileges (only needed if dependencies must be installed)
- An active internet connection

> Support for Termux and Ubuntu Proot environments is planned for a
> future release.

## Installation

**For normal users (production, stable code):**

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash
```

**For development (tracks the `dev` branch):**

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash -s -- --branch dev
```

The installer will:

1. Detect your operating system.
2. Check your internet connection.
3. Check for and install any missing required packages (`git`, `curl`,
   `python3`, `python3-pip`, `python3-venv`).
4. Ask where to install ZetBot AI (default: `~/zetbot-ai`).
5. Clone or update the ZetBot AI repository.
6. Create a Python virtual environment (if one doesn't already exist).
7. Install Python dependencies from `requirements.txt`.
8. Create a `.env` file from `.env.example` (only if `.env` doesn't
   already exist).
9. Print an installation summary.

The installer is idempotent — running it again on an existing
installation will update the code and dependencies without
overwriting your configuration or local changes.

The installer only **installs** ZetBot AI — it does not run the
project's `setup.sh` or start the bot. After installation, review
`.env` and continue manually:

```bash
cd ~/zetbot-ai
bash setup.sh   # if provided by the project
```

## Branch Installation Examples

Install the default (`main`) branch:

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash
```

Install the `dev` branch:

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash -s -- --branch dev
```

Install the `stable` branch:

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash -s -- --branch stable
```

## Directory Selection

By default, ZetBot AI is installed to:

```
$HOME/zetbot-ai
```

During installation you will be prompted to confirm or change this
location. You can also set it non-interactively:

```bash
curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash -s -- --dir /opt/zetbot-ai --yes
```

## What install.sh Performs

- Verifies the operating system is supported.
- Verifies internet connectivity before proceeding.
- Verifies and installs required system packages, if missing.
- Prompts for (or accepts) the installation directory.
- Clones the ZetBot AI repository, or offers to update an existing
  installation without overwriting local files.
- Creates a Python virtual environment (`.venv`) only if one does not
  already exist.
- Upgrades `pip` and installs dependencies from `requirements.txt`.
- Creates `.env` from `.env.example` only if `.env` does not already
  exist — existing configuration is never overwritten.
- Never runs `setup.sh` and never starts ZetBot AI automatically —
  installation and setup are kept as separate, deliberate steps.

## Troubleshooting

**"Unable to detect operating system"**
Your system is missing `/etc/os-release`. This installer currently
targets Ubuntu, Debian, and Linux Mint.

**"No internet connection detected"**
Check your network connection and DNS settings, then re-run the
installer.

**"This script requires root privileges or sudo"**
Install `sudo`, or run the installer as root.

**Installation directory already exists and is not empty**
Choose a different directory with `--dir`, or point the installer at
an existing ZetBot AI installation to update it instead.

## License

See [LICENSE](LICENSE).
