$destination = "C:\ProgramData\Scripts"
if (!(Test-Path $destination)) {
    mkdir $destination
}

$scriptText = @'
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
'@

New-Item -ItemType File -Path $destination -Name "RegisterCompanyPortal.ps1" -Force
$scriptText | Set-Content -Path "$destination\RegisterCompanyPortal.ps1" -Force

$taskName = "RegisterCompanyPortal"
$scriptPath = "C:\ProgramData\Scripts\RegisterCompanyPortal.ps1"

$taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
$taskTrigger = New-ScheduledTaskTrigger -AtLogOn
$taskPrincipal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users" -RunLevel Limited

Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal -Description "Register Company Portal for the current user at logon"
