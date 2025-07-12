#!/bin/bash

set -e

# ========== SETTINGS ==========
GITLEAKS_CONFIG_FLAG=$(git config --get gitleaks.enable)

# ========== CHECK ENABLE FLAG ==========
if [ "$GITLEAKS_CONFIG_FLAG" != "true" ]; then
  echo "[gitleaks] Skipped: enable it via 'git config gitleaks.enable true'"
  exit 0
fi

# ========== INSTALL FUNCTION ==========
install_gitleaks() {
  echo "[gitleaks] Installing Gitleaks..."

  UNAME_OUT="$(uname -s)"

  case "${UNAME_OUT}" in
      Linux*)     OS=linux;;
      Darwin*)    OS=darwin;;
      CYGWIN*|MINGW*|MSYS*) OS=windows;;
      *)          OS="unknown"
  esac

  if [ "$OS" = "linux" ]; then
    curl -s https://raw.githubusercontent.com/gitleaks/gitleaks/main/scripts/install.sh | bash

  elif [ "$OS" = "darwin" ]; then
    if command -v brew &> /dev/null; then
      brew install gitleaks
    else
      echo "[gitleaks] Homebrew not found. Using fallback installer..."
      curl -s https://raw.githubusercontent.com/gitleaks/gitleaks/main/scripts/install.sh | bash
    fi

  elif [ "$OS" = "windows" ]; then
    echo "[gitleaks] Windows detected. Please install manually:"
    echo "https://github.com/gitleaks/gitleaks/releases"
    exit 1
  else
    echo "[gitleaks] Unknown OS detected: $UNAME_OUT"
    exit 1
  fi
}

# ========== CHECK IF GITLEAKS IS INSTALLED ==========
if ! command -v gitleaks &> /dev/null; then
  install_gitleaks
fi

# ========== RUN SCAN ==========
echo "[gitleaks] Scanning your codebase..."

if ! gitleaks detect --source . --log-level error --no-banner --redact --exit-code 1; then
  echo -e "\n[gitleaks] ❌ Secrets detected! Commit rejected."
  echo "[gitleaks] Fix the issues or disable temporarily via:"
  echo "  git config gitleaks.enable false"
  exit 1
else
  echo "[gitleaks] ✅ No secrets found. Commit accepted."
  exit 0
fi
