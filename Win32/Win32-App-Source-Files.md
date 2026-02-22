# Win32 — Source Files

This folder contains the scripts and packages used to build the Intune Win32 app.

## Contents

| File | Description |
|---|---|
| `Install.ps1` | Main install script — provisions Company Portal and stages the bundle + dependencies |
| `Uninstall.ps1` | Uninstall script — removes the app, scheduled task, registration scripts, and staged files |
| `*.appxbundle` | Company Portal offline bundle |
| `*_License1.xml` | Offline license file |
| `*.appx` | Framework dependency packages (x64) |

## Packaging

To wrap these files into an `.intunewin` package, use the [Microsoft Win32 Content Prep Tool](https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool):

```
IntuneWinAppUtil.exe -c Win32 -s Install.ps1 -o IntuneWin
```

The output will be saved to the `IntuneWin/` folder.

## Intune Configuration

| Setting | Value |
|---|---|
| **Install command** | `powershell.exe -ExecutionPolicy Bypass -File .\Install.ps1` |
| **Uninstall command** | `powershell.exe -ExecutionPolicy Bypass -File .\Uninstall.ps1` |
| **Install behavior** | System |
| **Detection rule** | Custom detection script — upload `Detect.ps1` from the `Detection Script/` folder |
