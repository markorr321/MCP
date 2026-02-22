$packageName = "Microsoft.CompanyPortal"

# Check provisioned (for new users) OR installed (for existing users, even if auto-updated)
$provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $packageName }
$installed = Get-AppxPackage -AllUsers -Name $packageName

if ($provisioned -or $installed) {
    Write-Host "Company Portal detected. Provisioned: $($null -ne $provisioned), Installed: $($null -ne $installed)"
    exit 0
} else {
    exit 1
}
