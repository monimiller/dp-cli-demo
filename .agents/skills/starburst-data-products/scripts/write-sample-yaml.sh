#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
cat > "$DP_FILE" <<EOF
apiVersion: v1
kind: DataProduct
metadata:
  name: $PRODUCT_NAME
  catalogName: $CATALOG_NAME
  dataDomainName: $DOMAIN_NAME
  summary: Sample data product defined as YAML for the Starburst CLI
  description: |
    Example data product for init, lint, import, export, modify, re-import, and publish workflows.
owners:
  - name: Alice
    email: alice@example.com
views:
  - name: sample_orders
    description: Sample orders view
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
