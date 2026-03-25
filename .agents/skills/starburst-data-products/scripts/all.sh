#!/usr/bin/env bash
# Runs the sample lifecycle through overwrite re-import (no publish/cleanup).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/setup.sh"
"$SCRIPT_DIR/create-domain.sh"
"$SCRIPT_DIR/init.sh"
"$SCRIPT_DIR/write-sample-yaml.sh"
"$SCRIPT_DIR/lint.sh"
"$SCRIPT_DIR/import.sh"
"$SCRIPT_DIR/export.sh"
"$SCRIPT_DIR/compare.sh"
"$SCRIPT_DIR/write-modified-yaml.sh"
"$SCRIPT_DIR/import-modified.sh"
