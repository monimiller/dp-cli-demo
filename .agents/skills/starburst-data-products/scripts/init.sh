#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
ensure_env
starburst data-product init \
  --name "$PRODUCT_NAME" \
  --domain "$DOMAIN_NAME" \
  --catalog "$CATALOG_NAME" \
  -o "$DP_FILE" \
  --force
