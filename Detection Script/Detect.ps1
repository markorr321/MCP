$packageName = "Microsoft.CompanyPortal"
$stagingDir = "C:\ProgramData\CompanyPortal"

# Check provisioned (proves our Install.ps1 ran - Store installs don't provision)
$provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $packageName }

# Check staging folder exists (unique to our Win32 installation)
$staged = Test-Path $stagingDir

# Also check if installed for users
$installed = Get-AppxPackage -AllUsers -Name $packageName

# Require BOTH provisioned AND staged to confirm our Win32 app ran
# This prevents false positives from Store-installed versions
if ($provisioned -and $staged) {
    Write-Host "Company Portal Win32 detected. Provisioned: True, Staged: True, Installed: $($null -ne $installed)"
    exit 0
} else {
    Write-Host "Company Portal Win32 NOT detected. Provisioned: $($null -ne $provisioned), Staged: $staged"
    exit 1
}
