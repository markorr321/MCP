# PlatformScript — Scheduled Task Deployment

This folder contains the Intune Platform Script that creates the per-user registration scheduled task.

## Contents

| File | Description |
|---|---|
| `CreateScheduledTask.ps1` | Deploys registration scripts and creates the `RegisterCompanyPortal` scheduled task |

## What It Does

1. Creates `C:\ProgramData\Scripts\RegisterCompanyPortal.ps1` — a script that checks if Company Portal is installed for the current user and installs it from the staged bundle if not
2. Creates `C:\ProgramData\Scripts\RegisterCompanyPortal.vbs` — a VBS launcher that runs the PowerShell script silently (no console window)
3. Registers a `RegisterCompanyPortal` scheduled task that triggers at every user logon under the BUILTIN\Users group

## Logging

The script writes a transcript log to `C:\Windows\TEMP\CreateScheduledTask.log` for troubleshooting.

## Step-by-Step: Deploy as a Platform Script in Intune

### 1. Navigate to Platform Scripts
- Go to **Intune > Devices > Scripts and remediations > Platform scripts**
- Click **Add > Windows 10 and later**

### 2. Basics
- **Name:** Company Portal - Register Scheduled Task
- **Description:** Deploys a scheduled task that registers the Microsoft Company Portal app for each user at logon. The task checks if Company Portal is installed for the current user and, if not, installs it from a staged offline bundle. Requires the Company Portal Win32 app to be installed first.
- Click **Next**

### 3. Script settings
- Click **Browse** and upload `CreateScheduledTask.ps1` from this folder
- **Run this script using the logged on credentials:** No
- **Enforce script signature check:** No
- **Run script in 64 bit PowerShell Host:** Yes
- Click **Next**

### 4. Assignments
- Assign to the same device group as the Win32 app
- Click **Next**

### 5. Review + create
- Review settings and click **Create**
