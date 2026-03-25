# DP CLI Demo

Starburst data product CLI examples plus an Agent Skill for data-products-as-code workflows.

## Agent skill

- Skill: [`.agents/skills/starburst-data-products/SKILL.md`](.agents/skills/starburst-data-products/SKILL.md)
- Step scripts: [`.agents/skills/starburst-data-products/scripts/`](.agents/skills/starburst-data-products/scripts/)
- Makefile: [`.agents/skills/starburst-data-products/Makefile`](.agents/skills/starburst-data-products/Makefile)
- Notes: [`.agents/skills/starburst-data-products/reference.md`](.agents/skills/starburst-data-products/reference.md)

## Prerequisites

Create a `.env` in the repo root with:

- `SERVER`
- `ROLE`
- `STARBURST_USER`
- `STARBURST_PASSWORD`
- `CLI_JAR`

Tools: `java`, `curl`, `python3`, `bash`, `make` (optional).

## Quick start

```bash
make -C .agents/skills/starburst-data-products help
make -C .agents/skills/starburst-data-products all
```

Publish (after you have a product id):

```bash
make -C .agents/skills/starburst-data-products publish PRODUCT_ID='<product-id>'
```

Cleanup:

```bash
make -C .agents/skills/starburst-data-products cleanup PRODUCT_ID='<product-id>' DOMAIN_ID='<domain-id>'
```

## Run one step

```bash
bash .agents/skills/starburst-data-products/scripts/setup.sh
bash .agents/skills/starburst-data-products/scripts/lint.sh
```

Or use Makefile targets: `setup`, `create-domain`, `init`, `write-sample`, `lint`, `import`, `export`, `compare`, `write-modified`, `import-modified`, `import-fail`.

## Notes

- `import-fail` / `import.sh --on-duplicate FAIL` fails if the product already exists (expected).
- Cleanup requires `sysadmin` on the server and deletes resources.
