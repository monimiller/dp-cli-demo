# DP CLI Demo

Starburst data product CLI examples plus an Agent Skill for data-products-as-code workflows.

## Agent skill

- Skill: [`.agents/skills/starburst-data-products/SKILL.md`](.agents/skills/starburst-data-products/SKILL.md)
- Step scripts: [`.agents/skills/starburst-data-products/scripts/`](.agents/skills/starburst-data-products/scripts/)
- Makefile: [`.agents/skills/starburst-data-products/Makefile`](.agents/skills/starburst-data-products/Makefile)
- Notes: [`.agents/skills/starburst-data-products/reference.md`](.agents/skills/starburst-data-products/reference.md)

## Prerequisites

Create a `.env` in the repo root with:

- `SERVER`  SERVER=https://mysepdomain.starburst.net
- `ROLE`  ROLE=publish_data_admin
- `STARBURST_USER`  STARBURST_USER=mary
- `STARBURST_PASSWORD`  STARBURST_PASSWORD='hadalittlelamb03'
- `CLI_JAR`  CLI_JAR="/absolute/path/to/dp-cli-demo/starburst-cli-executable" (local file; see [docs/release-binary.md](docs/release-binary.md))


Tools: `java`, `curl`, `python3`, `bash`, `make` (optional).

## `starburst` command

The repo includes an executable [`starburst`](starburst) that loads `.env` and runs `java -jar "$CLI_JAR"`. From the repo root:

```bash
./starburst data-product --help
```

### Install globally (any directory)

The wrapper resolves symlinks, so you can link it into a directory on your `PATH`:

```bash
./install-starburst.sh
```

This installs to `~/.local/bin/starburst` by default. If that directory is not on your `PATH`, the script prints a line to add to `~/.zshrc` or `~/.zprofile`.

Use another location (e.g. Homebrew prefix):

```bash
INSTALL_DIR=/opt/homebrew/bin ./install-starburst.sh
```

For a one-off session without installing, from the repo root: `alias starburst="$(pwd)/starburst"`.

## Quick start

```bash
make -C .agents/skills/starburst-data-products help
make -C .agents/skills/starburst-data-products all
```

Publish (after you have a product id):

```bash
make -C .agents/skills/starburst-data-products publish PRODUCT_ID='<product-id>'
```

Cleanup:

```bash
make -C .agents/skills/starburst-data-products cleanup PRODUCT_ID='<product-id>' DOMAIN_ID='<domain-id>'
```

## Run one step

```bash
bash .agents/skills/starburst-data-products/scripts/setup.sh
bash .agents/skills/starburst-data-products/scripts/lint.sh
```

Or use Makefile targets: `setup`, `create-domain`, `init`, `write-sample`, `lint`, `import`, `export`, `compare`, `write-modified`, `import-modified`, `import-fail`.

## Notes

- `import-fail` / `import.sh --on-duplicate FAIL` fails if the product already exists (expected).
- Cleanup requires `sysadmin` on the server and deletes resources.
