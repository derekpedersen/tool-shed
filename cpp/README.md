# C/C++ Build Tools

Module for native C and C++ compiler toolchains. It does not install CMake or Ninja.

## Files

- `install.sh`: install C/C++ tools through the shared module runtime.
- `uninstall.sh`: uninstall the package where safely supported.
- `install.windows.ps1`: Windows PowerShell install entrypoint.
- `uninstall.windows.ps1`: Windows PowerShell uninstall entrypoint.

## Usage

From the repository root:

```bash
bash ./.tools/install.sh cpp
bash ./.tools/install.sh 'c++'
bash ./.tools/uninstall.sh cpp
```

On Windows, run the module entrypoints from PowerShell:

```powershell
pwsh ./cpp/install.windows.ps1
pwsh ./cpp/uninstall.windows.ps1
```

## Platforms

- Debian-based Linux: `build-essential`.
- macOS: Apple Command Line Tools. macOS asks for confirmation to start the system-managed installation.
- Windows: Visual Studio 2022 Build Tools with the C++ workload and Windows 11 SDK. This downloads a substantial toolchain.

Uninstall removes the Debian package or Visual Studio Build Tools package when present. Apple Command Line Tools are left installed because they are system-managed and may be shared with other software.
