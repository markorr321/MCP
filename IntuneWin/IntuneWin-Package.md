# IntuneWin — Packaged Output

This folder contains the pre-packaged `.intunewin` file ready for upload to Intune.

## Contents

| File | Description |
|---|---|
| `Install.intunewin` | Packaged Win32 app containing all scripts, the Company Portal bundle, license, and dependencies |

## Usage

Upload `Install.intunewin` directly to Intune when creating the Win32 app (Apps > All apps > Add > Windows app (Win32)).

## Re-packaging

If you make changes to any files in the `Win32/` folder, re-package using the [Microsoft Win32 Content Prep Tool](https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool):

```
IntuneWinAppUtil.exe -c Win32 -s Install.ps1 -o IntuneWin
```

This will overwrite the existing `Install.intunewin` with an updated package.
