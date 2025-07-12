#!/bin/bash

set -e

# ========== CONFIG CHECK ==========
GITLEAKS_CONFIG_FLAG=$(git config --get gitleaks.enable)

if [ "$GITLEAKS_CONFIG_FLAG" != "true" ]; then
  echo "[gitleaks] Skipped: enable it via 'git config gitleaks.enable true'"
  exit 0
fi

# ========== INSTALL FUNCTION ==========
install_gitleaks() {
  echo "[gitleaks] Installing Gitleaks..."

  VERSION="v8.27.2"
  BASE_URL="https://github.com/gitleaks/gitleaks/releases/download/${VERSION}"

  UNAME_OS="$(uname -s)"
  UNAME_ARCH="$(uname -m)"

  case "$UNAME_OS" in
    Linux) OS="linux";;
    Darwin) OS="darwin";;
    MINGW*|MSYS*|CYGWIN*|Windows_NT) OS="windows";;
    *) echo "[gitleaks] Unsupported OS: $UNAME_OS"; exit 1;;
  esac

  case "$UNAME_ARCH" in
    x86_64|amd64) ARCH="x64";;
    arm64|aarch64) ARCH="arm64";;
    *) echo "[gitleaks] Unsupported architecture: $UNAME_ARCH"; exit 1;;
  esac

  INSTALL_DIR="$HOME/.gitleaks/bin"
  mkdir -p "$INSTALL_DIR"

  if [ "$OS" = "darwin" ]; then
    if command -v brew &> /dev/null; then
      echo "[gitleaks] Installing via Homebrew..."
      brew install gitleaks
      return
    else
      echo "[gitleaks] Homebrew not found. Please install it: https://brew.sh/"
      exit 1
    fi
  fi

  FILENAME="gitleaks_${VERSION#v}_${OS}_${ARCH}"

  if [ "$OS" = "windows" ]; then
    curl -sLo "$INSTALL_DIR/gitleaks.exe" "${BASE_URL}/${FILENAME}.exe"
    chmod +x "$INSTALL_DIR/gitleaks.exe"
    GITLEAKS_BIN="$INSTALL_DIR/gitleaks.exe"
  else
    curl -sL "${BASE_URL}/${FILENAME}.tar.gz" | tar -xz -C "$INSTALL_DIR"
    GITLEAKS_BIN="$INSTALL_DIR/gitleaks"
  fi

  export PATH="$INSTALL_DIR:$PATH"
  echo "[gitleaks] Installed to $GITLEAKS_BIN"
}

# ========== INSTALL IF MISSING ==========
if ! command -v gitleaks &> /dev/null; then
  install_gitleaks
fi

# ========== SCAN ==========
echo "[gitleaks] Scanning staged changes..."

FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$FILES" ]; then
  echo "[gitleaks] No files staged for commit."
  exit 0
fi

LEAKS_FOUND=0

for FILE in $FILES; do
  if [ -f "$FILE" ]; then
    git show ":$FILE" | gitleaks detect --pipe --no-banner --redact --exit-code 1 > /dev/null 2>&1 || LEAKS_FOUND=1
  fi
done

if [ "$LEAKS_FOUND" -eq 1 ]; then
  echo -e "\n[gitleaks] ❌ Secrets detected in staged files! Commit rejected."
  echo "[gitleaks] Fix the issues or disable temporarily via:"
  echo "  git config gitleaks.enable false"
  exit 1
else
  echo "[gitleaks] ✅ No secrets found. Commit accepted."
  exit 0
fi
