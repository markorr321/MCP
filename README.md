# Microsoft Company Portal - Intune Deployment Solution

Offline deployment package for provisioning the Microsoft Company Portal app via Microsoft Intune. Designed for scenarios where the Microsoft Store is unavailable or ESP (Enrollment Status Page) skips account setup, leaving Company Portal unregistered for end users.

## Problem

Deploying Company Portal through the Microsoft Store (New) app type in Intune has unreliable install behavior — the app is frequently unavailable at first user login during Autopilot enrollment, especially when ESP skips the account setup phase. For more background on this issue, see [Improving Onboarding Experience: Automatically Launch the Company Portal](https://patchmypc.com/blog/launching-the-company-portal-automatically-after-autopilot/).

Existing workarounds like deploying Company Portal as an offline LOB app solve the availability problem, but the app version is static and can't be updated unless Microsoft publishes new offline source files.

This solution deploys Company Portal as a Win32 app with PowerShell scripts called via the standard command line installer type.

## How It Works

The solution uses a two-part approach deployed through separate Intune policies:

1. **Win32 App — System-level provisioning** — `Install.ps1` provisions the Company Portal `.appxbundle` with its dependencies and license so it is available to all users on the device. It also stages the bundle and dependency files to `C:\ProgramData\CompanyPortal` for user-context registration.
2. **Platform Script — Per-user registration** — `CreateScheduledTask.ps1` is deployed as an Intune Platform Script. It writes a registration script and VBS launcher to `C:\ProgramData\Scripts` and creates a `RegisterCompanyPortal` scheduled task that triggers at user logon. The task installs Company Portal from the staged bundle for any user who doesn't already have it.

## Repository Structure

```
Win32/
  Install.ps1                  # Main install script (Win32 app)
  Uninstall.ps1                # Uninstall script (removes app, task, and staged files)
  Install.intunewin            # Pre-packaged .intunewin for upload
  *.appx                       # Dependency packages (x64)
  *.appxbundle                 # Company Portal offline bundle
  *_License1.xml               # Offline license file
Detection Script/
  Detect.ps1                   # Custom detection script for Intune
PlatformScript/
  CreateScheduledTask.ps1      # Platform Script — creates scheduled task + registration scripts
```

## Intune Deployment

### 1. Win32 App

Upload `Install.intunewin` from the `Win32/` folder to Intune as a Win32 app.

To re-package after making changes, use the [Microsoft Win32 Content Prep Tool](https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool):
```
IntuneWinAppUtil.exe -c Win32 -s Install.ps1 -o Win32
```

#### App Configuration

| Setting | Value |
|---|---|
| **Install command** | `powershell.exe -ExecutionPolicy Bypass -File .\Install.ps1` |
| **Uninstall command** | `powershell.exe -ExecutionPolicy Bypass -File .\Uninstall.ps1` |
| **Install behavior** | System |
| **Detection rule** | Custom detection script — upload `Detection Script\Detect.ps1` |

### 2. Platform Script

Deploy `PlatformScript\CreateScheduledTask.ps1` as an Intune **Platform Script** (Devices > Scripts and remediations > Platform scripts).

| Setting | Value |
|---|---|
| **Run this script using the logged on credentials** | No (run as system) |
| **Run script in 64 bit PowerShell Host** | Yes |

## Dependencies

Download the offline Company Portal package (`.appxbundle`, license XML, and framework dependencies) from the Microsoft Download Center:

https://www.microsoft.com/en-us/download/details.aspx?id=108156

The following framework dependencies are included for x64 and must be in the same directory as `Install.ps1`:

- Microsoft.VCLibs.140.00
- Microsoft.NET.Native.Framework.2.2
- Microsoft.NET.Native.Runtime.2.2
- Microsoft.UI.Xaml.2.7
- Microsoft.Services.Store.Engagement

The install script automatically selects the correct architecture (x64/x86) at runtime.

## Scheduled Task Details

The `RegisterCompanyPortal` scheduled task is created by the Platform Script with the following behavior:

- **Trigger:** Runs at user logon
- **Principal:** BUILTIN\Users group (SID `S-1-5-32-545`), least privilege
- **Action:** Runs `C:\ProgramData\Scripts\RegisterCompanyPortal.vbs` — a VBS launcher that invokes PowerShell silently (no console window popup)
- **Behavior:** Checks if Company Portal is installed for the current user; if not, installs it from the staged bundle and dependencies in `C:\ProgramData\CompanyPortal`

## Uninstall

`Uninstall.ps1` performs a full cleanup:

1. Removes the provisioned package (prevents install for new users)
2. Removes the installed package for all existing user profiles
3. Deletes the `RegisterCompanyPortal` scheduled task
4. Removes the registration scripts from `C:\ProgramData\Scripts`
5. Removes the staged bundle and dependencies from `C:\ProgramData\CompanyPortal`
