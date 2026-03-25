# DP CLI Demo

This repository contains a Starburst data product lifecycle demo and a reusable Agent Skill version of that workflow.

## Agent Skill

The skill is located at:

- `.agents/skills/starburst-data-product-demo/SKILL.md`

Runner script:

- `.agents/skills/starburst-data-product-demo/scripts/run-demo.sh`

Reference notes:

- `.agents/skills/starburst-data-product-demo/reference.md`

## Prerequisites

Create a `.env` file in the repo root with:

- `SERVER`
- `ROLE`
- `STARBURST_USER`
- `STARBURST_PASSWORD`
- `CLI_JAR`

Required tools: `java`, `curl`, `python3`, `bash`.

## Quick Start

Run the full demo up to overwrite re-import:

```bash
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh all
```

Run publish:

```bash
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh publish --product-id <product-id>
```

Run cleanup:

```bash
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh cleanup --product-id <product-id> --domain-id <domain-id>
```

## Individual Steps

Use these commands as needed:

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

## Notes

- `import --on-duplicate FAIL` is expected to fail when the product already exists.
- `cleanup` uses `sysadmin` role and deletes demo resources.
