# dp-cli-demo

This repository includes a manual GitHub Actions workflow to deploy a data product YAML and optionally create a demo pull request.

## Workflow

- Workflow file: `.github/workflows/deploy-data-product.yml`
- Deploy action: `.github/actions/data-product-update/action.yml`
- Trigger: manual (`workflow_dispatch`)
- Default YAML target: `data-products/demo_product.yaml`

### Inputs

- `yaml_path`: path to the YAML file to deploy
- `duplicate_mode`: `OVERWRITE` or `FAIL`
- `create_demo_pr`: when `true`, creates/updates a demo PR that bumps `data-products/.demo-pr-version`

## Composite action interface

The deploy/update logic is abstracted into a local composite action with this interface:

- Required inputs:
  - `yaml_path`
  - `duplicate_mode`
  - `server`
  - `role`
  - `starburst_user`
  - `starburst_password`
  - `cli_jar`
- Optional inputs:
  - `insecure` (default: `true`)
  - `run_lint` (default: `true`)
  - `write_summary` (default: `true`)
- Outputs:
  - `status` (`success` or `failure`)
  - `deployed_yaml`
  - `duplicate_mode_used`

The workflow keeps user-facing controls in `workflow_dispatch`, then forwards values and secrets into the composite action.

## Required GitHub repository secrets

Set the following secrets in your repository settings:

- `SERVER`
- `ROLE`
- `STARBURST_USER`
- `STARBURST_PASSWORD`
- `CLI_JAR`

`CLI_JAR` can be either:

- an HTTPS URL to the Starburst CLI jar (recommended), or
- a file path that exists on the GitHub runner.

## How to run

1. Open the GitHub repository.
2. Go to **Actions**.
3. Open **Deploy Data Product**.
4. Click **Run workflow**.
5. Optionally change inputs, then run.

After a successful deploy, if `create_demo_pr=true`, the workflow opens or updates a PR from branch `demo/pr-bump` with a marker-file bump.
