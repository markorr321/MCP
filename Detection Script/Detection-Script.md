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

## Step-by-Step: Configure the Detection Rule in Intune

This script is uploaded during the Win32 app configuration (step 6 of the app setup).

1. On the **Detection rules** tab, set **Rules format** to **Use a custom detection script**
2. Click **Browse** and select `Detect.ps1` from this folder
3. Set **Run script as 32-bit process on 64-bit clients** to **No**
4. Set **Enforce script signature check** to **No**
5. Click **Next**
