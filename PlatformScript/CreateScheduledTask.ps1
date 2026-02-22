$logFile = "C:\Windows\TEMP\CreateScheduledTask.log"

# Deploy registration script and VBS launcher
$destination = "C:\ProgramData\Scripts"
if (!(Test-Path $destination)) {
    mkdir $destination
}

Start-Transcript -Path $logFile -Force

Write-Host "Script started at $(Get-Date)"
Write-Host "Running as: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)"
Write-Host "Architecture: $([IntPtr]::Size * 8)-bit"

$taskScript = @'
$pkg = Get-AppxPackage -Name "Microsoft.CompanyPortal" -ErrorAction SilentlyContinue
if (-not $pkg) {
    $stagingDir = "C:\ProgramData\CompanyPortal"
    $bundle = Get-ChildItem "$stagingDir\*.appxbundle" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($bundle) {
        $deps = Get-ChildItem "$stagingDir\*.appx" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
        if ($deps) {
            Add-AppxPackage -Path $bundle.FullName -DependencyPath $deps -ErrorAction SilentlyContinue
        } else {
            Add-AppxPackage -Path $bundle.FullName -ErrorAction SilentlyContinue
        }
    }
}
'@

Write-Host "Writing RegisterCompanyPortal.ps1..."
Set-Content -Path "$destination\RegisterCompanyPortal.ps1" -Value $taskScript -Force
Write-Host "RegisterCompanyPortal.ps1 exists: $(Test-Path "$destination\RegisterCompanyPortal.ps1")"

# VBScript launcher to run PowerShell silently (no CMD popup)
$vbsScript = @'
CreateObject("WScript.Shell").Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\ProgramData\Scripts\RegisterCompanyPortal.ps1""", 0, False
'@

Write-Host "Writing RegisterCompanyPortal.vbs..."
Set-Content -Path "$destination\RegisterCompanyPortal.vbs" -Value $vbsScript -Force
Write-Host "RegisterCompanyPortal.vbs exists: $(Test-Path "$destination\RegisterCompanyPortal.vbs")"

# Create scheduled task
Write-Host "Creating scheduled task..."
$taskName = "RegisterCompanyPortal"

$taskAction = New-ScheduledTaskAction -Execute "C:\ProgramData\Scripts\RegisterCompanyPortal.vbs"
$taskTrigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" -RunLevel Limited
$task = New-ScheduledTask -Action $taskAction -Trigger $taskTrigger -Principal $principal -Description "Register Company Portal for the current user at logon"
Register-ScheduledTask -TaskName $taskName -InputObject $task -Force

# Verify task creation
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "Scheduled task created successfully. State: $($task.State)"
} else {
    Write-Host "ERROR: Scheduled task was NOT created"
}

Write-Host "Script completed at $(Get-Date)"
Stop-Transcript
