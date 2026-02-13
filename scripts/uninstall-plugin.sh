#!/usr/bin/env bash
# Uninstall the Atelier plugin

set -euo pipefail

echo "Uninstalling Atelier plugin..."

claude plugin uninstall atelier@atelier-marketplace 2>/dev/null || echo "Plugin already uninstalled"

echo "Plugin uninstalled"
echo ""
echo "To reinstall: scripts/dev-setup.sh"
