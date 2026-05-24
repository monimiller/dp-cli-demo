# Field-by-field reference

Read this when you're unsure what a field means or which enum value to pick.
For overall workflow see `../SKILL.md`. For lint error patterns see
`lint-errors.md`.

## `metadata`

| Field | What it means | Tips |
|---|---|---|
| `name` | Human-readable product name | Title case, descriptive — "Customer Lifetime Value" not "clv_v2" |
| `catalogName` | Starburst catalog holding the underlying data | snake_case; must already exist in the cluster |
| `schemaName` | Schema within that catalog | snake_case; typically created at import time if it doesn't exist |
| `dataDomainName` | Logical business domain | e.g. "Finance", "Supply Chain Integrity", "Product Analytics" — usually pre-defined by the data platform team |
| `summary` | One-liner shown in search results | Under 20 words, action-oriented. This is what consumers see first. |
| `description` | Markdown long-form description | Use headers and bullets. Cover: what it is, who it's for, what questions it answers, any caveats (freshness, coverage gaps). |

## `owners`

A list of `name` + `email` pairs. At least one owner required. Owners are
responsible for data quality and access requests. Multiple co-owners is
common and encouraged for shared products — list everyone who's actually
on the hook.

## `relevantLinks`

`label` + `url` pairs. High-value targets:

- Source system documentation (the platform producing the raw data)
- Architecture diagrams (LucidChart, drawio, Confluence)
- Data dictionaries
- Dashboards built on top of this product
- Runbooks for incidents or refresh failures
- Upstream pipeline definitions (Airflow DAGs, dbt models)

A great `relevantLinks` block can save a consumer hours.

## `tags`

Free-form string labels for discovery. Good tag categories:

- Domain — `finance`, `marketing`, `product`
- Freshness — `real-time`, `daily`, `weekly`, `historical`
- Audience — `executive`, `data-science`, `ops`
- Technology — `iceberg`, `delta`, `hive`
- Lifecycle — `beta`, `production`, `deprecated`

Aim for 3-7 tags. Don't duplicate `metadata` fields as tags
(no `domain: finance` if `dataDomainName: Finance` is already set).

## `sampleQueries`

The "show me how to use this" queries shown in the Galaxy/SEP UI. Good sample
queries:

- Answer a real business question ("daily active users last 30 days")
- Use views and MVs defined in *this* product — not raw source tables. If
  a sample query reaches around the product, it teaches consumers to do the
  same and the product layer loses value.
- Are self-contained — runnable with no edits.
- Include a `description` explaining what the query shows (optional but
  strongly recommended).

Write at least 2. Prefer queries that showcase the most valuable columns
and the most common access patterns.

## `views`

Each view is a named SQL `SELECT`. The view is the primary access surface
for consumers — most queries should go through views, not raw tables.

### `viewSecurityMode`

- **`DEFINER`** — view executes with the **owner's** permissions. Consumers
  see whatever the owner can see. Use this for curated views where the
  owner has already filtered down to safe data.
- **`INVOKER`** — view executes with the **caller's** permissions. Consumers
  only see rows they're independently authorized for. Use this when
  row-level security on the underlying tables matters (PII, multi-tenant
  data, regulated domains).

Default to `DEFINER` unless the data has cross-customer or regulated
content.

### `definitionQuery`

The SQL body of the view. Conventions:

- JOIN to dimension tables to enrich raw events/transactions.
- Apply sensible time filters (e.g. last 90 days) so consumers don't
  accidentally scan years of data.
- Rename cryptic source columns to human-readable ones.
- **Do not use `SELECT *`** — list columns explicitly so the contract is
  visible and `columns:` documentation stays in sync.

### `columns`

Document every column. Each column needs:

- `type` — standard SQL type (`varchar`, `bigint`, `date`,
  `timestamp(3) with time zone`, `decimal(18,2)`, `map(varchar, varchar)`,
  `array(varchar)`, etc.). Quote types that contain special characters.
- `description` — business meaning, not the data type. "ISO 3166-1 alpha-2
  country code" beats "country". For enum-like columns, list possible
  values: "Customer segment (premium, standard, trial)".

## `materializedViews`

Use MVs for pre-aggregated data that's expensive to compute on the fly —
dashboards, ML features, daily metrics. Two refresh patterns; pick one
per MV.

### Incremental (real-time) pattern

Use when there's a monotonically increasing column (event timestamp,
auto-incrementing id) that lets the MV catch new rows without rebuilding.

```yaml
definitionProperties:
  grace_period: 5m            # how stale is acceptable before re-checking
  incremental_column: event_date   # the column that monotonically grows
  refresh_interval: 1h        # how often to check for new data
  storage_schema: mv_storage  # where the materialized rows are stored
```

### Scheduled (batch) pattern

Use for periodic aggregates (weekly, monthly) where a full rebuild on a
cron schedule is fine.

```yaml
definitionProperties:
  refresh_schedule: "0 0 * * 0"   # cron: every Sunday at midnight
  storage_schema: analytics_warehouse
```

**Don't mix the two.** An MV either has `incremental_column` +
`refresh_interval`, or it has `refresh_schedule`. Setting both makes lint
fail and the behavior undefined.

## `exportMetadata`

Typically populated by the system at export/publish time. When **creating**
a new product, leave this section out — or, if you set anything, only set
`status`. Valid values:

- `DRAFT` — the product exists but isn't visible to consumers.
- `PUBLISHED` — visible in the catalog.

Don't fill in `exportedAt`, `createdAt`, `publishedAt` with fabricated
timestamps. Lint won't catch this but it'll confuse downstream tooling.
