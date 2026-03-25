---
name: starburst-data-products
description: Guides Starburst data-products-as-code workflows using the CLI and REST API—domains, init, lint, import, export, duplicate handling, publish, and cleanup. Use when working with Starburst data product YAML, lifecycle automation, or data product operations in this repo.
---

# Starburst data products

## When to use

- Authoring or validating `DataProduct` YAML for Starburst
- Running `starburst data-product` commands (init, lint, import, export)
- API workflows (create domain, publish, delete) where the CLI does not cover a step

## Prerequisites

- Repo `.env` (or `ENV_FILE`) with: `SERVER`, `ROLE`, `STARBURST_USER`, `STARBURST_PASSWORD`, `CLI_JAR`
- Tools: `java`, `curl`, `python3`, `bash`, `make` (optional)

## Layout

| Resource | Path |
|----------|------|
| Shared env paths | `scripts/lib/common.sh` |
| Step scripts | `scripts/*.sh` |
| Orchestration | `Makefile` |
| Extra notes | `reference.md` |

## Environment overrides

| Variable | Purpose |
|----------|---------|
| `DP_FILE` | Primary YAML path (default `data-products/demo_product.yaml`) |
| `DP_MODIFIED_FILE` | Alternate YAML for overwrite flows |
| `EXPORTED_FILE` | Export output path |
| `DOMAIN_NAME`, `CATALOG_NAME`, `PRODUCT_NAME` | Product and domain identifiers |
| `DOMAIN_DESCRIPTION` | JSON body for create-domain |

## Makefile (from repo root)

```bash
make -C .agents/skills/starburst-data-products help
make -C .agents/skills/starburst-data-products all
```

## Individual scripts

Run from repo root (examples):

```bash
bash .agents/skills/starburst-data-products/scripts/setup.sh
bash .agents/skills/starburst-data-products/scripts/create-domain.sh
bash .agents/skills/starburst-data-products/scripts/init.sh
bash .agents/skills/starburst-data-products/scripts/write-sample-yaml.sh
bash .agents/skills/starburst-data-products/scripts/lint.sh
bash .agents/skills/starburst-data-products/scripts/import.sh
bash .agents/skills/starburst-data-products/scripts/export.sh
bash .agents/skills/starburst-data-products/scripts/compare.sh
bash .agents/skills/starburst-data-products/scripts/write-modified-yaml.sh
bash .agents/skills/starburst-data-products/scripts/import-modified.sh
bash .agents/skills/starburst-data-products/scripts/import.sh --on-duplicate FAIL
bash .agents/skills/starburst-data-products/scripts/publish.sh '<product-id>'
bash .agents/skills/starburst-data-products/scripts/cleanup.sh '<product-id>' '<domain-id>'
```

`scripts/all.sh` runs the same sequence as `make all` (stops before publish/cleanup).

## Safety

- `cleanup.sh` / `make cleanup` uses `sysadmin` and deletes resources.
- `import` with `--on-duplicate FAIL` errors if the product already exists (expected).
- Keep secrets in `.env`, not in scripts.

## Troubleshooting

See `reference.md`.
