# Repo context for Claude

This repo is a live demo of Data Products as Code on Starburst SEP.
Keep responses tight — the user is presenting.

**Demo script: [DEMO.md](DEMO.md).** When a prompt matches a beat there,
follow that beat exactly and stop. One beat per prompt — do not run
ahead, do not chain beats. The "Hard rules" section is binding,
especially: **never merge the demo PR yourself** — the human merge is
the punchline.

For Beats 1–4, pushing directly to main is fine — but always confirm
with the user before pushing.

## What lives where

- `data-products/*.yaml` — the products. Edits here are the source of truth.
- `.agents/skills/starburst-data-product/` — the skill for authoring/editing
  these YAMLs. SKILL.md is the entry; references/ is loaded on demand.
- `./starburst` — wrapper around the CLI jar. Sources `.env`, verifies the
  jar's md5 against `.starburst-cli.jar.md5`, and injects
  `--server/--user/--role` for SEP-talking subcommands.
- `.env` — SEP connection (gitignored). Already populated for the demo.
- `.github/workflows/deploy-data-products.yml` — on push to main, lints,
  imports, and publishes any changed `data-products/*.yaml`.
- `.github/CODEOWNERS` — `data-products/counterparty_exposure_demo.yaml`
  auto-requests review from `@edmundmiller`.

## Working on a data product

After any edit to a `data-products/*.yaml`:

```bash
./starburst data-product lint -f data-products/<file>.yaml
```

Lint is the fast feedback loop — it runs offline, no SEP needed. Don't ask
the user whether to save the file; just write it and lint.

Use the `starburst-data-product` skill for authoring guidance. Field
semantics, lint error triage, and lifecycle commands are in
`.agents/skills/starburst-data-product/references/`.

## Don't, during the demo

- Don't echo `.env` contents or any credentials.
- Don't push to main without confirming first. Pushing is allowed for
  Beats 1–4; just check with the user before doing it.
- Don't run `import` or `publish` ad-hoc against SEP unless the user asks
  (Beat 3 is an explicit ask; the workflow handles deploy on merge otherwise).
- Don't add commentary about what you're about to demo — just do the work.
- When a new data product is derived from `financial_information_report.yaml`
  plus a Confluence page, don't say you used `financial_information_report`
  as a template. Talk about the product as the business artifact it
  represents, not the demo plumbing behind it.
- Don't open a PR unless the active beat in [DEMO.md](DEMO.md) calls for one.
- After finishing the current beat, **stop**. Do not preview or start the
  next beat's work. The user drives pacing prompt-by-prompt.
