#!/usr/bin/env bash
#
# ZetBot AI — Official Installer
# https://github.com/EVOZXLabs/zetbot-installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash -s -- --branch dev
#   curl -fsSL https://raw.githubusercontent.com/EVOZXLabs/zetbot-installer/main/install.sh | bash -s -- --install-only
#
# What this script is (and is not):
#   It is a thin BOOTSTRAPPER. It only makes sure `git` and `curl` exist,
#   then clones/updates the ZetBot AI repository and hands off to the
#   scripts that ALREADY ship inside that repository (install.sh /
#   quickstart.sh). Those scripts know how to correctly provision the
#   current state of the project (Termux package quirks, TUR repo for
#   pandas, native build deps, virtualenv, self-check, etc). This script
#   never re-implements that logic itself, so it can't drift out of sync
#   with the project again the way the previous version did.
#
# Default behavior: install AND start the bot (paper trading, safe) in
# one command, by delegating to the repo's own quickstart.sh. Pass
# --install-only if you only want the environment prepared without the
# bot starting (the old behavior of this script).
#
set -Eeuo pipefail

# ----------------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------------

readonly REPO_URL="https://github.com/EVOZXLabs/zetbot-ai.git"
readonly DEFAULT_BRANCH="main"
readonly DEFAULT_INSTALL_DIR="${HOME}/zetbot-ai"
# Only bootstrap dependencies needed to fetch the repo. Everything else
# (python, venv, pandas/numpy, native build deps, etc.) is the
# responsibility of the project's own install.sh, which is kept in sync
# with the project by the project's own maintainers/tests.
readonly BOOTSTRAP_PACKAGES=(git curl)
readonly SUPPORTED_DISTROS=(ubuntu debian linuxmint)

BRANCH="${DEFAULT_BRANCH}"
INSTALL_DIR="${DEFAULT_INSTALL_DIR}"
NONINTERACTIVE=false
IS_TERMUX=false
INSTALL_ONLY=false

# ----------------------------------------------------------------------------
# Colors & icons
# ----------------------------------------------------------------------------

if [[ -t 1 ]]; then
    readonly C_RESET='\033[0m'
    readonly C_BOLD='\033[1m'
    readonly C_RED='\033[0;31m'
    readonly C_GREEN='\033[0;32m'
    readonly C_YELLOW='\033[0;33m'
    readonly C_BLUE='\033[0;34m'
    readonly C_CYAN='\033[0;36m'
else
    readonly C_RESET=''
    readonly C_BOLD=''
    readonly C_RED=''
    readonly C_GREEN=''
    readonly C_YELLOW=''
    readonly C_BLUE=''
    readonly C_CYAN=''
fi

readonly ICON_OK="✔"
readonly ICON_FAIL="✖"
readonly ICON_WARN="⚠"
readonly ICON_INFO="ℹ"
readonly ICON_ARROW="➜"
readonly ICON_ROCKET="🚀"

# ----------------------------------------------------------------------------
# Logging helpers
# ----------------------------------------------------------------------------

log_step()    { printf '\n%b%s %s%b\n' "${C_BLUE}${C_BOLD}" "${ICON_ARROW}" "$*" "${C_RESET}"; }
log_info()    { printf '%b%s%b %s\n' "${C_CYAN}" "${ICON_INFO}" "${C_RESET}" "$*"; }
log_success() { printf '%b%s%b %s\n' "${C_GREEN}" "${ICON_OK}" "${C_RESET}" "$*"; }
log_warn()    { printf '%b%s%b %s\n' "${C_YELLOW}" "${ICON_WARN}" "${C_RESET}" "$*"; }
log_error()   { printf '%b%s%b %s\n' "${C_RED}" "${ICON_FAIL}" "${C_RESET}" "$*" >&2; }

die() {
    log_error "$*"
    exit 1
}

# ----------------------------------------------------------------------------
# Trap handlers
# ----------------------------------------------------------------------------

on_error() {
    local exit_code=$?
    local line_no=${1:-unknown}
    log_error "Installation failed at line ${line_no} (exit code ${exit_code})."
    log_error "No files were removed. You can re-run the installer safely."
    exit "${exit_code}"
}

on_exit() {
    :
}

trap 'on_error ${LINENO}' ERR
trap on_exit EXIT

# ----------------------------------------------------------------------------
# Utility: interactive prompt (works even when script is piped via stdin)
# ----------------------------------------------------------------------------

prompt() {
    local message="$1"
    local default_value="${2:-}"
    local reply=""

    if [[ "${NONINTERACTIVE}" == true ]] || [[ ! -t 0 && ! -e /dev/tty ]]; then
        printf '%s\n' "${default_value}"
        return 0
    fi

    if [[ -n "${default_value}" ]]; then
        printf '%b%s%b [%s]: ' "${C_CYAN}" "${message}" "${C_RESET}" "${default_value}" > /dev/tty
    else
        printf '%b%s%b: ' "${C_CYAN}" "${message}" "${C_RESET}" > /dev/tty
    fi

    read -r reply < /dev/tty || reply=""
    if [[ -z "${reply}" ]]; then
        reply="${default_value}"
    fi
    printf '%s\n' "${reply}"
}

confirm() {
    local message="$1"
    local default_answer="${2:-y}"
    local reply=""
    local hint="y/N"
    [[ "${default_answer}" == "y" ]] && hint="Y/n"

    if [[ "${NONINTERACTIVE}" == true ]] || [[ ! -t 0 && ! -e /dev/tty ]]; then
        reply="${default_answer}"
    else
        printf '%b%s%b (%s): ' "${C_YELLOW}" "${message}" "${C_RESET}" "${hint}" > /dev/tty
        read -r reply < /dev/tty || reply=""
        [[ -z "${reply}" ]] && reply="${default_answer}"
    fi

    case "${reply,,}" in
        y|yes) return 0 ;;
        *) return 1 ;;
    esac
}

# ----------------------------------------------------------------------------
# Argument parsing
# ----------------------------------------------------------------------------

usage() {
    cat <<EOF
ZetBot AI Installer

Usage:
  install.sh [options]

Options:
  --branch <name>       Install a specific branch (default: ${DEFAULT_BRANCH})
  --dir <path>          Installation directory (default: ${DEFAULT_INSTALL_DIR})
  --install-only        Only prepare the environment; do not start the bot
                         (by default this script installs AND starts the
                         bot in paper trading mode, one command end-to-end)
  --yes, --noninteractive
                         Accept defaults without prompting
  -h, --help             Show this help message
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --branch)
                [[ $# -ge 2 ]] || die "--branch requires a value"
                BRANCH="$2"
                shift 2
                ;;
            --branch=*)
                BRANCH="${1#*=}"
                shift
                ;;
            --dir)
                [[ $# -ge 2 ]] || die "--dir requires a value"
                INSTALL_DIR="$2"
                shift 2
                ;;
            --dir=*)
                INSTALL_DIR="${1#*=}"
                shift
                ;;
            --install-only)
                INSTALL_ONLY=true
                shift
                ;;
            --yes|--noninteractive)
                NONINTERACTIVE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "Unknown argument: $1 (use --help for usage)"
                ;;
        esac
    done
}

# ----------------------------------------------------------------------------
# Environment detection
# ----------------------------------------------------------------------------

detect_environment() {
    # Termux (Android) is detected via the TERMUX_VERSION env var that the
    # Termux app exports for every shell it spawns.
    if [[ -n "${TERMUX_VERSION:-}" ]] || [[ "${PREFIX:-}" == *"com.termux"* ]]; then
        IS_TERMUX=true
        log_success "Detected supported environment: Termux (${TERMUX_VERSION:-unknown version})"
        return 0
    fi

    detect_linux_distro
}

detect_linux_distro() {
    [[ -f /etc/os-release ]] || die "Unable to detect operating system (missing /etc/os-release)."

    # shellcheck disable=SC1091
    source /etc/os-release

    local distro_id="${ID:-unknown}"
    local distro_like="${ID_LIKE:-}"
    local supported=false

    for candidate in "${SUPPORTED_DISTROS[@]}"; do
        if [[ "${distro_id}" == "${candidate}" ]] || [[ "${distro_like}" == *"${candidate}"* ]]; then
            supported=true
            break
        fi
    done

    if [[ "${supported}" != true ]]; then
        log_warn "Detected distribution '${distro_id}' is not officially supported."
        log_warn "Supported distributions: Ubuntu, Debian, Linux Mint."
        confirm "Continue anyway?" "n" || die "Installation aborted by user."
    else
        log_success "Detected supported environment: ${NAME:-${distro_id}}"
    fi
}

# ----------------------------------------------------------------------------
# Connectivity check
# ----------------------------------------------------------------------------

check_internet() {
    log_step "Checking internet connectivity"

    if curl -fsS --max-time 5 -o /dev/null "https://github.com"; then
        log_success "Internet connection is available."
    else
        die "No internet connection detected. Please check your network and try again."
    fi
}

# ----------------------------------------------------------------------------
# Bootstrap packages (git + curl only)
#
# Everything else the project needs (python, venv, pandas/numpy via
# Termux's tur-repo, native build deps like clang/rust/openssl/libffi on
# Termux, etc.) is installed by the project's own install.sh a few steps
# down. Duplicating that package list here is exactly what went stale
# and broke installs on Termux before, so it deliberately isn't done here.
# ----------------------------------------------------------------------------

require_sudo() {
    if [[ "${IS_TERMUX}" == true ]]; then
        # Termux packages install into the app's own sandbox; there is no
        # root/sudo involved and none is needed.
        SUDO=""
    elif [[ "${EUID}" -eq 0 ]]; then
        SUDO=""
    elif command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        die "This script requires root privileges or sudo to install missing packages."
    fi
}

package_installed() {
    local pkg="$1"
    # Termux's package manager is also dpkg-based, so this check works
    # identically on both Termux and Debian-family Linux distros.
    dpkg -s "${pkg}" >/dev/null 2>&1
}

check_and_install_bootstrap_packages() {
    log_step "Verifying bootstrap packages (git, curl)"

    require_sudo

    local missing=()
    for pkg in "${BOOTSTRAP_PACKAGES[@]}"; do
        if package_installed "${pkg}"; then
            log_success "${pkg} is already installed."
        else
            log_warn "${pkg} is missing."
            missing+=("${pkg}")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_success "git and curl are present."
        return 0
    fi

    log_info "Installing missing packages: ${missing[*]}"
    if [[ "${IS_TERMUX}" == true ]]; then
        pkg update -y
        pkg install -y "${missing[@]}"
    else
        ${SUDO} apt-get update -y
        ${SUDO} apt-get install -y "${missing[@]}"
    fi
    log_success "Missing packages installed successfully."
}

# ----------------------------------------------------------------------------
# Installation directory
# ----------------------------------------------------------------------------

choose_install_dir() {
    log_step "Choosing installation directory"

    INSTALL_DIR="$(prompt "Installation directory" "${INSTALL_DIR}")"
    INSTALL_DIR="${INSTALL_DIR/#\~/${HOME}}"

    log_info "Installation directory set to: ${INSTALL_DIR}"
}

# ----------------------------------------------------------------------------
# Repository clone / update
# ----------------------------------------------------------------------------

clone_or_update_repo() {
    log_step "Setting up ZetBot AI repository (branch: ${BRANCH})"

    if [[ -d "${INSTALL_DIR}/.git" ]]; then
        log_warn "An existing installation was found at ${INSTALL_DIR}."
        if confirm "Update existing installation?" "y"; then
            log_info "Fetching latest changes..."
            git -C "${INSTALL_DIR}" fetch origin "${BRANCH}"
            git -C "${INSTALL_DIR}" checkout "${BRANCH}"
            git -C "${INSTALL_DIR}" merge --ff-only "origin/${BRANCH}"
            log_success "Repository updated successfully."
        else
            log_info "Skipping repository update. Existing files were left untouched."
        fi
    else
        if [[ -d "${INSTALL_DIR}" ]]; then
            [[ -z "$(ls -A "${INSTALL_DIR}" 2>/dev/null)" ]] || \
                die "Target directory '${INSTALL_DIR}' exists and is not a ZetBot AI installation. Choose a different directory."
        fi
        mkdir -p "${INSTALL_DIR}"
        log_info "Cloning repository into ${INSTALL_DIR}..."
        git clone --branch "${BRANCH}" "${REPO_URL}" "${INSTALL_DIR}"
        log_success "Repository cloned successfully."
    fi
}

# ----------------------------------------------------------------------------
# Delegate to the project's own scripts
#
# The zetbot-ai repository ships its own install.sh (system packages,
# venv, dependencies, .env, folders, self-check) and quickstart.sh
# (install.sh + a one-question exchange picker + starting the bot in
# paper mode). Both already correctly handle the current state of the
# project — including Termux specifics like needing tur-repo for
# python-pandas — so this script reuses them instead of re-implementing
# that logic and risking it going stale again.
# ----------------------------------------------------------------------------

run_project_install_only() {
    log_step "Running the project's own install.sh"

    if [[ ! -f "install.sh" ]]; then
        die "install.sh not found in ${INSTALL_DIR} — the repository layout may have changed."
    fi

    if ! bash install.sh; then
        die "The project's install.sh reported failures — see the output above, fix them, then re-run this installer."
    fi
}

run_project_quickstart() {
    log_step "Running the project's own quickstart.sh (install + start the bot)"

    if [[ ! -f "quickstart.sh" ]]; then
        log_warn "quickstart.sh not found in ${INSTALL_DIR} — falling back to install-only mode."
        run_project_install_only
        print_summary
        return 0
    fi

    # quickstart.sh walks up from $PWD to find the repo root, so it will
    # correctly reuse the directory we just cloned/updated into, even if
    # a custom --dir was used. It installs (via install.sh), asks a single
    # exchange question only if .env is freshly created, then execs
    # run.sh — always in PAPER_MODE=true, never live trading, never asks
    # for API keys. This call replaces the current process.
    exec bash quickstart.sh
}

# ----------------------------------------------------------------------------
# Summary (install-only mode)
# ----------------------------------------------------------------------------

print_summary() {
    printf '\n%b%s ZetBot AI installation complete!%b\n' "${C_GREEN}${C_BOLD}" "${ICON_ROCKET}" "${C_RESET}"
    printf '\n'
    printf '  %bLocation:%b %s\n' "${C_BOLD}" "${C_RESET}" "${INSTALL_DIR}"
    printf '  %bBranch:%b   %s\n' "${C_BOLD}" "${C_RESET}" "${BRANCH}"
    printf '\n'
    log_info "This installer did not start ZetBot AI (--install-only was used)."
    log_info "Review your configuration in ${INSTALL_DIR}/.env, then continue with:"
    printf '\n'
    printf '    cd %s\n' "${INSTALL_DIR}"
    printf '    bash run.sh        %b# start the bot (paper trading by default)%b\n' "${C_CYAN}" "${C_RESET}"
    printf '    bash setup.sh      %b# optional: health check / diagnostics%b\n' "${C_CYAN}" "${C_RESET}"
    printf '    bash update.sh     %b# update to the latest version later%b\n' "${C_CYAN}" "${C_RESET}"
    printf '    bash uninstall.sh  %b# remove the bot (config/data preserved)%b\n' "${C_CYAN}" "${C_RESET}"
    printf '\n'
}

# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------

main() {
    parse_args "$@"

    printf '%b%s ZetBot AI Installer%b\n' "${C_BOLD}${C_BLUE}" "${ICON_ROCKET}" "${C_RESET}"

    detect_environment
    check_internet
    check_and_install_bootstrap_packages
    choose_install_dir
    clone_or_update_repo

    cd "${INSTALL_DIR}"

    if [[ "${INSTALL_ONLY}" == true ]]; then
        run_project_install_only
        print_summary
    else
        run_project_quickstart
        # Unreachable when quickstart.sh exists (run_project_quickstart execs
        # into it). Reached only on the fallback path, where the summary was
        # already printed inside run_project_quickstart.
    fi
}

main "$@"
