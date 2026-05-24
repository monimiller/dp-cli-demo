# Lint error patterns

Read this when `starburst data-product lint` fails with a message you don't
recognize. For overall workflow see `../SKILL.md`. For field semantics see
`fields.md`.

Lint error messages reference exact YAML paths (e.g.
`views[1].columns[3].type`). Read the path before reading the error text —
the path usually points at the fix.

## Setup errors (lint itself can't run)

### `Unable to access jarfile`

```
Error: Unable to access jarfile /Users/.../starburst (3)
```

The repo `.env` has `CLI_JAR` pointing at a path that doesn't exist on this
machine. **Don't try to fix it yourself** — surface the actual `.env` value
and the missing path to the user. They need to either:
- Download the Starburst CLI jar to that path, or
- Update `CLI_JAR` in `.env` to point at where the jar actually lives.

Until this is fixed, you cannot validate YAML. Tell the user and stop —
producing an unvalidated YAML is worse than no YAML.

### `Missing $REPO_ROOT/.env`

The `./starburst` wrapper couldn't find `.env`. Either you're not running
from the repo root, or `.env` was deleted. Run lint from the repo root or
restore `.env`.

## Schema errors

### `unknown field` or `field not allowed`

You used a key that isn't in the schema. Common causes:
- Typo (`viewSecuirtyMode` instead of `viewSecurityMode`).
- Old field name from a previous schema version.
- Putting a field at the wrong nesting level (e.g. `tags` under `metadata`
  instead of at the top level).

Cross-check against `template.yaml` — it lists every supported field at
the correct nesting.

### `required field missing`

The schema demands a field you didn't set. The error path tells you
exactly which one. Required fields per section:

- `metadata`: `name`, `catalogName`, `schemaName`, `dataDomainName`,
  `summary`
- `owners[]`: `name`, `email`
- `views[]`: `name`, `definitionQuery`, `viewSecurityMode`, `columns`
- `views[].columns[]`: `name`, `type`
- `materializedViews[]`: `name`, `definitionQuery`, `definitionProperties`,
  `columns`

### `invalid enum value`

Some fields only accept specific values:

- `viewSecurityMode`: `DEFINER` or `INVOKER` (uppercase, exact).
- `exportMetadata.status`: `DRAFT` or `PUBLISHED`.

Case matters. `Definer` will fail.

## YAML syntax errors

### `mapping values are not allowed in this context`

Usually an unquoted string containing a colon. Wrap the value in quotes:

```yaml
# Wrong
description: Type of event (click, view, purchase, etc.)
# Right
description: "Type of event (click, view, purchase, etc.)"
```

### `expected <block end>` or `found character that cannot start any token`

Indentation issue. YAML is whitespace-sensitive — 2 spaces per level, no
tabs. The error line number points at where parsing broke, but the actual
cause is often a few lines earlier.

### `found duplicate key`

You repeated a key under the same parent. Often happens with `description:`
appearing twice in a view block — once at the view level, once inside a
column. Check indentation; one of them is at the wrong level.

## SQL-related warnings

Lint does **not** execute SQL. It will not catch:

- Tables that don't exist in the catalog
- Columns referenced in `definitionQuery` that don't exist in the source
- Syntax errors that the Trino parser would reject

These only show up at `import` time. If you want to catch them earlier,
run a quick `SELECT 1 FROM <table> WHERE FALSE` against the cluster
before relying on the view.

## When in doubt

If the error is genuinely confusing and not covered here, paste the full
lint output to the user and ask before guessing. A wrong fix can mask the
real error and waste another round-trip.
