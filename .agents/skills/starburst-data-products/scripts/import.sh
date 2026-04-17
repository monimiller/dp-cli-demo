#!/usr/bin/env bash
# Import data product from DP_FILE. Optional: --on-duplicate OVERWRITE|FAIL
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
ensure_env
on_duplicate=""
if [[ "${1:-}" == "--on-duplicate" ]]; then
  on_duplicate="${2:-}"
fi
args=()
if [[ -n "$on_duplicate" ]]; then
  args+=(--on-duplicate "$on_duplicate")
fi
starburst data-product import \
  -f "$DP_FILE" \
  --server "$SERVER" \
  --user "$STARBURST_USER" \
  --password \
  --insecure \
  --role "$ROLE" \
  "${args[@]+"${args[@]}"}"
