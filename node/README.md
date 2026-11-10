# Node.js

Node.js is a JavaScript runtime for building web apps, developer tooling, serverless functions, and frontend build pipelines. Official site: https://nodejs.org/

## What it is used for

- Running JavaScript and TypeScript server-side applications
- Building web frontends and local toolchains with npm
- Supporting automation, scripts, and CLI utilities
- Working with modern JavaScript ecosystems and package management

## Files

- install.sh: install Node.js through the central installer runtime
- uninstall.sh: uninstall Node.js through the central installer runtime
- install.windows.ps1: PowerShell wrapper for Node.js installation on Windows

## Usage

From repo root:

```bash
bash ./.tools/install.sh node
bash ./.tools/uninstall.sh node
```

PowerShell (Windows):

```powershell
pwsh ./node/install.windows.ps1
```

