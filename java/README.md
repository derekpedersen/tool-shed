# Java

Java is a general-purpose programming language and runtime used for JVM-based applications, backend services, and developer tooling. This module installs the Eclipse Temurin OpenJDK 25 toolchain, providing both `java` and `javac`.

## What it is used for

- Running Java applications and JVM-based services
- Building and testing enterprise backend applications
- Supporting toolchains such as Maven, Gradle, and Spring Boot
- Local developer environments for Java-focused projects

## Files

- `install.sh`: install Java through the shared module runtime.
- `uninstall.sh`: uninstall Java through the shared module runtime.
- `install.windows.ps1`: Windows PowerShell install entrypoint.
- `uninstall.windows.ps1`: Windows PowerShell uninstall entrypoint.

## Aliases

Accepted aliases: `java`, `jdk`, `openjdk`, and `temurin`.

## Usage

From the repository root:

```bash
bash ./.tools/install.sh java
bash ./.tools/uninstall.sh java
```

Dry run:

```bash
bash ./.tools/install.sh java --dry-run
bash ./.tools/uninstall.sh java --dry-run
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
