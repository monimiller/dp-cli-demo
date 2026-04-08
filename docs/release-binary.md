# Starburst CLI binary (releases and local setup)

The Starburst data-product CLI is **not committed to this repository**. Attach it to [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) so clones stay small and users pick up a known build.

## GitHub Release — suggested release notes (copy/paste)

Use this as the release description body (edit the version line):

```markdown
## Starburst CLI

Download the **`starburst`** executable for your platform from Starburst (same artifact you use for `java -jar` / self-executing CLI), then:

1. Save it in the repo root as **`starburst-cli-executable`** (exact name).
2. `chmod +x starburst-cli-executable`
3. In `.env`, set:
   `CLI_JAR="/absolute/path/to/dp-cli-demo/starburst-cli-executable"`

The repo-root `starburst` script runs `java -jar "$CLI_JAR"` using that path.

**Attached to this release:** _(upload the `starburst` binary here and name the asset clearly, e.g. `starburst-cli-<version>-macos` or as provided by Starburst)._
```

## Local setup (without a release)

1. Copy your CLI file to the repo root as `starburst-cli-executable`.
2. `chmod +x starburst-cli-executable`
3. Point `CLI_JAR` in `.env` at that path (see [README](../README.md) prerequisites).

The file is listed in `.gitignore` so it stays local unless you choose to commit it.
