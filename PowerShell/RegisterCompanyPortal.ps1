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
