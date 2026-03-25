#!/usr/bin/env bash
# Writes an alternate YAML (e.g. extra column) for overwrite / round-trip exercises.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
cat > "$DP_MODIFIED_FILE" <<EOF
apiVersion: v1
kind: DataProduct
metadata:
  name: $PRODUCT_NAME
  catalogName: $CATALOG_NAME
  schemaName: $PRODUCT_NAME
  dataDomainName: $DOMAIN_NAME
  summary: Updated definition (example with extra column)
  description: |
    Example data product for init, lint, import, export, modify, re-import, and publish workflows.
owners:
  - name: Alice
    email: alice@example.com
views:
  - name: sample_orders
    description: Sample orders view
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
