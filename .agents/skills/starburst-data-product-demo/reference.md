# Reference

## Common Failures

- `Missing env file`: set `ENV_FILE` or create repo `.env`.
- `Missing required env var`: provide all required values (`SERVER`, `ROLE`, `STARBURST_USER`, `STARBURST_PASSWORD`, `CLI_JAR`).
- Auth failures (`401`/`403`): validate credentials and `X-Trino-Role`.
- Duplicate import failures: expected when using `--on-duplicate FAIL`.
- Publish/cleanup failures: verify `product-id` and `domain-id`.

## Useful Commands

Check script usage:

```bash
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh
```

Run one step at a time:

```bash
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh setup
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh lint
```

Override defaults:

```bash
ENV_FILE=/path/to/.env \
DOMAIN_NAME="CLI Demo" \
PRODUCT_NAME=demo_product \
bash .agents/skills/starburst-data-product-demo/scripts/run-demo.sh all
```

## Expected Behavior Notes

- Exported YAML may differ from original YAML due to server-managed fields.
- `all` runs through overwrite re-import but does not publish or cleanup automatically.
- `publish` and `cleanup` are intentionally explicit to avoid accidental deletion.
