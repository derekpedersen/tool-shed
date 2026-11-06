# Python 3

Python 3 is a general-purpose scripting language widely used for automation, data work, API tooling, and machine learning. Official site: https://www.python.org/

## What it is used for

- Writing scripts and automation for local and CI workflows
- Managing data processing, analysis, and ETL tasks
- Building APIs, tooling, and automation for dev environments
- Supporting Python-based ML, data science, and developer utilities

## Files

- install.sh: install Python 3 through the central installer runtime
- uninstall.sh: uninstall Python 3 through the central installer runtime
- install.windows.ps1: PowerShell wrapper for Python 3 installation on Windows
- pip-tools.sh: reviewable list of Python tools managed with pip

## Aliases

Accepted alias names: python, python3

## Usage

From repo root:

```bash
bash ./.tools/install.sh python3
bash ./.tools/uninstall.sh python3
```

PowerShell (Windows):

```powershell
pwsh ./python3/install.windows.ps1
```

## Python tool manifest

Use the standalone manifest script to review or install a curated list of Python tools without changing the central installer flow.

### Review the list

```bash
bash python3/pip-tools.sh --list
```

### Preview the installs

```bash
bash python3/pip-tools.sh --dry-run
```

### Install the tools

```bash
bash python3/pip-tools.sh --install
```

### Update the manifest

Edit the `PYTHON_TOOLS` array at the top of `python3/pip-tools.sh` and keep the list in one place for easy review and updates.

### Notes

- This is a user-scoped Python tool manifest, not a central installer bundle change.
- It relies on Python 3 and pip being available first.
- Use `--dry-run` before installing to review changes safely.

