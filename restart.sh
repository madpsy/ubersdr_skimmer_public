#!/usr/bin/env bash
# restart.sh — restart the ubersdr_skimmer service
#
# Usage:
#   ./restart.sh

set -euo pipefail

INSTALL_DIR="${HOME}/ubersdr/skimmer"

cd "${INSTALL_DIR}"
echo "Stopping ubersdr_skimmer..."
docker compose down
echo "Starting ubersdr_skimmer..."
docker compose up -d --remove-orphans
echo "Done."
echo "  View logs : docker compose logs -f"
