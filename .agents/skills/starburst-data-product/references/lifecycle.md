# Data product lifecycle commands

Read this when you need to do more than author YAML — when the user wants to
import, re-import, publish, export, or delete a data product. For YAML
authoring, see `../SKILL.md`. For lint errors, see `lint-errors.md`.

All commands assume the repo root `./starburst` wrapper. It sources `.env`,
auto-injects `--server`, `--user`, and `--role` from env vars for the
SEP-talking subcommands (`import`, `export`, `publish`, `delete`), and routes
`publish` through `scripts/publish.sh` because the CLI's implementation is
still a stub.

## The lifecycle in one diagram

```
init    (scaffold a YAML)
  ↓
lint    (validate offline — no server needed)
  ↓
import  (create or overwrite the product on SEP, status=DRAFT)
  ↓
export  (round-trip: pull the canonical YAML back from SEP)
  ↓
publish (DRAFT → PUBLISHED — visible to consumers)
  ↓
delete  (tear down — async workflow)
```

`lint` runs anywhere, anytime — it's the cheapest feedback loop. The other
steps need a live SEP cluster.

## `init` — scaffold a YAML

```bash
./starburst data-product init \
  --name my_product \
  --domain "My Domain" \
  --catalog hive \
  -o data-products/my_product.yaml \
  --force
```

`--force` overwrites an existing file. Without it, init refuses to clobber.
You normally won't use this from the skill — you scaffold from
`references/template.yaml` instead, because that gives you the full schema
including MVs and sample queries which init omits.

## `lint` — validate offline

Already covered in `../SKILL.md`. Use after every meaningful edit.

```bash
./starburst data-product lint -f data-products/my_product.yaml
```

## `import` — push to SEP

Creates the product if new, or refuses/overwrites if it already exists.

```bash
./starburst data-product import -f data-products/my_product.yaml
```

The wrapper injects `--server`, `--user`, `--role` from `.env`. Pair with
`--password` (the CLI then reads `STARBURST_PASSWORD` from env) and
`--insecure` if your SEP cert isn't in the local trust store.

### `--on-duplicate` semantics

| Flag | What happens if a product with this name+domain already exists |
|---|---|
| (default) | CLI errors out — safer default for first imports |
| `--on-duplicate FAIL` | Same — explicitly fail. Use in CI when you want to catch accidental dup pushes. |
| `--on-duplicate OVERWRITE` | Replace the existing product with the YAML's contents. Use for legitimate edits. |

Import returns a product **ID** (UUID). Capture it if the user wants to
publish or delete next — both take `--id`.

## `export` — round-trip from SEP

Pulls the canonical YAML back. Useful for confirming what SEP actually
stored after an import (the server fills in `schemaName`,
`viewSecurityMode` defaults, and `exportMetadata`).

```bash
./starburst data-product export \
  --domain "My Domain" \
  --name my_product \
  -o /tmp/exported.yaml \
  --force
```

Diff against the source to see what SEP added:

```bash
diff data-products/my_product.yaml /tmp/exported.yaml
```

Expected differences: SEP adds `schemaName` (if you omitted it),
`viewSecurityMode: DEFINER` (if you omitted it), and a full
`exportMetadata` block. Anything else is worth investigating.

## `publish` — DRAFT → PUBLISHED

The CLI subcommand exists but its implementation is currently a stub
("ERROR: publish is not yet implemented"). The wrapper routes around this
by calling SEP's REST workflow endpoint directly via `scripts/publish.sh`.
You don't need to do anything special — just call the wrapper:

```bash
./starburst data-product publish --id <product-id>
# or
./starburst data-product publish --domain "My Domain" --name my_product
```

`scripts/publish.sh` POSTs to
`$SERVER/api/v1/dataProduct/products/<id>/workflows/publish`, then polls
the same URL until the workflow reaches `DONE` / `COMPLETED` /
`SUCCEEDED` / `PUBLISHED`, or fails. Exits 0 on success, non-zero on
failure with the SEP error body printed to stderr.

## `delete` — tear down

```bash
./starburst data-product delete --id <product-id>
```

Delete is an async workflow on SEP's side — the call returns immediately
but the actual teardown takes a few seconds. If you're chaining delete
into more work, `sleep 3` between the call and any follow-up. The
underlying Trino tables/views are dropped unless you pass `skipTrinoDelete`.

## Data domains

There's no `data-product domain` CLI subcommand yet — create domains via
REST when you need a new one:

```bash
curl -sk -X POST \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{$ROLE}" \
  -H "Content-Type: application/json" \
  -d '{"name":"My Domain","description":"...","schemaLocation":"my_schema"}' \
  "$SERVER/api/v1/dataProduct/domains"
```

Domains are usually pre-created by the data platform team — only do this
when you're bootstrapping a fresh demo cluster.
