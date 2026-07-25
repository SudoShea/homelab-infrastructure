#!/usr/bin/env bash
# ==============================================================================
# Script      : bump-version.sh
# Description : Automated version and date header update tool for repository files
# Author      : SudoShea
# Version     : 1.0.0
# License     : MIT
# ==============================================================================
set -euo pipefail

# Ensure running from Git repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

echo "=========================================="
echo "  Homelab Infrastructure Version Bump Tool"
echo "=========================================="

# Detect current version from repo headers
CURRENT_VER=$(grep -Er -m 1 "Version\s*[:=]\s*v?[0-9]+\.[0-9]+\.[0-9]+" . | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -n 1 || echo "unknown")
echo "Current detected version: v${CURRENT_VER}"
echo ""

# Get target version from argument or prompt user
NEW_VER="${1:-}"
if [[ -z "$NEW_VER" ]]; then
  read -rp "Enter new version (e.g. 1.6.0 or v1.6.0): " NEW_VER
fi

# Normalize version string (strip leading 'v')
CLEAN_VER=$(echo "$NEW_VER" | sed 's/^v//')
TODAY=$(date +%Y-%m-%d)

if [[ -z "$CLEAN_VER" ]]; then
  echo "Error: Version string cannot be empty."
  exit 1
fi

echo ""
echo "Updating files to Version v${CLEAN_VER} (Date: ${TODAY})..."
echo "------------------------------------------"

# Target both tracked (--cached) AND untracked (--others) files, respecting .gitignore (--exclude-standard)
FILES=$(git ls-files --cached --others --exclude-standard \
  ':(glob)**/*.md' ':(glob)**/*.yml' ':(glob)**/*.yaml' \
  ':(glob)**/*.sh' ':(glob)**/*.toml' ':(glob)**/*.conf' \
  ':(glob)**/*.ini' ':(glob)**/*.j2' ':(glob)**/*.json' 2>/dev/null)

COUNT=0
for FILE in $FILES; do
  # Skip this script to prevent self-modification buffer errors
  [[ "$FILE" == *"bump-version.sh"* ]] && continue

  # 1. Standard Comment Block Headers (e.g. "# Version     : 1.5.0")
  sed -i -E "s/(#?\s*Version\s*[:=]\s*v?)[0-9]+\.[0-9]+\.[0-9]+/\1${CLEAN_VER}/gI" "$FILE"

  # 2. Markdown Headers (e.g. "* **Version:** 1.5.0")
  sed -i -E "s/(\*?\s*\*\*Version:\*\*\s*v?)[0-9]+\.[0-9]+\.[0-9]+/\1${CLEAN_VER}/gI" "$FILE"

  # 3. Standard Comment Date Headers (e.g. "# Last Updated : YYYY-MM-DD")
  sed -i -E "s/(#?\s*Last Updated\s*[:=]\s*)[0-9]{4}-[0-9]{2}-[0-9]{2}/\1${TODAY}/gI" "$FILE"

  # 4. Markdown Date Headers (e.g. "* **Last Updated:** YYYY-MM-DD")
  sed -i -E "s/(\*?\s*\*\*Last Updated:\*\*\s*)[0-9]{4}-[0-9]{2}-[0-9]{2}/\1${TODAY}/gI" "$FILE"

  COUNT=$((COUNT + 1))
done

echo "Successfully scanned and updated ${COUNT} files!"
echo ""
echo "Current Git Repository Status:"
echo "------------------------------------------"
git status --short
