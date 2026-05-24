# Datanova Demo — Beat Sheet

This file is the script for the live demo. When the user prompts during
the demo, follow the matching beat below **exactly**, then **stop and wait
for the next prompt**. Do not run ahead.

## Hard rules

- **One beat per user prompt.** After completing a beat, stop. Do not
  start the next beat's work, do not offer to. The user drives pacing.
- **No pull requests before Beat 5.** Beat 3 publishes via the CLI
  directly (`import` + `publish`). Beats 1–4 must not run `gh pr create`,
  `gh pr merge`, or `mcp__*__create_pull_request`. Only Beat 5 opens a PR.
- **No merging the demo PR.** Beat 5 ends at "PR opened with Edmund as
  reviewer." The merge is the human punchline — never merge it yourself.
- **No commentary about what's about to happen.** Just do the work for
  the current beat.

## Pre-stage (before the clock starts)

- Blue Ribbon Priority Orders deleted from SEP (clean slate)
- Counterparty Exposure Demo live in SEP with Edmund as sole owner
- Confluence page open in a browser tab
- `data-products/` folder visible in the file tree
- SEP open in another tab

## Beat 1 — CLI baseline (0:00–0:20)

User shows the terminal manually. **Agent is not involved.** If prompted,
stay quiet and wait.

## Beat 2 — Create (0:20–1:00)

Prompt: *"Create a data product for Blue Ribbon Iced Tea's high priority
supply chain orders. Check my Confluence for context."*

Do:
1. Fetch the Confluence page for table/column context.
2. Run the `starburst-data-product` skill's interview (only for fields the
   prompt and Confluence don't already cover).
3. Write `data-products/blue_ribbon_high_priority_orders.yaml`.
4. Lint it. Fix until it passes.
5. Stop. **Do not commit, do not push, do not open a PR.**

## Beat 3 — Commit & publish (1:00–1:20)

Prompt: *"Commit this to GitHub and publish it to SEP."*

Do:
1. `git add` + `git commit` on the current branch.
2. `git push` the branch (not main, not a PR).
3. Run `./starburst data-product import -f <file> --on-duplicate OVERWRITE`
   then `./starburst data-product publish -n "<name>"` directly against
   SEP. The CLI is the publish path for this beat — not the workflow.
4. Stop. **Do not open a PR.** The PR for this product is not part of the
   demo flow.

## Beat 4 — Edit Ryo's DP (1:20–1:50)

Prompt: *"The Counterparty Exposure Demo needs to update the description
with a new business rule to note that as of Q2 2026, all WIND_DOWN
counterparty positions require quarterly review. And add a sample query
that shows all positions in counterparties we're currently winding down.
Show me the diff when you're done."*

Do:
1. Edit `data-products/counterparty_exposure_demo.yaml`:
   - Append the WIND_DOWN quarterly review note to `description`.
   - Add a sample query for WIND_DOWN positions.
2. Lint.
3. Show the diff (`git diff data-products/counterparty_exposure_demo.yaml`).
4. Stop. **Do not commit, do not push, do not open a PR.**

## Beat 5 — PR + approval (1:50–2:10)

Prompt: *"Open a pull request for this change and assign Edmund
(@edmundmiller) as the reviewer."*

Do:
1. Commit the Beat 4 edits.
2. Push the branch.
3. `gh pr create` with Edmund as reviewer.
4. Return the PR URL. Stop. **Do not merge.** The user merges live to
   show the workflow firing.
