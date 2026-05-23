#!/usr/bin/env bash
# Data Product CLI - Full Lifecycle Demo
# Copy-paste each block one at a time.
# Press Enter between blocks to see results.

# ============================================================
# SETUP - Run this once to load environment variables
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/.env"
  set +a
else
  echo "Missing $SCRIPT_DIR/.env"
  echo "Create it with SERVER, ROLE, STARBURST_USER, STARBURST_PASSWORD, CLI_JAR"
  return 1 2>/dev/null || exit 1
fi

alias starburst="java -jar $CLI_JAR"
DP_FILE="$SCRIPT_DIR/data-products/demo_product.yaml"
DP_MODIFIED_FILE="$SCRIPT_DIR/data-products/demo_product.modified.yaml"

# ============================================================
# STEP 0: Create a data domain (needed once)
# ============================================================

curl -sk -X POST \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{$ROLE}" \
  -H "Content-Type: application/json" \
  -d '{"name":"CLI Demo","description":"Domain for CLI demo","schemaLocation":"iceberg_demo"}' \
  "$SERVER/api/v1/dataProduct/domains" | python3 -m json.tool

# ============================================================
# STEP 1: Init - Generate a YAML template
# ============================================================

starburst data-product init \
  --name demo_product \
  --domain "CLI Demo" \
  --catalog iceberg_demo \
  -o "$DP_FILE" \
  --force

cat "$DP_FILE"

# ============================================================
# STEP 2: Edit the YAML with a real definition
# ============================================================

cat > "$DP_FILE" << 'EOF'
apiVersion: v1
kind: DataProduct
metadata:
  name: demo_product
  catalogName: iceberg_demo
  dataDomainName: CLI Demo
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

cat "$DP_FILE"

# ============================================================
# STEP 3: Lint - Validate YAML offline (no server needed)
# ============================================================

starburst data-product lint -f "$DP_FILE"

# ============================================================
# STEP 4: Import - Create the data product on the server
# ============================================================

starburst data-product import \
  -f "$DP_FILE" \
  --server $SERVER \
  --user $STARBURST_USER \
  --password \
  --insecure \
  --role $ROLE

# Save the product ID from the output above for later steps.
# Example: PRODUCT_ID=5d7d2f9b-1748-49a8-9511-2866a99f3063

# ============================================================
# STEP 5: Export - Fetch it back as YAML (round-trip)
# ============================================================

starburst data-product export \
  --domain "CLI Demo" \
  --name demo_product \
  --server $SERVER \
  --user $STARBURST_USER \
  --password \
  --insecure \
  --role $ROLE \
  -o /tmp/demo-dp-exported.yaml \
  --force

cat /tmp/demo-dp-exported.yaml

# ============================================================
# STEP 6: Compare original vs exported
# ============================================================

diff "$DP_FILE" /tmp/demo-dp-exported.yaml || true
# (Differences expected: server adds schemaName, viewSecurityMode, exportMetadata)

# ============================================================
# STEP 7: Modify the exported YAML
# ============================================================

# Edit the file: change summary and add a column.
# For the demo, we write a modified version:

cat > "$DP_MODIFIED_FILE" << 'EOF'
apiVersion: v1
kind: DataProduct
metadata:
  name: demo_product
  catalogName: iceberg_demo
  schemaName: demo_product
  dataDomainName: CLI Demo
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

# ============================================================
# STEP 8: Re-import with --on-duplicate OVERWRITE
# ============================================================

starburst data-product import \
  -f "$DP_MODIFIED_FILE" \
  --server $SERVER \
  --user $STARBURST_USER \
  --password \
  --insecure \
  --role $ROLE \
  --on-duplicate OVERWRITE

# ============================================================
# STEP 9: Show that --on-duplicate FAIL rejects duplicates
# ============================================================

starburst data-product import \
  -f "$DP_MODIFIED_FILE" \
  --server $SERVER \
  --user $STARBURST_USER \
  --password \
  --insecure \
  --role $ROLE \
  --on-duplicate FAIL
# Expected: ERROR about duplicate product

# ============================================================
# STEP 10: Publish (via API - CLI publish not yet implemented)
# ============================================================

# Replace PRODUCT_ID with the actual ID from step 4
PRODUCT_ID=<paste-id-here>

curl -sk -X POST \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{$ROLE}" \
  "$SERVER/api/v1/dataProduct/products/$PRODUCT_ID/workflows/publish"

# Check publish status after a few seconds:
sleep 3
curl -sk \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{$ROLE}" \
  "$SERVER/api/v1/dataProduct/products/$PRODUCT_ID/workflows/publish" | python3 -m json.tool

# ============================================================
# CLEANUP: Delete product and domain
# ============================================================

# Delete requires sysadmin role
DOMAIN_ID=<paste-domain-id-from-step-0>

# Delete the data product (async workflow)
curl -sk -X POST \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{sysadmin}" \
  "$SERVER/api/v1/dataProduct/products/$PRODUCT_ID/workflows/delete?skipTrinoDelete=true"

# Wait for delete to complete, then delete the domain
sleep 3
curl -sk -X DELETE \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{sysadmin}" \
  "$SERVER/api/v1/dataProduct/domains/$DOMAIN_ID"
