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

Write-Host "Installing Company Portal with dependencies..."
Add-AppxProvisionedPackage -Online -PackagePath $bundlePath -LicensePath $licensePath -DependencyPackagePath $depPaths | Out-Null

# Verify installation
$provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq "Microsoft.CompanyPortal" }
$installed = Get-AppxPackage -AllUsers -Name "Microsoft.CompanyPortal"

Write-Host "Provisioned: $($provisioned -ne $null)"
Write-Host "Installed for users: $($installed -ne $null)"

Stop-Transcript

Write-Host "Installation complete."
exit 0
