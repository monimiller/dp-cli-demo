#!/usr/bin/env bash
# Usage: publish.sh <product-id>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
ensure_env
product_id="${1:-${PRODUCT_ID:-}}"
if [[ -z "$product_id" ]]; then
  echo "Usage: publish.sh <product-id>"
  exit 1
fi
curl -sk -X POST \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{$ROLE}" \
  "$SERVER/api/v1/dataProduct/products/$product_id/workflows/publish"

sleep 3
curl -sk \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{$ROLE}" \
  "$SERVER/api/v1/dataProduct/products/$product_id/workflows/publish" | python3 -m json.tool
