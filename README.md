# DP CLI Demo

Starburst data product CLI examples and an Agent Skill for
data-products-as-code workflows.

## Agent skill

- Skill: [`.agents/skills/starburst-data-product/SKILL.md`](.agents/skills/starburst-data-product/SKILL.md)
- References: template, fully-populated example, field reference, lint error
  triage, and full lifecycle commands (init/lint/import/export/publish/delete)
  live under [`.agents/skills/starburst-data-product/references/`](.agents/skills/starburst-data-product/references/).

The skill triggers whenever you ask Claude to create, edit, or publish a
Starburst data product YAML. It interviews briefly when context is thin,
writes the YAML to `data-products/`, and runs `starburst data-product lint`
as a feedback loop before handing back.

## Prerequisites

Create a `.env` in the repo root with (replace sample values):

| Variable | Example | Required |
|---|---|---|
| `SERVER` | `https://mysepdomain.starburst.net` | Yes |
| `ROLE` | `publish_data_admin` | Yes |
| `STARBURST_USER` | `mary` | Yes |
| `STARBURST_PASSWORD` | `…` | Yes |
| `CLI_JAR` | `/absolute/path/to/dp-cli-demo/starburst-cli.jar` | Optional override |

`CLI_JAR` is optional — if unset (or pointing at a missing file), the
wrapper falls back to `./starburst-cli.jar` in the repo root.
Drop the Starburst CLI jar at that path (see
[docs/release-binary.md](docs/release-binary.md)) and you don't need to
touch `.env` for the jar.

Tools: `java`, `curl`, `python3`, `bash`.

## `starburst` command

The repo includes an executable [`starburst`](starburst) wrapper. From the
repo root:

```bash
./starburst data-product --help
```

The wrapper:

- Sources `.env` so you don't have to `set -a && source .env` in your shell.
- Auto-injects `--server`, `--user`, and `--role` for the SEP-talking
  subcommands (`import`, `export`, `publish`, `delete`) when you omit them.
- Routes **`data-product publish`** through [`scripts/publish.sh`](scripts/publish.sh)
  because the CLI's `publish` subcommand is currently a stub
  (`ERROR: publish is not yet implemented`). The wrapper resolves
  `--id` or `--domain` + `--name`, then POSTs to SEP's workflow endpoint
  and polls until the workflow finishes.

### Install globally (any directory)

The wrapper resolves symlinks, so you can link it into a directory on your
`PATH`:

```bash
./install-starburst.sh
```

This installs to `~/.local/bin/starburst` by default. If that directory is
not on your `PATH`, the script prints the line to add to `~/.zshrc` or
`~/.zprofile`.

Use another location (e.g. Homebrew prefix):

```bash
INSTALL_DIR=/opt/homebrew/bin ./install-starburst.sh
```

For a one-off session without installing, from the repo root:

```bash
alias starburst="$(pwd)/starburst"
```

## Quick start

Lint a YAML file:

```bash
./starburst data-product lint -f data-products/financial_information_report.yaml
```

Import a YAML to SEP (creates the data product):

```bash
./starburst data-product import -f data-products/financial_information_report.yaml --password --insecure
```

Re-import with overwrite:

```bash
./starburst data-product import -f data-products/financial_information_report.yaml --password --insecure --on-duplicate OVERWRITE
```

Publish (after import):

```bash
./starburst data-product publish --domain "Finance" --name "Financial Information Report" --password --insecure
```

For the full lifecycle and detailed flag reference, see
[`.agents/skills/starburst-data-product/references/lifecycle.md`](.agents/skills/starburst-data-product/references/lifecycle.md).
