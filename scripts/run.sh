#!/usr/bin/env bash
# ==============================================================================
# File        : scripts/run.sh
# Description : Generic execution wrapper for homelab-infrastructure
# Author      : SudoShea
# Version     : 1.8.4
# License     : MIT
# ==============================================================================

set -e

# Prefer local inventory override if present, fall back to default template
if [ -f "inventory.local.ini" ]; then
    INVENTORY="inventory.local.ini"
else
    INVENTORY="inventory.ini"
fi

PLAYBOOK="site.yml"

show_help() {
    echo "Usage: ./scripts/run.sh [command] [target]"
    echo ""
    echo "Commands:"
    echo "  check [host/group]    Run a dry-run (--check --diff)"
    echo "  run [host/group]      Run live playbook against a specific host or group"
    echo "  all                   Run live across all nodes in inventory"
    echo "  help                  Display this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/run.sh check"
    echo "  ./scripts/run.sh run pihole"
    echo "  ./scripts/run.sh run rhel_servers"
}

command="${1:-check}"
shift || true
target="$1"

case "$command" in
    check)
        if [ -n "$target" ]; then
            echo "Running dry-run for target: $target (using $INVENTORY)"
            ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --limit "$target" --check --diff -K
        else
            echo "Running dry-run across all nodes (using $INVENTORY)..."
            ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --check --diff -K
        fi
        ;;
    run)
        if [ -z "$target" ]; then
            echo "Error: Please specify a target host or group."
            echo "Example: ./scripts/run.sh run pihole"
            exit 1
        fi
        echo "Applying homelab stack live to target: $target (using $INVENTORY)"
        ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --limit "$target" -K
        ;;
    all)
        echo "WARNING: Applying homelab stack live across ALL nodes in $INVENTORY!"
        read -p "Are you sure? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            ansible-playbook -i "$INVENTORY" "$PLAYBOOK" -K
        else
            echo "Aborted."
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $command"
        show_help
        exit 1
        ;;
esac
