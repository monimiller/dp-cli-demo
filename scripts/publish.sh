#!/usr/bin/env bash
# Publish a Starburst data product via REST.
#
# The Starburst CLI's `data-product publish` command treats HTTP 204 (the
# success response from SEP) as an error and exits non-zero. We route around
# that by POSTing to the workflow endpoint ourselves, then polling the GET on
# the same URL until the workflow finishes.
#
# Invoked by the ./starburst wrapper after it resolves --domain/--name into a
# product ID. Expects these env vars to already be set (the wrapper sources
# .env before exec'ing this script):
#   SERVER             https://<sep-host>
#   STARBURST_USER     auth username
#   STARBURST_PASSWORD auth password
#   ROLE               Trino role with publish_data_product privilege
#
# Usage: publish.sh <product-id>
set -euo pipefail

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "Usage: publish.sh <product-id>" >&2
  exit 2
fi
PRODUCT_ID="$1"

for var in SERVER STARBURST_USER STARBURST_PASSWORD ROLE; do
  if [[ -z "${!var:-}" ]]; then
    echo "publish.sh: \$$var is not set. The ./starburst wrapper should source .env first." >&2
    exit 1
  fi
done

URL="$SERVER/api/v1/dataProduct/products/$PRODUCT_ID/workflows/publish"

# Capture the HTTP status separately so we can distinguish 204 (success) from
# real errors. -w '%{http_code}' appends the code; we strip it off the body.
trigger_response="$(
  curl -sk -o /dev/null -w '%{http_code}' \
    -X POST \
    -u "$STARBURST_USER:$STARBURST_PASSWORD" \
    -H "X-Trino-Role: system=ROLE{$ROLE}" \
    "$URL"
)"

case "$trigger_response" in
  20[0-4])
    echo "Publish triggered for product $PRODUCT_ID (HTTP $trigger_response)."
    ;;
  *)
    echo "Publish trigger failed for product $PRODUCT_ID (HTTP $trigger_response)." >&2
    # Re-issue the call without -o /dev/null so the user sees any error body.
    curl -sk \
      -X POST \
      -u "$STARBURST_USER:$STARBURST_PASSWORD" \
      -H "X-Trino-Role: system=ROLE{$ROLE}" \
      "$URL" >&2 || true
    echo >&2
    exit 1
    ;;
esac

# Poll until the workflow finishes or we hit the timeout. SEP returns the
# workflow's status in the body of a GET on the same URL.
DEADLINE=$(( $(date +%s) + 60 ))
while true; do
  body="$(
    curl -sk \
      -u "$STARBURST_USER:$STARBURST_PASSWORD" \
      -H "X-Trino-Role: system=ROLE{$ROLE}" \
      "$URL"
  )"

  # Empty body means SEP is still processing — treat as in-progress.
  if [[ -z "$body" ]]; then
    status="PENDING"
  else
    status="$(
      printf '%s' "$body" | python3 -c "
import json, sys
try:
    raw = json.load(sys.stdin)
except json.JSONDecodeError:
    print('UNKNOWN')
    sys.exit(0)
print(raw.get('status') or raw.get('state') or 'UNKNOWN')
" 2>/dev/null || echo UNKNOWN
    )"
  fi

  case "$status" in
    DONE|COMPLETED|SUCCEEDED|PUBLISHED)
      echo "Publish complete: $status"
      exit 0
      ;;
    FAILED|ERROR|CANCELLED)
      echo "Publish failed: $status" >&2
      printf '%s\n' "$body" >&2
      exit 1
      ;;
    *)
      if (( $(date +%s) >= DEADLINE )); then
        echo "Publish still $status after 60s. Check SEP for final status." >&2
        printf '%s\n' "$body" >&2
        exit 1
      fi
      sleep 2
      ;;
  esac
done
