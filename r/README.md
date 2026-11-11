# R

Module for the R interpreter, used for statistical computing and graphics. This module installs the runtime only; CRAN packages remain project-managed.

## Files

- `install.sh`: install R through the shared module runtime.
- `uninstall.sh`: uninstall the R runtime through the shared module runtime.
- `install.windows.ps1`: Windows PowerShell install entrypoint.
- `uninstall.windows.ps1`: Windows PowerShell uninstall entrypoint.

## Usage

From the repository root:

```bash
bash ./.tools/install.sh r
bash ./.tools/install.sh R
bash ./.tools/uninstall.sh r
```

`r-lang` is also accepted as an alias.

On Windows, run the module entrypoints from PowerShell:

```powershell
pwsh ./r/install.windows.ps1
pwsh ./r/uninstall.windows.ps1
```

## Platforms

- Debian-based Linux: `r-base`.
- macOS: Homebrew `r` formula.
- Windows: `RProject.R` through winget.

R packages and user libraries are not installed or removed by this module.
