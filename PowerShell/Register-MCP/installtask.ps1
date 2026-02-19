$destination = "C:\ProgramData\Scripts"
if(!(Test-Path $Destination))
{
    mkdir $Destination
}

Copy-Item -Path "$($psscriptroot)\RegisterCompanyPortal.ps1" -Destination $Destination -Recurse -Force

schtasks.exe /create /xml "$($psscriptroot)\RegisterCompanyPortal.xml" /tn "RegisterCompanyPortal" /f | Out-Host