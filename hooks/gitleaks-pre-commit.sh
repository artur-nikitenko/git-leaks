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

  # Linux or macOS: use install.sh
  if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
    curl -s https://raw.githubusercontent.com/gitleaks/gitleaks/main/scripts/install.sh | bash
    export PATH=$PATH:$HOME/.gitleaks/bin

  # Windows Git Bash or WSL
  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    echo "[gitleaks] Windows detected. Please install Gitleaks manually:"
    echo "https://github.com/gitleaks/gitleaks/releases"
    exit 1
  else
    echo "[gitleaks] Unknown OS: $OSTYPE. Please install manually."
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
