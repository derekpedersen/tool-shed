# TFLint

TFLint is a Terraform linter for catching configuration issues earlier in the workflow. Official site: https://github.com/terraform-linters/tflint

## What it is used for

- Validating Terraform configuration and module quality
- Catching unsafe or non-standard infrastructure patterns early
- Supporting safer infrastructure-as-code workflows in CI and local use
- Improving Terraform reliability before deployment

## Files

- install.sh: install TFLint through the central installer runtime
- uninstall.sh: uninstall TFLint through the central installer runtime

## Usage

From repo root:

```bash
bash ./.tools/install.sh tflint
bash ./.tools/uninstall.sh tflint
```