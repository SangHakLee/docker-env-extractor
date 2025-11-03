#!/bin/sh
# shellcheck shell=dash
# gcloud-env-extractor installer

set -e

# Some shells don't have `local`. Alias it to `typeset` if needed.
has_local() {
    # shellcheck disable=SC2034
    local _has_local
}
has_local 2>/dev/null || alias local=typeset

VERSION="1.0.0"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="gcloud-env-extractor"
INSTALL_PATH="$INSTALL_DIR/$BINARY_NAME"

# GitHub repository URL (update this with your actual repository)
REPO_URL="https://raw.githubusercontent.com/sanghaklee/gcloud-env-extractor/master"
SCRIPT_URL="$REPO_URL/run.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Helper functions
check_cmd() {
    command -v "$1" > /dev/null 2>&1
}

need_cmd() {
    if ! check_cmd "$1"; then
        printf "${RED}❌ Error: need '%s' (command not found)${NC}\n" "$1" >&2
        exit 1
    fi
}

say() {
    printf "%s\n" "$1"
}

err() {
    printf "${RED}ERROR${NC}: %s\n" "$1" >&2
    exit 1
}

# Check if running as root for installation
check_root() {
    if [ "$(id -u)" -ne 0 ] && [ ! -w "$INSTALL_DIR" ]; then
        say "$(printf "${YELLOW}⚠️  This script requires sudo privileges to install to $INSTALL_DIR${NC}")"
        say "$(printf "${BLUE}💡 Re-running with sudo...${NC}")"
        exec sudo "$0" "$@"
    fi
}

# Uninstall function
uninstall() {
    say "$(printf "${CYAN}Uninstalling gcloud-env-extractor...${NC}")"

    if [ -f "$INSTALL_PATH" ]; then
        rm -f "$INSTALL_PATH"
        say "$(printf "${GREEN}✅ Successfully uninstalled gcloud-env-extractor${NC}")"
        say "$(printf "${BLUE}   Removed: $INSTALL_PATH${NC}")"
    else
        say "$(printf "${YELLOW}⚠️  gcloud-env-extractor is not installed${NC}")"
        exit 1
    fi
}

# Install function
install() {
    say "$(printf "${CYAN}Installing gcloud-env-extractor v${VERSION}...${NC}")"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check required commands
    need_cmd curl
    need_cmd mktemp
    need_cmd chmod
    need_cmd mkdir
    need_cmd rm
    need_cmd cp

    # Create temp directory
    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT

    # Download the script
    say "$(printf "${BLUE}📥 Downloading script...${NC}")"
    if ! curl -fsSL "$SCRIPT_URL" -o "$TMP_DIR/run.sh"; then
        err "Failed to download script from $SCRIPT_URL"
    fi

    # Verify download
    if [ ! -s "$TMP_DIR/run.sh" ]; then
        err "Downloaded file is empty"
    fi

    # Install to target directory
    say "$(printf "${BLUE}📦 Installing to $INSTALL_PATH...${NC}")"
    cp "$TMP_DIR/run.sh" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"

    # Verify installation
    if [ -x "$INSTALL_PATH" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        say "$(printf "${GREEN}✅ Successfully installed gcloud-env-extractor!${NC}")"
        echo ""
        say "$(printf "${YELLOW}Quick Start:${NC}")"
        printf "  ${CYAN}gcloud-env-extractor check 8080${NC}       # Check port status\n"
        printf "  ${CYAN}gcloud-env-extractor add 8080${NC}         # Add port rule\n"
        printf "  ${CYAN}gcloud-env-extractor list${NC}             # List Docker rules\n"
        printf "  ${CYAN}gcloud-env-extractor help${NC}             # Show help\n"
        echo ""
        say "$(printf "${BLUE}💡 Run 'gcloud-env-extractor help' for more information${NC}")"
    else
        err "Installation failed"
    fi
}

# Main
main() {
    case "${1:-}" in
        --uninstall|-u)
            check_root "$@"
            uninstall
            ;;
        --help|-h)
            echo "gcloud-env-extractor installer v${VERSION}"
            echo ""
            echo "Usage:"
            echo "  $0              Install gcloud-env-extractor"
            echo "  $0 --uninstall  Uninstall gcloud-env-extractor"
            echo "  $0 --help       Show this help"
            echo ""
            echo "Quick install:"
            echo "  curl -LsSf $REPO_URL/install.sh | sh"
            echo ""
            echo "Uninstall:"
            echo "  curl -LsSf $REPO_URL/install.sh | sh -s -- --uninstall"
            ;;
        *)
            check_root "$@"
            install
            ;;
    esac
}

main "$@"