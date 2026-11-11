# Julia

Module for Julia installed and managed through the official Juliaup installer. Fresh installs use the stable `release` channel; existing Juliaup configurations are left unchanged. If Julia is already installed without Juliaup, the installer leaves it untouched. Julia is individually installable and is not part of a bundle.

## Files

- `install.sh`: install Juliaup and the Julia release channel through the shared module runtime.
- `uninstall.sh`: preserve the user-managed Juliaup installation, channels, and depot.
- `install.windows.ps1`: Windows PowerShell install entrypoint.
- `uninstall.windows.ps1`: Windows PowerShell uninstall entrypoint.

## Usage

From the repository root:

```bash
bash ./.tools/install.sh julia
bash ./.tools/install.sh juliaup
bash ./.tools/uninstall.sh julia
```

On Windows, run the module entrypoints from PowerShell:

```powershell
pwsh ./julia/install.windows.ps1
pwsh ./julia/uninstall.windows.ps1
```

## Platforms

- Debian-based Linux and macOS: official Juliaup installer.
- Windows: Juliaup from the Microsoft Store via winget.

Uninstall intentionally does not run `juliaup self uninstall` or remove `~/.julia`. Julia version channels, configuration, and package environments are user-managed data.
