<#
.SYNOPSIS
    Downloads and installs the Company Portal app and dependencies from a GitHub release.

.DESCRIPTION
    Designed to run as an Intune Platform Script (SYSTEM context).
    - Fetches the latest release from a GitHub repository
    - Downloads the .appxbundle, license XML, and architecture-matched dependencies
    - Provisions Company Portal so it is available for all users at next login

.NOTES
    Configure the $GitHubRepo variable below before deploying.
    Upload all package files (bundle, license, dependencies) as assets on a GitHub release.
#>

#region ── Configuration ──────────────────────────────────────────────────────────
# Set to your GitHub repository in "owner/repo" format
$GitHubRepo = "YOURORG/Company-Portal-Win32"

# Log file location (writable by SYSTEM)
$LogPath = "C:\ProgramData\CompanyPortalInstall.log"
#endregion ────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"
Start-Transcript -Path $LogPath -Force

try {
    # ── Ensure TLS 1.2 for GitHub API ────────────────────────────────────────
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # ── Determine architecture ───────────────────────────────────────────────
    $arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    Write-Host "Detected architecture: $arch"

    # ── Query GitHub for latest release ──────────────────────────────────────
    $apiUrl = "https://api.github.com/repos/$GitHubRepo/releases/latest"
    Write-Host "Fetching latest release from: $apiUrl"

    $releaseInfo = Invoke-RestMethod -Uri $apiUrl -Headers @{
        "Accept"     = "application/vnd.github+json"
        "User-Agent" = "CompanyPortal-Installer"
    }

    Write-Host "Latest release: $($releaseInfo.tag_name) - $($releaseInfo.name)"
    $assets = $releaseInfo.assets

    if (-not $assets -or $assets.Count -eq 0) {
        throw "No assets found in the latest release."
    }

    Write-Host "Found $($assets.Count) release asset(s)."

    # ── Create temp working directory ────────────────────────────────────────
    $workDir = Join-Path $env:TEMP "CompanyPortalInstall_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -Path $workDir -ItemType Directory -Force | Out-Null
    Write-Host "Working directory: $workDir"

    # ── Helper: download a release asset ─────────────────────────────────────
    function Get-ReleaseAsset {
        param (
            [string]$DownloadUrl,
            [string]$FileName
        )
        $outPath = Join-Path $workDir $FileName
        Write-Host "  Downloading: $FileName"
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $outPath -UseBasicParsing
        return $outPath
    }

    # ── Identify and download assets ─────────────────────────────────────────

    # 1. Company Portal bundle (.appxbundle)
    $bundleAsset = $assets | Where-Object { $_.name -like "*.appxbundle" } | Select-Object -First 1
    if (-not $bundleAsset) { throw "No .appxbundle found in release assets." }
    $bundlePath = Get-ReleaseAsset -DownloadUrl $bundleAsset.browser_download_url -FileName $bundleAsset.name

    # 2. License XML
    $licenseAsset = $assets | Where-Object { $_.name -like "*License*.xml" } | Select-Object -First 1
    if (-not $licenseAsset) { throw "No license XML found in release assets." }
    $licensePath = Get-ReleaseAsset -DownloadUrl $licenseAsset.browser_download_url -FileName $licenseAsset.name

    # 3. Dependencies - download only the ones matching the detected architecture
    $depPatterns = @(
        "Microsoft.VCLibs.140.00_*_${arch}__*.appx",
        "Microsoft.NET.Native.Framework*_${arch}__*.appx",
        "Microsoft.NET.Native.Runtime*_${arch}__*.appx",
        "Microsoft.UI.Xaml*_${arch}__*.appx",
        "Microsoft.Services.Store.Engagement*_${arch}__*.appx"
    )

    $depPaths = @()
    foreach ($pattern in $depPatterns) {
        $match = $assets | Where-Object { $_.name -like $pattern } | Select-Object -First 1
        if ($match) {
            $depPaths += Get-ReleaseAsset -DownloadUrl $match.browser_download_url -FileName $match.name
        } else {
            Write-Warning "No asset matched pattern: $pattern"
        }
    }

    Write-Host ""
    Write-Host "Bundle : $($bundleAsset.name)"
    Write-Host "License: $($licenseAsset.name)"
    Write-Host "Dependencies downloaded: $($depPaths.Count)"

    # ── Install Company Portal (provisioned for all users) ───────────────────
    Write-Host ""
    Write-Host "Installing Company Portal with dependencies..."

    $installParams = @{
        Online               = $true
        PackagePath          = $bundlePath
        LicensePath          = $licensePath
    }

    if ($depPaths.Count -gt 0) {
        $installParams["DependencyPackagePath"] = $depPaths
    }

    Add-AppxProvisionedPackage @installParams | Out-Null

    # ── Verify installation ──────────────────────────────────────────────────
    $provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq "Microsoft.CompanyPortal" }
    $installed   = Get-AppxPackage -AllUsers -Name "Microsoft.CompanyPortal"

    Write-Host "Provisioned: $($null -ne $provisioned)"
    Write-Host "Installed for users: $($null -ne $installed)"

    if (-not $provisioned -and -not $installed) {
        throw "Installation verification failed - Company Portal not detected after install."
    }

    Write-Host ""
    Write-Host "Company Portal installation complete."
    $exitCode = 0

} catch {
    Write-Error "Installation failed: $_"
    $exitCode = 1

} finally {
    # ── Cleanup temp files ───────────────────────────────────────────────────
    if ($workDir -and (Test-Path $workDir)) {
        Write-Host "Cleaning up: $workDir"
        Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Stop-Transcript
}

exit $exitCode
