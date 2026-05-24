---
name: dpac
description: >
  Data Products as Code (DPaC) skill — use this whenever a user wants to create,
  fill out, or generate a Data Product YAML file. Triggers include: "create a data
  product", "fill out the DPaC template", "build a data product YAML", "help me
  define a data product", "write a DPaC for X", or any mention of data products
  in YAML/code form. Also use when the user describes data they own (tables, views,
  domains) and wants to package them as a product for others to consume. Even if the
  user only has a rough idea ("I have some sales data I want to share"), invoke this
  skill — it guides them through the full process.
---

# Data Products as Code (DPaC) Skill

This skill helps you (and the users you're helping) create well-formed Data Product
YAML files for Starburst Galaxy/SEP. The output is a complete, copy-paste-ready
`.yaml` file following the `apiVersion: v1 / kind: DataProduct` schema.

## Reference files

- `references/template.yaml` — the blank template (start here for structure)
- `references/example.yaml` — a fully-populated example to use as a style guide

Read these if you need to verify exact field names or see realistic SQL patterns.

---

## Your job when this skill triggers

Your goal is to produce a **complete, valid Data Product YAML** that the user can
drop straight into their Starburst environment. The output should require zero
guesswork on their part.

There are two modes:

**A. User gives you rich context (tables, domains, queries, column names)**
→ Go ahead and generate the full YAML, filling every section from what they shared.
  Ask only for genuinely missing pieces that you cannot infer.

**B. User gives you a vague or minimal description ("I have sales data I want to share")**
→ Ask a few focused questions (see Interview section below), then generate.

Either way, avoid asking more than 3-4 questions before attempting a draft — it's
always better to generate something concrete and let the user react to it.

---

## Interview: what to ask

When context is thin, ask about these in a single conversational message:

1. **What does this data represent?** (e.g., "weekly sales by region", "user clickstream events")
2. **What catalog/schema does it live in?** (e.g., `analytics_catalog.sales_schema`)
3. **Who owns it?** (name + email; can be themselves)
4. **What are the main tables or views?** List them if known; if not, describe the data shape.
5. **What questions should someone be able to answer with this product?** This drives sample queries.

You don't need all of these to start — partial answers are enough for a solid draft.

---

## Field-by-field guide

### `metadata`

| Field | What it means | Tips |
|---|---|---|
| `name` | Human-readable product name | Title case, descriptive — e.g. "Customer Lifetime Value" |
| `catalogName` | Starburst catalog that holds the underlying data | snake_case |
| `schemaName` | Schema within that catalog | snake_case |
| `dataDomainName` | Logical business domain | e.g. "Enterprise Analytics Domain", "Finance", "Product" |
| `summary` | One-liner description (shown in search results) | Keep it under 20 words, action-oriented |
| `description` | Markdown long-form description | Use headers, bullet lists; explain what the product does, who it's for, what questions it answers |

### `owners`

A list of `name` + `email` pairs. At least one owner is required. The owner is the
person responsible for data quality and access. If the user doesn't know additional
owners, just list themselves.

### `relevantLinks`

Optional but valuable. Include links to:
- Source system documentation
- Architecture diagrams
- Data dictionaries
- Dashboards built on top of this product
- Runbooks

### `tags`

Free-form string labels used for discovery. Good tags describe:
- Domain (e.g. `finance`, `marketing`, `product`)
- Freshness / update cadence (e.g. `real-time`, `daily`, `historical`)
- Audience (e.g. `executive`, `data-science`, `ops`)
- Technology (e.g. `iceberg`, `delta`, `hive`)

Aim for 3-7 tags. Don't repeat metadata fields as tags.

### `sampleQueries`

These are the "show me how to use this" queries — they appear in Galaxy's UI to help
consumers get started. Good sample queries:
- Answer a real business question ("how many daily active users last 30 days?")
- Use the views/materialized views defined in this product, not raw source tables
- Are self-contained and runnable without modification
- Include a `description` explaining what the query shows (optional but recommended)

Write at least 2 sample queries per product. Prefer queries that showcase the most
valuable columns.

### `views`

Views are the primary data access layer. Each view is a named SQL SELECT statement.

**`viewSecurityMode`**:
- `DEFINER` — the view executes with the *owner's* permissions (consumers see all data the owner can see). Use for curated, pre-filtered views.
- `INVOKER` — the view executes with the *caller's* permissions (consumers only see what they're allowed to see). Use when row-level security matters.

**`definitionQuery`**: The SQL body of the view. Should:
- JOIN to dimension tables to enrich raw events/transactions
- Apply sensible time filters (e.g. last 90 days) to keep queries fast
- Rename cryptic column names to human-readable ones
- Not contain `SELECT *` — be explicit about columns

**`columns`**: Document every column. Good column documentation includes:
- A `type` using standard SQL types (varchar, bigint, date, timestamp(3) with time zone, decimal(18,2), etc.)
- A `description` that explains business meaning, not just the data type. E.g. "ISO 3166-1 alpha-2 country code" not just "country"

### `materializedViews`

Use materialized views for pre-aggregated data that's expensive to compute on the fly
(dashboards, ML features, daily metrics). Two refresh patterns:

**Incremental (real-time) pattern** — use when there's a monotonically increasing column:
```yaml
definitionProperties:
  grace_period: 5m          # how stale is OK before re-checking
  incremental_column: event_date   # the column that grows over time
  refresh_interval: 1h      # how often to check for new data
  storage_schema: mv_storage # where to store the materialized data
```

**Scheduled (batch) pattern** — use for weekly/monthly aggregates:
```yaml
definitionProperties:
  refresh_schedule: "0 0 * * 0"   # cron: every Sunday at midnight
  storage_schema: analytics_warehouse
```

### `exportMetadata`

This section is typically populated by the system when a product is exported/published.
When generating a new product, leave it as a template or omit it unless the user
asks to set specific values. If setting `status`, valid values are `PUBLISHED` and `DRAFT`.

---

## Output format

Always output the complete YAML in a fenced code block:

```yaml
apiVersion: v1
kind: DataProduct
# ... full content
```

After the code block, add a brief prose explanation of key design decisions
(e.g., why you chose DEFINER vs INVOKER, what the sample queries demonstrate,
any fields you left blank and why).

If the YAML is long, you can split the explanation into a short bullet list —
but the YAML itself should always be complete and untruncated.

Also offer to save the YAML as a file the user can download.

---

## Common pitfalls to avoid

- **Don't use `SELECT *` in views** — always list columns explicitly and document them
- **Don't leave `description` fields blank** — even a one-sentence description is far better than nothing for discoverability
- **Don't mix incremental and scheduled properties** in the same materializedView — pick one pattern
- **Don't reference source tables directly in sample queries** — sample queries should use the views/materializedViews defined in this product
- **Don't leave `exportMetadata` dates in the future** — if populating, use realistic timestamps

---

## Quality bar

A high-quality Data Product YAML:
1. Has a clear, jargon-free summary and description
2. Has at least 2 views with fully documented columns
3. Has 2+ sample queries that answer real business questions using those views
4. Has relevant tags that aid discovery
5. Has at least one owner with a real email
6. Is syntactically valid YAML (check indentation carefully)

Before finalizing, mentally walk through: "If I were a data consumer finding this
product for the first time, would I know what it does, how to use it, and who to
contact?" If yes, you're done.
