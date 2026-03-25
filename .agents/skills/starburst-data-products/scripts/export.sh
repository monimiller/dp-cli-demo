#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
ensure_env
starburst data-product export \
  --domain "$DOMAIN_NAME" \
  --name "$PRODUCT_NAME" \
  --server "$SERVER" \
  --user "$STARBURST_USER" \
  --password \
  --insecure \
  --role "$ROLE" \
  -o "$EXPORTED_FILE" \
  --force
