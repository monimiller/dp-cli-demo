#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
ensure_env
curl -sk -X POST \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{$ROLE}" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$DOMAIN_NAME\",\"description\":\"$DOMAIN_DESCRIPTION\",\"schemaLocation\":\"$CATALOG_NAME\"}" \
  "$SERVER/api/v1/dataProduct/domains" | python3 -m json.tool
