# Starburst CLI binary (releases and local setup)

The Starburst data-product CLI is **not committed to this repository**. Attach it to [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) so clones stay small and users pick up a known build.

## GitHub Release — suggested release notes (copy/paste)

Use this as the release description body (edit the version line):

```markdown
## Starburst CLI

Download the **`starburst`** executable for your platform from Starburst (same artifact you use for `java -jar` / self-executing CLI), then:

1. Save it in the repo root as **`starburst-cli.jar`** (exact name).

That's it. The repo-root `./starburst` wrapper auto-discovers the jar at
that path — you don't need to touch `.env` unless you want to point at a
jar somewhere else (set `CLI_JAR` to override).

**Attached to this release:** _(upload the jar here and name the asset clearly, e.g. `starburst-cli-<version>.jar` or as provided by Starburst)._
```

## Local setup (without a release)

1. Copy your CLI jar to the repo root as `starburst-cli.jar`.

`./starburst data-product --help` should now work. The file is listed in
`.gitignore` so it stays local unless you choose to commit it.

To point at a jar somewhere else, set `CLI_JAR` in `.env` to its absolute
path — the wrapper prefers `CLI_JAR` when it's set and the file exists,
otherwise falls back to `./starburst-cli.jar`.
