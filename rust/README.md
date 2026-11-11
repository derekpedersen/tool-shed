# Rust

Module for the Rust stable toolchain, installed and managed through the official per-user `rustup` toolchain manager.

## Files

- `install.sh`: install Rust through the shared module runtime.
- `uninstall.sh`: preserve user-managed Rust state and report that it remains installed.
- `install.windows.ps1`: Windows PowerShell install entrypoint.
- `uninstall.windows.ps1`: Windows PowerShell uninstall entrypoint.

## Usage

From the repository root:

```bash
bash ./.tools/install.sh rust
bash ./.tools/install.sh rustup
bash ./.tools/uninstall.sh rust
```

On Windows, run the module entrypoints from PowerShell:

```powershell
pwsh ./rust/install.windows.ps1
pwsh ./rust/uninstall.windows.ps1
```

## Toolchain behavior

A fresh installation selects the stable toolchain. Existing rustup installations keep their current default. Cargo's `bin` directory is added to the current installer process PATH; rustup also manages the shell-profile PATH setup during first-time installation.

Uninstall intentionally does not run `rustup self uninstall` or remove `~/.rustup` or `~/.cargo`. Those directories may contain toolchains, configuration, and binaries managed outside this repository.

On Windows, the Rust module is ordered after the `cpp` module in bundles so the MSVC linker and SDK are present for Rust's default MSVC target.
