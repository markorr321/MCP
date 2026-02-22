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

## Intune Configuration

Deploy as a Platform Script under Devices > Scripts and remediations > Platform scripts.

| Setting | Value |
|---|---|
| **Name** | Company Portal - Register Scheduled Task |
| **Run this script using the logged on credentials** | No |
| **Enforce script signature check** | No |
| **Run script in 64 bit PowerShell Host** | Yes |
