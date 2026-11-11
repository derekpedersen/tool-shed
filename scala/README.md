# Scala

Module for the Scala 3 toolchain using Scala CLI. Scala CLI provides a REPL and can compile, run, test, and package Scala sources. It also supports Java sources.

## Files

- `install.sh`: install Scala CLI through the shared module runtime.
- `uninstall.sh`: uninstall Scala CLI without deleting its caches.
- `install.windows.ps1`: Windows PowerShell install entrypoint.
- `uninstall.windows.ps1`: Windows PowerShell uninstall entrypoint.

## Usage

From the repository root:

```bash
bash ./.tools/install.sh scala
bash ./.tools/install.sh scala-cli
bash ./.tools/uninstall.sh scala
```

Run Scala code with the `scala-cli` command:

```bash
scala-cli run Hello.scala
scala-cli repl
```

On Windows, run the module entrypoints from PowerShell:

```powershell
pwsh ./scala/install.windows.ps1
pwsh ./scala/uninstall.windows.ps1
```

## Platforms

- Debian-based Linux and macOS: official Scala CLI home installer.
- Windows: `VirtusLab.ScalaCLI` through winget.

The `full` and `ai` bundles install Java before Scala CLI. Scala CLI may download compiler and JVM artifacts on first use; those caches are preserved when the tool is uninstalled.
