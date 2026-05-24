---
name: starburst-data-product
description: >-
  Use this skill whenever the user wants to create, edit, or publish a Starburst
  data product YAML — both Starburst Galaxy and SEP. It triggers on phrases like
  "create a data product", "build a DPaC", "fill out a data product yaml",
  "package this data as a product", or any reference to files under
  `data-products/`. Also trigger when the user only describes raw data they own
  ("we have iceberg sales tables we want to expose") — the skill interviews
  briefly, drafts the YAML, writes it to disk, and runs `starburst data-product
  lint` to confirm it validates before handing back.
---

# Starburst data product authoring

Produce a **valid, lint-clean** Starburst data product YAML and write it to
`data-products/<snake_case_name>.yaml` (or wherever the host repo keeps them).
The file should exist on disk by the end of your turn — the user shouldn't
have to copy YAML out of your reply.

## Workflow

1. **Gather context.** If the user already gave you tables, owners, domain, and
   a description, you have enough to start. If anything's vague or missing, run
   the [interview](#interview) below — in one message, not field-by-field.
2. **Pick a filename.** Snake-case the product name:
   `data-products/<snake_case_name>.yaml`. Don't ask the user to confirm the
   filename — just pick a sensible one. They can `git mv` it if they prefer
   something else.
3. **Write the YAML.** Use `references/template.yaml` as the skeleton.
   `references/example.yaml` is a fully-populated example showing realistic
   SQL, column docs, MV refresh patterns, and tag choices. For field semantics
   (catalog vs schema, DEFINER vs INVOKER, MV refresh patterns), consult
   `references/fields.md`.
4. **Lint it.**
   ```bash
   starburst data-product lint -f data-products/<name>.yaml
   ```
   Lint is offline — it doesn't talk to a server, just validates the YAML
   against the schema.
5. **Fix any errors and re-lint** until the command exits 0. See
   `references/lint-errors.md` for the common error patterns.
6. **Summarize your design decisions** in the reply: DEFINER vs INVOKER on
   each view, MV refresh pattern (incremental vs scheduled), which sample
   queries you wrote and why. Skip anything that was obvious from the user's
   ask — focus on the choices they couldn't have predicted.

**Do not ask "should I save this as a file?"** — always write the file. If the
user dislikes it they can `git restore` or `rm` it. Asking adds a turn and
breaks flow.

## Interview

When context is thin, ask all six in one conversational message. Partial
answers are usually enough — start drafting once you have answers to 3+.

1. **What does this data represent?** (e.g. "weekly sales by region",
   "counterparty positions across funds")
2. **Where does it live?** Catalog and schema (e.g. `hive.sales_q4`,
   `iceberg.analytics.events`).
3. **Who owns it?** Name + email for every owner. Multiple co-owners is
   common — list each person responsible for data quality or access.
4. **What are the main tables or views?** If unknown, describe the data
   shape (entity, grain, key columns).
5. **What questions should consumers answer with this product?** This
   directly drives the `sampleQueries` section, so the more concrete the
   better.
6. **Any context links or references?** Documentation pages, dashboards
   built on this data, runbooks, Confluence pages, architecture diagrams,
   upstream pipeline definitions. These become `relevantLinks` and are
   often the most valuable navigation aid for consumers.

## Lint feedback loop

Treat `starburst data-product lint` as ground truth. Run it after every
meaningful change to the YAML — not just at the end. The lint:

- Catches schema violations (missing required fields, invalid enum values
  like a bad `viewSecurityMode` or `status`).
- Catches malformed YAML (indentation, type coercion, duplicate keys).
- Does **not** execute the SQL — `definitionQuery` typos and bad column
  references only surface at `import` time.

When lint fails, read the message carefully, fix the file, re-lint. Don't
guess — the CLI's error messages reference exact YAML paths. If you're
stuck on an obscure error, check `references/lint-errors.md`.

If `starburst` isn't on PATH or the CLI can't find its jar, that's a host
setup problem — surface it to the user instead of plowing ahead with an
unvalidated YAML. The host repo may wrap the CLI (e.g. `./starburst`); use
whatever invocation the user's environment provides.

## Quality bar before declaring done

- File exists at `data-products/<name>.yaml`.
- `starburst data-product lint -f <path>` exits 0.
- At least one owner with a real email.
- At least 2 views with documented columns (no `SELECT *` in
  `definitionQuery`).
- At least 2 sample queries that hit the views or MVs defined in *this*
  product — not raw source tables. Sample queries are how new consumers
  learn the shape; if they bypass the product layer they're misleading.
- `summary` is one line, plain-English, no jargon.
- A consumer landing on this product cold can answer: *what is it, how do I
  use it, who do I contact?*

## References

| File | When to read |
|---|---|
| `references/template.yaml` | Always — copy as starting skeleton. |
| `references/example.yaml` | When you want to see what a populated product looks like (sample queries, column docs, MV patterns). |
| `references/fields.md` | When you're unsure what a field means or which enum value to pick. |
| `references/lint-errors.md` | When lint fails with a message you don't recognize. |
| `references/lifecycle.md` | When the user wants to import, publish, export, or delete a product — not just author YAML. |
