# Java

Module for the Eclipse Temurin OpenJDK 25 developer toolchain. The JDK provides both `java` and `javac`.

## Files

- `install.sh`: install Java through the shared module runtime.
- `uninstall.sh`: uninstall Java through the shared module runtime.
- `install.windows.ps1`: Windows PowerShell install entrypoint.
- `uninstall.windows.ps1`: Windows PowerShell uninstall entrypoint.

## Usage

From the repository root:

```bash
bash ./.tools/install.sh java
bash ./.tools/uninstall.sh java
```

`jdk` is also accepted as an alias:

```bash
bash ./.tools/install.sh jdk
```

On Windows, run the module entrypoints from PowerShell:

```powershell
pwsh ./java/install.windows.ps1
pwsh ./java/uninstall.windows.ps1
```

## Platforms

- Debian-based Linux: Temurin 25 from the Eclipse Adoptium apt repository.
- macOS: Temurin 25 from the Homebrew `temurin@25` cask.
- Windows: Temurin 25 JDK from winget.

The installers use each platform's Java discovery and PATH defaults. They do not configure `JAVA_HOME`.
