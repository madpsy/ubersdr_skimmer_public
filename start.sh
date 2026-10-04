#!/usr/bin/env bash
# start.sh — start the ubersdr_skimmer service
#
# Usage:
#   ./start.sh

set -euo pipefail

INSTALL_DIR="${HOME}/ubersdr/skimmer"

cd "${INSTALL_DIR}"
echo "Starting ubersdr_skimmer..."
docker compose up -d --remove-orphans
echo "Done."
echo "  View logs : docker compose logs -f"
