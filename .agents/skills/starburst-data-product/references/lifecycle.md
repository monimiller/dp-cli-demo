# Data product lifecycle commands

Read this when you need to do more than author YAML — when the user wants
to import, re-import, publish, export, or delete a data product. For YAML
authoring, see `../SKILL.md`. For lint errors, see `lint-errors.md`.

This file covers the canonical Starburst CLI commands. The host repo may
wrap them (e.g. a `./starburst` script that injects connection flags from a
`.env`) — use whatever invocation the user's environment provides. Drop the
wrapper prefix from these examples if you're using the CLI directly.

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
steps need a live SEP cluster, so they take `--server`, `--user`, and
`--role` flags (plus `--password` to read `STARBURST_PASSWORD` from env,
and `--insecure` if the cluster's cert isn't trusted locally).

## `init` — scaffold a YAML

```bash
starburst data-product init \
  --name my_product \
  --domain "My Domain" \
  --catalog hive \
  -o data-products/my_product.yaml \
  --force
```

`--force` overwrites an existing file. You normally won't use `init` from
this skill — `references/template.yaml` is a richer starting point because
it includes MVs and sample-query placeholders that `init` omits.

## `lint` — validate offline

Covered in `../SKILL.md`. Run after every meaningful edit.

```bash
starburst data-product lint -f data-products/my_product.yaml
```

## `import` — push to SEP

Creates the product if new, errors out if it already exists.

```bash
starburst data-product import \
  -f data-products/my_product.yaml \
  --server $SERVER --user $USER --role $ROLE --password --insecure
```

Import prints the new product's UUID. Capture it if the user wants to
publish or delete next — both can take `--id`.

### `--on-duplicate` semantics

| Flag | What happens if a product with this name+domain already exists |
|---|---|
| (default) | CLI errors out — safer default for first imports |
| `--on-duplicate FAIL` | Explicit fail. Use in CI to catch accidental dup pushes. |
| `--on-duplicate OVERWRITE` | Replace the existing product with the YAML's contents. Use for legitimate edits. |

## `export` — round-trip from SEP

Pulls the canonical YAML back. Useful for confirming what SEP actually
stored after an import — the server fills in `schemaName`,
`viewSecurityMode` defaults, and the `exportMetadata` block.

```bash
starburst data-product export \
  --domain "My Domain" --name my_product \
  --server $SERVER --user $USER --role $ROLE --password --insecure \
  -o /tmp/exported.yaml --force
```

Diff against the source to see what SEP added:

```bash
diff data-products/my_product.yaml /tmp/exported.yaml
```

Expected differences: SEP adds `schemaName` (if you omitted it),
`viewSecurityMode: DEFINER` (if you omitted it), and a full
`exportMetadata` block. Anything else is worth investigating.

## `publish` — DRAFT → PUBLISHED

```bash
starburst data-product publish --id <product-id>
# or
starburst data-product publish --domain "My Domain" --name my_product
```

**Heads-up:** depending on your CLI version, `publish` may not be fully
implemented — some builds print `ERROR: publish is not yet implemented`
and exit 1 regardless of flags. If you hit that, the host repo may
provide a wrapper that routes around it (typically by POSTing to
`/api/v1/dataProduct/products/<id>/workflows/publish` directly). Surface
the issue to the user rather than calling the workflow endpoint yourself
from the skill.

## `delete` — tear down

```bash
starburst data-product delete --id <product-id>
```

Delete is an async workflow on SEP's side — the call returns immediately
but the actual teardown takes a few seconds. If you're chaining delete
into more work, `sleep 3` between the call and any follow-up.

## Data domains

There's no `data-product domain` CLI subcommand yet — create domains via
REST when you need a new one:

```bash
curl -sk -X POST \
  -u "$USER:$PASSWORD" \
  -H "X-Trino-Role: system=ROLE{$ROLE}" \
  -H "Content-Type: application/json" \
  -d '{"name":"My Domain","description":"...","schemaLocation":"my_schema"}' \
  "$SERVER/api/v1/dataProduct/domains"
```

Domains are usually pre-created by the data platform team — only do this
when you're bootstrapping a fresh cluster.
