$ErrorActionPreference = "Stop"
Start-Transcript -Path "C:\ProgramData\CompanyPortalInstall.log" -Force

# Determine architecture for dependency selection
$arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

# Build dependency paths
$dependencies = @(
    "Microsoft.VCLibs.140.00_14.0.33519.0_${arch}__8wekyb3d8bbwe.appx",
    "Microsoft.NET.Native.Framework.2.2_2.2.29512.0_${arch}__8wekyb3d8bbwe.appx",
    "Microsoft.NET.Native.Runtime.2.2_2.2.28604.0_${arch}__8wekyb3d8bbwe.appx",
    "Microsoft.UI.Xaml.2.7_7.2409.9001.0_${arch}__8wekyb3d8bbwe.appx",
    "Microsoft.Services.Store.Engagement_10.0.23012.0_${arch}__8wekyb3d8bbwe.appx"
)

$depPaths = @()
foreach ($dep in $dependencies) {
    $depPath = Join-Path $PSScriptRoot $dep
    if (Test-Path $depPath) {
        Write-Host "Including dependency: $dep"
        $depPaths += $depPath
    } else {
        Write-Warning "Dependency not found: $depPath"
    }
}

# Install Company Portal with license and all dependencies together
$bundlePath = Join-Path $PSScriptRoot "c797dbb4414543f59d35e59e5225824e.appxbundle"
$licensePath = Join-Path $PSScriptRoot "c797dbb4414543f59d35e59e5225824e_License1.xml"

Write-Host "Bundle path: $bundlePath (Exists: $(Test-Path $bundlePath))"
Write-Host "License path: $licensePath (Exists: $(Test-Path $licensePath))"
Write-Host "Dependencies found: $($depPaths.Count)"

# Remove existing provisioned package if present (prevents version conflict)
$existing = Get-AppxProvisionedPackage -Online |
    Where-Object { $_.DisplayName -eq "Microsoft.CompanyPortal" }
if ($existing) {
    Write-Host "Removing existing provisioned package: $($existing.PackageName)"
    Remove-AppxProvisionedPackage -Online -PackageName $existing.PackageName | Out-Null
}

Write-Host "Provisioning Company Portal with dependencies..."
Add-AppxProvisionedPackage -Online -PackagePath $bundlePath -LicensePath $licensePath -DependencyPackagePath $depPaths | Out-Null

# Register for any existing user profiles (covers scenarios where a user is already logged in)
$pkg = Get-AppxPackage -AllUsers -Name "Microsoft.CompanyPortal" -ErrorAction SilentlyContinue
if ($pkg) {
    foreach ($p in @($pkg)) {
        $manifest = Join-Path $p.InstallLocation "AppxManifest.xml"
        if (Test-Path $manifest) {
            Write-Host "Registering for existing users from: $($p.InstallLocation)"
            Add-AppxPackage -Register $manifest -DisableDevelopmentMode -ForceApplicationShutdown -ErrorAction SilentlyContinue
        }
    }
}

# Create a one-time logon task to register Company Portal at first user sign-in
# This ensures the app is immediately available when ESP skips account setup
$taskName = "RegisterCompanyPortal"
$taskScript = @'
$pkg = Get-AppxPackage -Name "Microsoft.CompanyPortal" -ErrorAction SilentlyContinue
if (-not $pkg) {
    $allPkg = Get-AppxPackage -AllUsers -Name "Microsoft.CompanyPortal" -ErrorAction SilentlyContinue
    if ($allPkg) {
        $manifest = Join-Path $allPkg[0].InstallLocation "AppxManifest.xml"
        if (Test-Path $manifest) {
            Add-AppxPackage -Register $manifest -DisableDevelopmentMode -ForceApplicationShutdown
        }
    }
}
Unregister-ScheduledTask -TaskName "RegisterCompanyPortal" -Confirm:$false
'@

$scriptPath = "C:\ProgramData\RegisterCompanyPortal.ps1"
Set-Content -Path $scriptPath -Value $taskScript -Force

$action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings `
    -Principal (New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users" -RunLevel Limited) `
    -Force | Out-Null

Write-Host "Logon registration task created: $taskName"

# Verify installation
$provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq "Microsoft.CompanyPortal" }
$installed = Get-AppxPackage -AllUsers -Name "Microsoft.CompanyPortal"

Write-Host "Provisioned: $($provisioned -ne $null)"
Write-Host "Installed for users: $($installed -ne $null)"

Stop-Transcript

Write-Host "Installation complete."
exit 0
