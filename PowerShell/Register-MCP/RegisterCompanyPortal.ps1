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
