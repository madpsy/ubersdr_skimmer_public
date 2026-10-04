#!/usr/bin/env bash
# stop.sh — stop the ubersdr_skimmer service
#
# Usage:
#   ./stop.sh

set -euo pipefail

INSTALL_DIR="${HOME}/ubersdr/skimmer"

cd "${INSTALL_DIR}"
echo "Stopping ubersdr_skimmer..."
docker compose down
echo "Done."
