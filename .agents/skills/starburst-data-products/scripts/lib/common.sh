#!/usr/bin/env bash
# Shared helpers for Starburst data product scripts. Source from scripts/*.sh only.
set -euo pipefail

_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$_LIB_DIR/.." && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"

ENV_FILE="${ENV_FILE:-$REPO_ROOT/.env}"
DP_FILE="${DP_FILE:-$REPO_ROOT/data-products/Blue Ribbon High Priority Orders.yaml}"
DP_MODIFIED_FILE="${DP_MODIFIED_FILE:-$REPO_ROOT/data-products/demo_product.modified.yaml}"
EXPORTED_FILE="${EXPORTED_FILE:-/tmp/starburst-dp-exported.yaml}"
DOMAIN_NAME="${DOMAIN_NAME:-CLI Demo}"
DOMAIN_DESCRIPTION="${DOMAIN_DESCRIPTION:-Data product domain}"
CATALOG_NAME="${CATALOG_NAME:-iceberg_demo}"
PRODUCT_NAME="${PRODUCT_NAME:-demo_product}"

ensure_env() {
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "Missing env file: $ENV_FILE"
    echo "Expected vars: SERVER ROLE STARBURST_USER STARBURST_PASSWORD CLI_JAR"
    exit 1
  fi

  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a

  local missing=0
  for var_name in SERVER ROLE STARBURST_USER STARBURST_PASSWORD CLI_JAR; do
    if [[ -z "${!var_name:-}" ]]; then
      echo "Missing required env var: $var_name"
      missing=1
    fi
  done
  if [[ "$missing" -eq 1 ]]; then
    exit 1
  fi
}

starburst() {
  java -jar "$CLI_JAR" "$@"
}
