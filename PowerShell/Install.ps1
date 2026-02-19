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

try {
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
} catch {
    Write-Warning "Provisioning failed: $_"
}

# Copy registration script and create scheduled task via schtasks.exe + XML
$destination = "C:\ProgramData\Scripts"
if (!(Test-Path $destination)) {
    mkdir $destination
}

$taskScript = @'
$pkg = Get-AppxPackage -Name "Microsoft.CompanyPortal" -ErrorAction SilentlyContinue
if (-not $pkg) {
    $path = Get-ChildItem "C:\Program Files\WindowsApps\Microsoft.CompanyPortal_*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($path) {
        $manifest = Join-Path $path.FullName "AppxManifest.xml"
        if (Test-Path $manifest) {
            Add-AppxPackage -Register $manifest -DisableDevelopmentMode -ForceApplicationShutdown
        }
    }
}
'@

Set-Content -Path "$destination\RegisterCompanyPortal.ps1" -Value $taskScript -Force

$taskXml = @'
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <URI>\RegisterCompanyPortal</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <ExecutionTimeLimit>P1D</ExecutionTimeLimit>
      <Enabled>true</Enabled>
    </LogonTrigger>
    <RegistrationTrigger>
      <Delay>PT30S</Delay>
      <Enabled>true</Enabled>
    </RegistrationTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <GroupId>S-1-5-32-545</GroupId>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Command>
      <Arguments>-executionpolicy bypass -windowstyle hidden -file "C:\ProgramData\Scripts\RegisterCompanyPortal.ps1"</Arguments>
    </Exec>
  </Actions>
</Task>
'@

$xmlPath = "$env:TEMP\RegisterCompanyPortal.xml"
Set-Content -Path $xmlPath -Value $taskXml -Encoding Unicode -Force

schtasks.exe /create /xml $xmlPath /tn "RegisterCompanyPortal" /f | Out-Host
Write-Host "schtasks /create exit code: $LASTEXITCODE"

schtasks.exe /run /tn "RegisterCompanyPortal" | Out-Host
Write-Host "schtasks /run exit code: $LASTEXITCODE"

# Verify installation
$provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq "Microsoft.CompanyPortal" }
$installed = Get-AppxPackage -AllUsers -Name "Microsoft.CompanyPortal"

Write-Host "Provisioned: $($null -ne $provisioned)"
Write-Host "Installed for users: $($null -ne $installed)"

if ($provisioned -or $installed) {
    Write-Host "Installation complete."
    exit 0
} else {
    Write-Host "Installation failed - Company Portal not detected."
    exit 1
}
