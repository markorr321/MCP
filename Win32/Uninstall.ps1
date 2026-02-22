$ErrorActionPreference = "SilentlyContinue"

$packageName = "Microsoft.CompanyPortal"

# Remove provisioned package (prevents install for new users)
Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $packageName } | ForEach-Object {
    Write-Host "Removing provisioned package: $($_.PackageName)"
    Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName
}

# Remove installed package for all users
Get-AppxPackage -AllUsers -Name $packageName | ForEach-Object {
    Write-Host "Removing package for all users: $($_.PackageFullName)"
    Remove-AppxPackage -AllUsers -Package $_.PackageFullName
}

# Remove scheduled task
Unregister-ScheduledTask -TaskName "RegisterCompanyPortal" -Confirm:$false -ErrorAction SilentlyContinue

# Remove registration scripts
Remove-Item "C:\ProgramData\Scripts\RegisterCompanyPortal.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\ProgramData\Scripts\RegisterCompanyPortal.vbs" -Force -ErrorAction SilentlyContinue

# Remove staged appxbundle and dependencies
Remove-Item "C:\ProgramData\CompanyPortal" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Uninstall complete."
exit 0
