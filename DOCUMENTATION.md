# Starburst Data Products as Code — Documentation

This repo provides a full lifecycle toolkit for managing Starburst data products as code: author YAML definitions, validate them, push them to a Starburst server, and publish them — all from a terminal, an AI agent, or a GitHub Actions workflow.

---

## What's in this repo

```
dp-cli-demo/
├── .env                              # Secrets (gitignored)
├── data-products/
│   └── demo_product.yaml             # Your data product definitions live here
├── demo-dp-cli.sh                    # Step-by-step interactive demo script
└── .agents/
    └── skills/
        └── starburst-data-products/
            ├── SKILL.md              # Agent skill definition
            ├── Makefile              # Orchestration shortcuts
            ├── reference.md         # Troubleshooting notes
            └── scripts/
                ├── lib/common.sh     # Shared env loading + CLI wrapper
                ├── setup.sh          # Validate environment
                ├── create-domain.sh  # Create a data domain via REST API
                ├── init.sh           # Generate a blank YAML template
                ├── write-sample-yaml.sh     # Write sample YAML to DP_FILE
                ├── write-modified-yaml.sh   # Write a modified version (extra column)
                ├── lint.sh           # Validate YAML offline
                ├── import.sh         # Import YAML to server
                ├── import-modified.sh       # Re-import modified YAML (OVERWRITE)
                ├── export.sh         # Export YAML from server
                ├── compare.sh        # Diff local vs exported
                ├── publish.sh        # Publish via REST API
                ├── cleanup.sh        # Delete product + domain (sysadmin only)
                └── all.sh            # Run full flow (setup → import-modified)
```

---

## Prerequisites

Create a `.env` file in the repo root (it is gitignored):

```bash
SERVER=https://your-starburst-host
ROLE=accountadmin
STARBURST_USER=your_username
STARBURST_PASSWORD=your_password
CLI_JAR=/path/to/starburst-cli.jar
```

Required tools: `java`, `curl`, `python3`, `bash`. `make` is optional.

---

## The data product YAML format

Data products are defined as YAML files with the following structure:

```yaml
apiVersion: v1
kind: DataProduct
metadata:
  name: demo_product
  catalogName: iceberg_demo
  dataDomainName: CLI Demo
  summary: A short description shown in the catalog
  description: |
    A longer description of this data product's purpose and lineage.
owners:
  - name: Alice
    email: alice@example.com
views:
  - name: sample_orders
    description: A sample orders view
    definitionQuery: |
      SELECT orderkey, custkey, orderstatus, totalprice, orderdate
      FROM tpch.tiny.orders
    columns:
      - name: orderkey
        type: bigint
        description: Order identifier
      - name: totalprice
        type: double
        description: Total price of the order
```

Key fields:
- `metadata.name` — identifier used by the CLI for export and comparison
- `metadata.catalogName` — the Iceberg (or other) catalog this product lives in
- `metadata.dataDomainName` — must match a domain that already exists on the server
- `views` — one or more SQL views that make up the product's public interface

After an import, the server will add `schemaName`, `viewSecurityMode`, and `exportMetadata` fields. These show up when you run `export` and `compare`. This is expected behavior.

---

## The full data product lifecycle

```
create-domain → init → (edit YAML) → lint → import → export → compare
                                                                    ↓
                                                              write-modified
                                                                    ↓
                                                            import-modified (OVERWRITE)
                                                                    ↓
                                                                publish
                                                                    ↓
                                                               cleanup
```

Each step maps to a script and a Makefile target (described below).

---

## For humans: running the demo interactively

The `demo-dp-cli.sh` script is designed for a live walkthrough. Copy-paste each block one at a time and read the output before moving on.

```bash
# Load environment and set aliases
source demo-dp-cli.sh
```

After setup, work through the steps:

**Step 0 — Create a data domain** (once per environment):

```bash
curl -sk -X POST \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{$ROLE}" \
  -H "Content-Type: application/json" \
  -d '{"name":"CLI Demo","description":"Domain for CLI demo","schemaLocation":"iceberg_demo"}' \
  "$SERVER/api/v1/dataProduct/domains" | python3 -m json.tool
```

Save the `id` from the response — you'll need it for cleanup.

**Step 1 — Generate a YAML template:**

```bash
starburst data-product init \
  --name demo_product --domain "CLI Demo" --catalog iceberg_demo \
  -o data-products/demo_product.yaml --force
```

**Step 2 — Edit the YAML** with real queries and column definitions (see format above).

**Step 3 — Lint (no server required):**

```bash
starburst data-product lint -f data-products/demo_product.yaml
```

**Step 4 — Import to the server:**

```bash
starburst data-product import \
  -f data-products/demo_product.yaml \
  --server $SERVER --user $STARBURST_USER --password --insecure --role $ROLE
```

Save the `product-id` from the output.

**Steps 5–6 — Export and compare:**

```bash
starburst data-product export \
  --domain "CLI Demo" --name demo_product \
  --server $SERVER --user $STARBURST_USER --password --insecure --role $ROLE \
  -o /tmp/demo-dp-exported.yaml --force

diff data-products/demo_product.yaml /tmp/demo-dp-exported.yaml || true
```

**Steps 7–8 — Modify and re-import with OVERWRITE:**

Edit your YAML (add a column, update the summary, etc.), then:

```bash
starburst data-product import \
  -f data-products/demo_product.modified.yaml \
  --server $SERVER --user $STARBURST_USER --password --insecure --role $ROLE \
  --on-duplicate OVERWRITE
```

**Step 9 — Verify duplicate protection (FAIL mode):**

```bash
starburst data-product import \
  -f data-products/demo_product.yaml \
  --server $SERVER --user $STARBURST_USER --password --insecure --role $ROLE \
  --on-duplicate FAIL
# Expected: ERROR — product already exists
```

**Step 10 — Publish:**

```bash
PRODUCT_ID=<paste-from-step-4>

curl -sk -X POST \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{$ROLE}" \
  "$SERVER/api/v1/dataProduct/products/$PRODUCT_ID/workflows/publish"

# Check publish status:
sleep 3
curl -sk -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{$ROLE}" \
  "$SERVER/api/v1/dataProduct/products/$PRODUCT_ID/workflows/publish" | python3 -m json.tool
```

**Cleanup** (requires `sysadmin`):

```bash
DOMAIN_ID=<paste-from-step-0>

curl -sk -X POST \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{sysadmin}" \
  "$SERVER/api/v1/dataProduct/products/$PRODUCT_ID/workflows/delete?skipTrinoDelete=true"

sleep 3
curl -sk -X DELETE \
  -u "$STARBURST_USER:$STARBURST_PASSWORD" \
  -H "X-Trino-Role: system=ROLE{sysadmin}" \
  "$SERVER/api/v1/dataProduct/domains/$DOMAIN_ID"
```

---

## For humans: using the Makefile

The Makefile wraps every script as a named target. Run from the repo root:

```bash
# See all targets
make -C .agents/skills/starburst-data-products help

# Run the full sample flow (setup → import-modified)
make -C .agents/skills/starburst-data-products all

# Run individual steps
make -C .agents/skills/starburst-data-products setup
make -C .agents/skills/starburst-data-products create-domain
make -C .agents/skills/starburst-data-products init
make -C .agents/skills/starburst-data-products write-sample
make -C .agents/skills/starburst-data-products lint
make -C .agents/skills/starburst-data-products import
make -C .agents/skills/starburst-data-products export
make -C .agents/skills/starburst-data-products compare
make -C .agents/skills/starburst-data-products write-modified
make -C .agents/skills/starburst-data-products import-modified

# Try to import a product that already exists — expected to fail
make -C .agents/skills/starburst-data-products import-fail

# Publish and cleanup require IDs from earlier steps
make -C .agents/skills/starburst-data-products publish PRODUCT_ID='<uuid>'
make -C .agents/skills/starburst-data-products cleanup PRODUCT_ID='<uuid>' DOMAIN_ID='<uuid>'
```

`make all` stops before publish and cleanup intentionally — those are destructive or manual steps.

### Environment variable overrides

Every default path and name is overridable:

| Variable | Default | Purpose |
|---|---|---|
| `ENV_FILE` | `<repo-root>/.env` | Path to credentials file |
| `DP_FILE` | `data-products/demo_product.yaml` | Primary YAML to lint/import |
| `DP_MODIFIED_FILE` | `data-products/demo_product.modified.yaml` | Modified YAML for overwrite flow |
| `EXPORTED_FILE` | `/tmp/starburst-dp-exported.yaml` | Where export writes its output |
| `DOMAIN_NAME` | `CLI Demo` | Data domain name |
| `CATALOG_NAME` | `iceberg_demo` | Catalog for domain creation |
| `PRODUCT_NAME` | `demo_product` | Product name for init/export |
| `DOMAIN_DESCRIPTION` | `Data product domain` | Description for domain creation |

Example — run against a different YAML file:

```bash
DP_FILE=data-products/my_other_product.yaml \
  make -C .agents/skills/starburst-data-products lint
```

---

## For AI agents: the agent skill

The `.agents/skills/starburst-data-products/` folder is an **agent skill** following the [agentskills.io](https://agentskills.io/home) layout. AI agents (such as those built on Claude Code or the Anthropic Agent SDK) can load this skill to gain guided, context-aware access to all data product lifecycle operations.

### How it works

The skill's `SKILL.md` defines:
- When the skill should activate (authoring YAML, running CLI commands, API workflows)
- What the agent needs (environment variables, tools)
- How the repo is laid out
- Which scripts map to which operations
- Safety notes (cleanup is destructive; import with `FAIL` errors by design)

When an agent loads this skill, it can translate natural language requests like _"lint the current data product YAML"_ or _"import the product and overwrite if it already exists"_ directly into the correct script invocation or CLI command — without needing to rediscover the project structure each time.

### What an agent can do with this skill

| User asks | Agent runs |
|---|---|
| "Check that the YAML is valid" | `bash .agents/skills/starburst-data-products/scripts/lint.sh` |
| "Import the data product" | `bash .agents/skills/starburst-data-products/scripts/import.sh` |
| "Import and overwrite if it exists" | `bash .agents/skills/starburst-data-products/scripts/import.sh --on-duplicate OVERWRITE` |
| "Export the product from the server" | `bash .agents/skills/starburst-data-products/scripts/export.sh` |
| "Show me what changed after export" | `bash .agents/skills/starburst-data-products/scripts/compare.sh` |
| "Publish the product" | `bash .agents/skills/starburst-data-products/scripts/publish.sh <product-id>` |
| "Clean up the demo environment" | `bash .agents/skills/starburst-data-products/scripts/cleanup.sh <product-id> <domain-id>` |
| "Run the whole flow" | `make -C .agents/skills/starburst-data-products all` |

### Agent safety notes

- The agent should load `.env` (or ask the user to confirm it exists) before running any networked script.
- `cleanup.sh` deletes resources permanently. The agent should confirm intent before running it.
- `import.sh --on-duplicate FAIL` failing is expected behavior, not an error to retry.
- Credentials live in `.env` and are never passed as command-line arguments — the scripts handle this securely.

---

## For GitHub Actions: automated deployment

The `github-actions` branch adds two reusable pieces: a composite action and a workflow that calls it.

### The composite action: `.github/actions/data-product-update`

This action encapsulates lint + import as a single reusable step. It can be called from any workflow in the repo.

**Inputs:**

| Input | Required | Default | Description |
|---|---|---|---|
| `yaml_path` | yes | — | Path to the data product YAML file |
| `duplicate_mode` | yes | — | `OVERWRITE` or `FAIL` |
| `server` | yes | — | Starburst server URL |
| `role` | yes | — | Starburst role for import |
| `starburst_user` | yes | — | Starburst username |
| `starburst_password` | yes | — | Starburst password |
| `cli_jar` | yes | — | HTTP(S) URL **or** runner-local path to the CLI jar |
| `insecure` | no | `true` | Pass `--insecure` to the CLI |
| `run_lint` | no | `true` | Lint before import |
| `write_summary` | no | `true` | Write result to the GitHub Actions job summary |

**Outputs:**

| Output | Description |
|---|---|
| `status` | `success` or `failure` |
| `deployed_yaml` | The YAML path that was deployed |
| `duplicate_mode_used` | The duplicate mode passed to import |

**How the action resolves the CLI jar:**
The `cli_jar` input accepts either a download URL or a path already present on the runner. If a URL is provided, the action downloads the jar with `curl` before using it. This lets you host the jar in a private location (e.g., an S3 bucket or internal artifact store) without committing it to the repo.

### The workflow: `.github/workflows/deploy-data-product.yml`

This is a manually triggered (`workflow_dispatch`) workflow with three inputs:

| Input | Default | Description |
|---|---|---|
| `yaml_path` | `data-products/demo_product.yaml` | Which YAML to deploy |
| `duplicate_mode` | `OVERWRITE` | How to handle an existing product |
| `create_demo_pr` | `true` | Whether to open a demo PR after a successful deploy |

**Required repository secrets:**

| Secret | Description |
|---|---|
| `SERVER` | Starburst server URL |
| `ROLE` | Starburst role |
| `STARBURST_USER` | Username |
| `STARBURST_PASSWORD` | Password |
| `CLI_JAR` | URL or path to the CLI jar |

**What the workflow does:**

1. **`deploy` job** — checks out the repo, sets up Java 17, then calls the composite action to lint and import the specified YAML. The job summary shows the deployed file, duplicate mode, and result.

2. **`demo_pr` job** — runs only if `deploy` succeeded and `create_demo_pr` is `true`. It writes a small version marker file (`data-products/.demo-pr-version`) and opens (or updates) a pull request on the `demo/pr-bump` branch using `peter-evans/create-pull-request`. This gives you a visible, linkable record in GitHub of every successful deploy.

**Running the workflow:**

Go to **Actions → Deploy Data Product → Run workflow** in the GitHub UI, fill in the inputs, and click Run. The job summary will show lint and import results. If the demo PR option is enabled, a link to the PR appears in the summary as well.

**Using the action in your own workflow:**

```yaml
- name: Deploy my data product
  uses: ./.github/actions/data-product-update
  with:
    yaml_path: data-products/my_product.yaml
    duplicate_mode: OVERWRITE
    server: ${{ secrets.SERVER }}
    role: ${{ secrets.ROLE }}
    starburst_user: ${{ secrets.STARBURST_USER }}
    starburst_password: ${{ secrets.STARBURST_PASSWORD }}
    cli_jar: ${{ secrets.CLI_JAR }}
```

---

## Troubleshooting

| Problem | Likely cause | Fix |
|---|---|---|
| `Missing env file` | `.env` not found at repo root | Create `.env` with the five required variables |
| `Missing required env var` | A variable is blank in `.env` | Fill in `SERVER`, `ROLE`, `STARBURST_USER`, `STARBURST_PASSWORD`, `CLI_JAR` |
| HTTP `401` / `403` | Bad credentials or wrong role | Check username, password, and `ROLE` value |
| Import error: duplicate product | Product already exists on server | Use `--on-duplicate OVERWRITE` to update, or `FAIL` to reject intentionally |
| Export diff shows extra fields | Server adds `schemaName`, `viewSecurityMode`, etc. | Expected — these are server-managed; `compare.sh` uses `|| true` so it won't fail |
| `publish.sh` / `cleanup.sh` fail | Wrong `product-id` or `domain-id` | Copy IDs exactly from the import output or the API response |
| Cleanup fails with permissions error | Your role isn't `sysadmin` | Cleanup requires `sysadmin` on the Starburst server |
| GitHub Actions `401` on import | Secrets not set or wrong | Set `SERVER`, `ROLE`, `STARBURST_USER`, `STARBURST_PASSWORD`, `CLI_JAR` in repo secrets |
| CLI jar not found in Actions | `CLI_JAR` secret is a bad URL or path | Provide a valid HTTPS URL the runner can `curl`, or a path that exists on the runner |
