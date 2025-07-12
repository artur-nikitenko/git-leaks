# Gitleaks Git Pre-Commit Hook

Pre-commit Git hook that automatically runs Gitleaks to scan for secrets before each commit.

## 🚀 Features

- Auto-installs Gitleaks for Linux/macOS
- Skips scan unless explicitly enabled
- Rejects commit if secrets like API keys or tokens are found

## 🛠 Installation

1. Enable Gitleaks scan in your Git repo:
```bash
   git config gitleaks.enable true
```
2.	Install the hook into .git/hooks/pre-commit:
```bash
curl -s https://raw.githubusercontent.com/artur-nikitenko/git-leaks/refs/heads/main/hooks/gitleaks-pre-commit.sh -o .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```
