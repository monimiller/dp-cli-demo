#!/usr/bin/env bash
# Import from DP_MODIFIED_FILE. Set ON_DUPLICATE=OVERWRITE|FAIL (default OVERWRITE).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
ensure_env
mode="${ON_DUPLICATE:-OVERWRITE}"
if [[ "${1:-}" == "--on-duplicate" ]]; then
  mode="${2:-OVERWRITE}"
fi
starburst data-product import \
  -f "$DP_MODIFIED_FILE" \
  --server "$SERVER" \
  --user "$STARBURST_USER" \
  --password \
  --insecure \
  --role "$ROLE" \
  --on-duplicate "$mode"
