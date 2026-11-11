# direnv

direnv loads and unloads environment variables automatically based on the current directory. Official site: https://direnv.net/

## What it is used for

- Loading project-specific environment variables automatically
- Keeping local dev environments consistent per repository
- Simplifying `.envrc`-based developer workflows
- Reducing manual shell export setup across projects

## Files

- install.sh: install direnv through the central installer runtime
- uninstall.sh: uninstall direnv through the central installer runtime

## Usage

From repo root:

```bash
bash ./.tools/install.sh direnv
bash ./.tools/uninstall.sh direnv
```