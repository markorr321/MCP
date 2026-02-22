# IntuneWin — Packaged Output

This folder contains the pre-packaged `.intunewin` file ready for upload to Intune.

## Contents

| File | Description |
|---|---|
| `Install.intunewin` | Packaged Win32 app containing all scripts, the Company Portal bundle, license, and dependencies |

## Step-by-Step: Wrap the Win32 App

### 1. Download the tool
- Download the [Microsoft Win32 Content Prep Tool](https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool) from GitHub
- Extract `IntuneWinAppUtil.exe` to a local folder

### 2. Verify your source folder
- Make sure the `Win32/` folder contains all required files:
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
- This is the file you upload to Intune when creating the Win32 app

## Step-by-Step: Upload to Intune

1. Go to **Intune > Apps > All apps > Add**
2. Select **Windows app (Win32)** as the app type
3. Click **Select app package file**
4. Browse to and upload `Install.intunewin` from this folder
5. Click **OK**
6. Continue with the app configuration (see `Win32/Win32-App-Source-Files.md` for full setup steps)
