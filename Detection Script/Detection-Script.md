# Detection Script

This folder contains the custom detection script used by the Win32 app in Intune.

## Contents

| File | Description |
|---|---|
| `Detect.ps1` | Checks whether Company Portal is provisioned or installed on the device |

## How It Works

The script checks two conditions:

1. **Provisioned** — Is `Microsoft.CompanyPortal` in the provisioned package list? (covers new user profiles)
2. **Installed** — Is `Microsoft.CompanyPortal` installed for any user? (covers existing profiles and auto-updates)

If either condition is true, the script exits with code `0` (detected). Otherwise, it exits with code `1` (not detected).

## Intune Configuration

When configuring the Win32 app detection rule:

- **Rules format:** Use a custom detection script
- **Script file:** Upload `Detect.ps1`
- **Run script as 32-bit process on 64-bit clients:** No
- **Enforce script signature check:** No
