#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"
ENV_FILE="${ENV_FILE:-$REPO_ROOT/.env}"

DP_FILE="${DP_FILE:-$REPO_ROOT/data-products/demo_product.yaml}"
DP_MODIFIED_FILE="${DP_MODIFIED_FILE:-$REPO_ROOT/data-products/demo_product.modified.yaml}"
EXPORTED_FILE="${EXPORTED_FILE:-/tmp/demo-dp-exported.yaml}"
DOMAIN_NAME="${DOMAIN_NAME:-CLI Demo}"
CATALOG_NAME="${CATALOG_NAME:-iceberg_demo}"
PRODUCT_NAME="${PRODUCT_NAME:-demo_product}"

usage() {
  cat <<'EOF'
Usage:
  run-demo.sh all
  run-demo.sh setup
  run-demo.sh create-domain
  run-demo.sh init
  run-demo.sh write-demo-yaml
  run-demo.sh lint
  run-demo.sh import [--on-duplicate OVERWRITE|FAIL]
  run-demo.sh export
  run-demo.sh compare
  run-demo.sh write-modified-yaml
  run-demo.sh publish --product-id <id>
  run-demo.sh cleanup --product-id <id> --domain-id <id>

Optional environment variables:
  ENV_FILE, DP_FILE, DP_MODIFIED_FILE, EXPORTED_FILE
  DOMAIN_NAME, CATALOG_NAME, PRODUCT_NAME
EOF
}

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

step_setup() {
  ensure_env
  echo "Environment loaded from $ENV_FILE"
}

step_create_domain() {
  ensure_env
  curl -sk -X POST \
    -u "$STARBURST_USER:$STARBURST_PASSWORD" \
    -H "X-Trino-Role: system=ROLE{$ROLE}" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$DOMAIN_NAME\",\"description\":\"Domain for CLI demo\",\"schemaLocation\":\"$CATALOG_NAME\"}" \
    "$SERVER/api/v1/dataProduct/domains" | python3 -m json.tool
}

step_init() {
  ensure_env
  starburst data-product init \
    --name "$PRODUCT_NAME" \
    --domain "$DOMAIN_NAME" \
    --catalog "$CATALOG_NAME" \
    -o "$DP_FILE" \
    --force
}

step_write_demo_yaml() {
  cat > "$DP_FILE" <<EOF
apiVersion: v1
kind: DataProduct
metadata:
  name: $PRODUCT_NAME
  catalogName: $CATALOG_NAME
  dataDomainName: $DOMAIN_NAME
  summary: A demo data product created via the starburst CLI
  description: |
    This data product demonstrates the full lifecycle of data-products-as-code:
    init, lint, import, export, modify, re-import, and publish.
owners:
  - name: Alice
    email: alice@example.com
views:
  - name: sample_orders
    description: A sample orders view for demo purposes
    definitionQuery: |
      SELECT
        orderkey,
        custkey,
        orderstatus,
        totalprice,
        orderdate
      FROM tpch.tiny.orders
    columns:
      - name: orderkey
        type: bigint
        description: Order identifier
      - name: custkey
        type: bigint
        description: Customer identifier
      - name: orderstatus
        type: varchar
        description: Status of the order
      - name: totalprice
        type: double
        description: Total price of the order
      - name: orderdate
        type: date
        description: Date the order was placed
EOF
}

step_lint() {
  ensure_env
  starburst data-product lint -f "$DP_FILE"
}

step_import() {
  ensure_env
  local on_duplicate="${1:-}"
  local args=()
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
    "${args[@]}"
}

step_export() {
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
}

step_compare() {
  diff "$DP_FILE" "$EXPORTED_FILE" || true
}

step_write_modified_yaml() {
  cat > "$DP_MODIFIED_FILE" <<EOF
apiVersion: v1
kind: DataProduct
metadata:
  name: $PRODUCT_NAME
  catalogName: $CATALOG_NAME
  schemaName: $PRODUCT_NAME
  dataDomainName: $DOMAIN_NAME
  summary: Updated via overwrite - added orderpriority column
  description: |
    This data product demonstrates the full lifecycle of data-products-as-code:
    init, lint, import, export, modify, re-import, and publish.
owners:
  - name: Alice
    email: alice@example.com
views:
  - name: sample_orders
    description: A sample orders view for demo purposes
    viewSecurityMode: DEFINER
    definitionQuery: |-
      SELECT
        orderkey,
        custkey,
        orderstatus,
        totalprice,
        orderdate,
        orderpriority
      FROM tpch.tiny.orders
    columns:
      - name: orderkey
        type: bigint
        description: Order identifier
      - name: custkey
        type: bigint
        description: Customer identifier
      - name: orderstatus
        type: varchar
        description: Status of the order
      - name: totalprice
        type: double
        description: Total price of the order
      - name: orderdate
        type: date
        description: Date the order was placed
      - name: orderpriority
        type: varchar
        description: Priority of the order
EOF
}

step_import_modified() {
  ensure_env
  local mode="${1:-OVERWRITE}"
  starburst data-product import \
    -f "$DP_MODIFIED_FILE" \
    --server "$SERVER" \
    --user "$STARBURST_USER" \
    --password \
    --insecure \
    --role "$ROLE" \
    --on-duplicate "$mode"
}

step_publish() {
  ensure_env
  local product_id="${1:-}"
  if [[ -z "$product_id" ]]; then
    echo "Missing required --product-id"
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
}

step_cleanup() {
  ensure_env
  local product_id="${1:-}"
  local domain_id="${2:-}"
  if [[ -z "$product_id" || -z "$domain_id" ]]; then
    echo "Missing required --product-id and/or --domain-id"
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
}

parse_kv_arg() {
  local expected="$1"
  local provided="${2:-}"
  if [[ "$provided" != "$expected" ]]; then
    echo "Expected argument: $expected"
    exit 1
  fi
}

main() {
  local command="${1:-}"
  if [[ -z "$command" ]]; then
    usage
    exit 1
  fi
  shift || true

  case "$command" in
    all)
      step_setup
      step_create_domain
      step_init
      step_write_demo_yaml
      step_lint
      step_import
      step_export
      step_compare
      step_write_modified_yaml
      step_import_modified OVERWRITE
      ;;
    setup) step_setup ;;
    create-domain) step_create_domain ;;
    init) step_init ;;
    write-demo-yaml) step_write_demo_yaml ;;
    lint) step_lint ;;
    import)
      local mode=""
      if [[ "${1:-}" == "--on-duplicate" ]]; then
        mode="${2:-}"
      fi
      step_import "$mode"
      ;;
    export) step_export ;;
    compare) step_compare ;;
    write-modified-yaml) step_write_modified_yaml ;;
    publish)
      parse_kv_arg "--product-id" "${1:-}"
      step_publish "${2:-}"
      ;;
    cleanup)
      parse_kv_arg "--product-id" "${1:-}"
      local pid="${2:-}"
      parse_kv_arg "--domain-id" "${3:-}"
      local did="${4:-}"
      step_cleanup "$pid" "$did"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
