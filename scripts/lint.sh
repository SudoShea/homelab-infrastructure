#!/usr/bin/env bash
# ==============================================================================
# Script      : scripts/lint.sh
# Description : Local Ansible static analysis and syntax verification wrapper
# Author      : SudoShea
# Version     : 1.11.0
# Licence     : MIT
# ==============================================================================
set -euo pipefail

# ANSI Colour Formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

echo -e "${BLUE}[INFO] Starting local Ansible linting and syntax checks...${NC}"

# Handle Vault Passwords safely without modifying your local workspace
if [[ -f ".vault_pass" ]]; then
    echo -e "${BLUE}[INFO] Using existing local .vault_pass file...${NC}"
    VAULT_FILE=".vault_pass"
else
    echo -e "${BLUE}[INFO] No .vault_pass found. Using ephemeral temporary vault file for linting...${NC}"
    TMP_VAULT=$(mktemp /tmp/vault_pass.XXXXXX)
    echo "dummy_ci_vault_password" > "$TMP_VAULT"
    # Automatically remove temporary file on script exit
    trap 'rm -f "$TMP_VAULT"' EXIT
    VAULT_FILE="$TMP_VAULT"
fi

export ANSIBLE_VAULT_PASSWORD_FILE="$VAULT_FILE"

# Ensure tools are installed
if ! command -v ansible-lint &> /dev/null; then
    echo -e "${RED}[ERROR] 'ansible-lint' command not found.${NC}"
    exit 1
fi

if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${RED}[ERROR] 'ansible-playbook' command not found.${NC}"
    exit 1
fi

echo -e "${BLUE}[INFO] Step 1/2: Executing ansible-lint static analysis...${NC}"
if ansible-lint; then
    echo -e "${GREEN}[SUCCESS] ansible-lint passed cleanly!${NC}"
else
    echo -e "${RED}[FAILURE] ansible-lint detected rule violations above.${NC}"
    exit 1
fi

echo -e "${BLUE}[INFO] Step 2/2: Executing playbook syntax verification...${NC}"
if ansible-playbook site.yml --syntax-check; then
    echo -e "${GREEN}[SUCCESS] Playbook syntax check passed!${NC}"
else
    echo -e "${RED}[FAILURE] Playbook syntax check failed.${NC}"
    exit 1
fi

echo -e "${GREEN}[SUCCESS] All local checks passed!${NC}"
