# Microsoft Company Portal - Intune Deployment Solution

Offline deployment package for provisioning the Microsoft Company Portal app via Microsoft Intune. Designed for scenarios where the Microsoft Store is unavailable or ESP (Enrollment Status Page) skips account setup, leaving Company Portal unregistered for end users.

## Problem

Deploying Company Portal through the Microsoft Store (New) app type in Intune has unreliable install behavior — the app is frequently unavailable at first user login during Autopilot enrollment, especially when ESP skips the account setup phase. For more background on this issue, see [Improving Onboarding Experience: Automatically Launch the Company Portal](https://patchmypc.com/blog/launching-the-company-portal-automatically-after-autopilot/).

Existing workarounds like deploying Company Portal as an offline LOB app solve the availability problem, but the app version is static and can't be updated unless Microsoft publishes new offline source files.

This solution instead uses the new [Intune Win32 PowerShell installer type](https://powershellisfun.com/2026/01/23/intune-win32-powershell-installer-type/), which allows the install and uninstall scripts to be updated directly in Intune without recreating the `.intunewin` package. Script logic can be iterated on independently from the bundled app payload.

## How It Works

The solution uses a two-phase approach:

1. **System-level provisioning** - `Install.ps1` provisions the Company Portal `.appxbundle` with its dependencies and license so it is available to all users on the device.
2. **Per-user registration** - A scheduled task (`RegisterCompanyPortal`) checks whether Company Portal is registered for the current user and registers it from the provisioned package if not. The task fires on two triggers:
   - **Registration trigger** (30-second delay) — registers the app for the current user immediately after install, so it's available during the active session without waiting for a logoff/logon cycle.
   - **Logon trigger** — catches any future users who log in after provisioning.

## Repository Structure

```
PowerShell/
  Install.ps1                  # Main install script (deploy via Intune)
  Uninstall.ps1                # Uninstall script (removes app + scheduled task)
  RegisterCompanyPortal.ps1    # Standalone per-user registration script
  CreateScheduledTask.ps1      # Standalone scheduled task creation script
  Register-MCP/                # Standalone module (task XML + scripts)
    installtask.ps1            # Copies registration script and creates the scheduled task
    RegisterCompanyPortal.ps1  # Per-user registration logic
    RegisterCompanyPortal.xml  # Exported scheduled task XML definition
  *.appx                       # Dependency packages (x64)
  *.appxbundle                 # Company Portal offline bundle
  *_License1.xml               # Offline license file
RegisterCompanyPortal.xml      # Exported scheduled task XML (root copy)
```

## Intune Deployment

### Package as a Win32 App

1. Place all files from `PowerShell/` into a single source folder (scripts, `.appxbundle`, `.appx` dependencies, and license XML).
2. Use the [Microsoft Win32 Content Prep Tool](https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool) to wrap the folder into an `.intunewin` file:
   ```
   IntuneWinAppUtil.exe -c <source_folder> -s Install.ps1 -o <output_folder>
   ```
3. Upload the `.intunewin` to Intune as a Win32 app.

### Intune App Configuration

When configuring the app in Intune, select **PowerShell Script** as the installer type (type any character in the installer type field to reveal the option). This lets you update the install/uninstall scripts directly in Intune without repackaging.

| Setting | Value |
|---|---|
| **Installer type** | PowerShell Script |
| **Install script** | `Install.ps1` |
| **Uninstall script** | `Uninstall.ps1` |
| **Install behavior** | System |
| **Detection rule** | Registry or file-based rule checking for `Microsoft.CompanyPortal` provisioned package |

### Detection Rule Example

Use a **custom script** or a **file rule**:
- **Path:** `C:\ProgramData\Scripts`
- **File:** `RegisterCompanyPortal.ps1`
- **Detection method:** File or folder exists

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

The `RegisterCompanyPortal` scheduled task is created with the following behavior:

- **Triggers:** Runs at user logon and once on task registration (30-second delay)
- **Principal:** BUILTIN\Users group, least privilege
- **Action:** Runs `C:\ProgramData\Scripts\RegisterCompanyPortal.ps1` via PowerShell (hidden window, execution policy bypass)
- **Behavior:** Checks if Company Portal is registered for the current user; if not, finds the provisioned package in `WindowsApps` and registers it

## Uninstall

`Uninstall.ps1` performs a full cleanup:

1. Removes the provisioned package (prevents install for new users)
2. Removes the installed package for all existing user profiles
3. Deletes the `RegisterCompanyPortal` scheduled task
4. Removes the registration script from `C:\ProgramData\Scripts`
