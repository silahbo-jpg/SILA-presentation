#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "Running Bash smoke test (dry-run)..."
./scripts/generate_epic_svgs.sh --compress --keep 1 --dry-run --short-run
RC=$?
if [[ $RC -ne 0 ]]; then
  echo "Bash smoke failed: exit $RC"
  exit 3
fi

echo "Bash smoke: OK"
tail -n 200 logs/last-run.log || true

exit 0
