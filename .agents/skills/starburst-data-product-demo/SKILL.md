---
name: starburst-data-product-demo
description: Runs a Starburst data product lifecycle CLI demo including domain creation, init, lint, import/export round-trip, duplicate handling, publish, and cleanup. Use when the user asks to demo or automate Starburst data-product workflows from YAML or shell script steps.
---

# Starburst Data Product Demo

## When To Use

Use this skill when working on:
- Starburst `data-product` CLI demonstrations
- converting copy-paste demo commands into repeatable script execution
- data product lifecycle validation (init, lint, import, export, publish)

## Prerequisites

- `.env` file exists at repo root (or set `ENV_FILE`) with:
  - `SERVER`
  - `ROLE`
  - `STARBURST_USER`
  - `STARBURST_PASSWORD`
  - `CLI_JAR`
- Required tools in PATH: `java`, `curl`, `python3`
- Starburst CLI JAR is reachable via `CLI_JAR`

## Files In This Skill

- Main runner: `scripts/run-demo.sh`
- Additional notes: `reference.md`

## Default Data Files

- Source YAML: `data-products/demo_product.yaml`
- Modified YAML: `data-products/demo_product.modified.yaml`
- Export target: `/tmp/demo-dp-exported.yaml`

## Command Workflow

Run full demo up to overwrite re-import:

```bash
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh all
```

Run individual steps:

```bash
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh setup
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh create-domain
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh init
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh write-demo-yaml
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh lint
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh import
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh export
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh compare
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh write-modified-yaml
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh import --on-duplicate OVERWRITE
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh import --on-duplicate FAIL
```

Publish and cleanup require IDs from API or CLI output:

```bash
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh publish --product-id <product-id>
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh cleanup --product-id <product-id> --domain-id <domain-id>
```

## Safety Notes

- `cleanup` uses `sysadmin` role and permanently deletes demo resources.
- `import --on-duplicate FAIL` is expected to error if product already exists.
- Keep credentials in `.env`; do not hardcode secrets in scripts.

## Troubleshooting

If any step fails, check common fixes in `reference.md`.
