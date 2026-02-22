# Win32 App — Package and Deploy

This folder contains the scripts and packages used to build and deploy the Intune Win32 app.

## Contents

| File | Description |
|---|---|
| `Install.ps1` | Main install script — provisions Company Portal and stages the bundle + dependencies |
| `Uninstall.ps1` | Uninstall script — removes the app, scheduled task, registration scripts, and staged files |
| `*.appxbundle` | Company Portal offline bundle |
| `*_License1.xml` | Offline license file |
| `*.appx` | Framework dependency packages (x64) |

## Step 1: Package the Win32 App

### 1. Download the Content Prep Tool
- Download the [Microsoft Win32 Content Prep Tool](https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool) from GitHub
- Extract `IntuneWinAppUtil.exe` to a local folder

### 2. Verify your source folder
- Make sure this `Win32/` folder contains all required files:
  - `Install.ps1`
  - `Uninstall.ps1`
  - `*.appxbundle` (Company Portal bundle)
  - `*_License1.xml` (offline license)
  - All five `.appx` dependency packages

### 3. Run the tool
- Open a command prompt or PowerShell window
- Navigate to where you extracted `IntuneWinAppUtil.exe`
- Run:
  ```
  IntuneWinAppUtil.exe -c Win32 -s Install.ps1 -o IntuneWin
  ```
  - `-c Win32` — the source folder containing your scripts and packages
  - `-s Install.ps1` — the setup file (entry point for the install)
  - `-o IntuneWin` — the output folder where the `.intunewin` will be saved

### 4. Confirm the output
- Check the `IntuneWin/` folder for `Install.intunewin`
- This is the file you upload to Intune in the next step

## Step 2: Configure the Win32 App in Intune

### 1. Create the app
- Go to **Intune > Apps > All apps > Add**
- Select **Windows app (Win32)** as the app type
- Click **Select**

### 2. Upload the package
- Click **Select app package file**
- Browse to and upload `Install.intunewin` from the `IntuneWin/` folder
- Click **OK**

### 3. App information
- **Name:** Microsoft Company Portal (Offline)
- **Description:** Offline deployment of Company Portal with per-user registration via scheduled task
- **Publisher:** Microsoft
- **Logo:** Upload `CompanyPortal-Logo.png` from the `Logo/` folder
- Fill in any other fields per your org's standards
- Click **Next**

### 4. Program
- **Install command:** `powershell.exe -ExecutionPolicy Bypass -File .\Install.ps1`
- **Uninstall command:** `powershell.exe -ExecutionPolicy Bypass -File .\Uninstall.ps1`
- **Install behavior:** System
- **Device restart behavior:** No specific action
- Click **Next**

### 5. Requirements
- **Operating system architecture:** 64-bit
- **Minimum operating system:** Windows 10 1903 (or your org's minimum)
- Click **Next**

### 6. Detection rules
- **Rules format:** Use a custom detection script
- Click **Browse** and upload `Detect.ps1` from the `Detection Script/` folder
- **Run script as 32-bit process on 64-bit clients:** No
- **Enforce script signature check:** No

The detection script checks two conditions:
1. **Provisioned** — Is `Microsoft.CompanyPortal` in the provisioned package list? (covers new user profiles)
2. **Installed** — Is `Microsoft.CompanyPortal` installed for any user? (covers existing profiles and auto-updates)

If either condition is true, the script exits with code `0` (detected). Otherwise, it exits with code `1` (not detected).

- Click **Next**

### 7. Dependencies
- Skip unless you have other apps that must install first
- Click **Next**

### 8. Supersedence
- Skip unless you're replacing an existing Company Portal deployment
- Click **Next**

### 9. Assignments
- Assign to your target device group as **Required**
- Click **Next**

### 10. Review + create
- Review settings and click **Create**
