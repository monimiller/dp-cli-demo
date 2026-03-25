# Reference

## Common failures

- Missing `.env` or `ENV_FILE`: create repo `.env` with required variables.
- Missing `SERVER`, `ROLE`, `STARBURST_USER`, `STARBURST_PASSWORD`, or `CLI_JAR`.
- HTTP `401`/`403`: check credentials and `X-Trino-Role`.
- Import duplicate: use `--on-duplicate OVERWRITE` or expect failure with `FAIL`.
- Publish/cleanup: confirm `product-id` and `domain-id` from API or CLI output.

## Makefile

```bash
make -C .agents/skills/starburst-data-products all
make -C .agents/skills/starburst-data-products publish PRODUCT_ID='<uuid>'
```

## Behavior notes

- Exported YAML may add server-managed fields vs. your local file; `compare.sh` may show a diff.
- `write-sample-yaml.sh` / `write-modified-yaml.sh` do not require server credentials (paths only).
- `all` / `make all` does not publish or cleanup automatically.

## Format

This skill follows the Agent Skills layout (folder with `SKILL.md` plus optional scripts). See [agentskills.io](https://agentskills.io/home).
