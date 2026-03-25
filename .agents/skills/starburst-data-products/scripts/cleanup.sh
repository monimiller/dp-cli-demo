#!/usr/bin/env bash
# Usage: cleanup.sh <product-id> <domain-id>  (requires sysadmin role on server)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
ensure_env
product_id="${1:-}"
domain_id="${2:-}"
if [[ -z "$product_id" || -z "$domain_id" ]]; then
  echo "Usage: cleanup.sh <product-id> <domain-id>"
  exit 1
fi
curl -sk -X POST \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{sysadmin}" \
  "$SERVER/api/v1/dataProduct/products/$product_id/workflows/delete?skipTrinoDelete=true"

sleep 3
curl -sk -X DELETE \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{sysadmin}" \
  "$SERVER/api/v1/dataProduct/domains/$domain_id"
