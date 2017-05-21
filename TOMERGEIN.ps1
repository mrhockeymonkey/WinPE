<#
    This script will generate a new WinPE Image from scratch allowing you to version control
    Requirments: 
       Windows ADK 8.1 installed
       You should run this script from a directory with the following structure or simillar (Adjust to suit needs)

    D:\WinPE
    |_ driver
    |  |_ HP
    |     |_ *.inf
    |  |_ Dell
    |     |_ *.inf
    |_ mount
    |_ scripts
       |_ startnet.cmd
#>

$WorkingDir = "D:\WinPE\"
$WinPEDir = 'C:\Program Files (x86)\Windows Kits\8.1\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64'


#Copy a fresh winpe.wim file over
Write-Host "Copying Fresh WinPE.wim..." -ForegroundColor Yellow
Copy-Item -Path "$WinPEDir\en-us\winpe.wim" `
          -Destination $WorkingDir `
          -Force

#Mount WinPE file
Write-Host "`nMounting Image..." -ForegroundColor Yellow
& dism.exe /Mount-Image /ImageFile:$WorkingDir\winpe.wim /Index:1 /MountDir:$WorkingDir\mount

#Add Optional Components for Powershell
Write-Host "`nInstalling Powershell..." -ForegroundColor Yellow
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\WinPE-WMI.cab"
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\en-us\WinPE-WMI_en-us.cab"
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\WinPE-NetFX.cab"
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\en-us\WinPE-NetFX_en-us.cab"
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\WinPE-Scripting.cab"
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\en-us\WinPE-Scripting_en-us.cab"
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\WinPE-PowerShell.cab"
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\en-us\WinPE-PowerShell_en-us.cab"
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\WinPE-StorageWMI.cab"
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\en-us\WinPE-StorageWMI_en-us.cab"
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\WinPE-DismCmdlets.cab"
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\en-us\WinPE-DismCmdlets_en-us.cab"

& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\WinPE-HTA.cab"
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\en-us\WinPE-MDAC_en-us.cab"
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\WinPE-MDAC.cab"
& Dism /Add-Package /Image:"$WorkingDir\mount" /PackagePath:"$WinPEDir\WinPE_OCs\en-us\WinPE-HTA_en-us.cab"

#Edit Localisation info for UK
Write-Host "Setitng Timezone and Keyboard to UK..." -ForegroundColor Yellow
& Dism /image:$WorkingDir\mount /Set-SysLocale:en-GB
& Dism /image:$WorkingDir\mount /Set-UserLocale:en-GB
& Dism /image:$WorkingDir\mount /Set-InputLocale:0809:00000809
& Dism /image:$WorkingDir\mount /Set-TimeZone:"GMT Standard Time"

#Inject drivers into the the winpe image
$DriverFolders = gci "$WorkingDir\driver"
$DriverFolders | ForEach-Object {
    Write-Host "`nInjecting $($_.Name) Drivers..." -ForegroundColor Yellow
    & Dism /Image:"$WorkingDir\mount" /Add-Driver /Driver:"$($_.FullName)" /Recurse /ForceUnsigned 
}

#Copy Scripts...
Write-Host "`nCopying Custom Scripts..." -ForegroundColor Yellow
Copy-Item -Path "$WorkingDir\scripts\startnet.cmd" -Destination "$WorkingDir\mount\Windows\System32\startnet.cmd" -Force
New-Item -ItemType Directory "$WorkingDir\mount\Scripts" -Force
Copy-Item -Path "$WorkingDir\scripts\CustomPowershellScript.ps1" -Destination "$WorkingDir\mount\Scripts\CustomPowershellScript.ps1"


#Unmount WinPE File
Write-Host "`nUnmounting Image..." -ForegroundColor Yellow
& Dism /Unmount-image /MountDir:$WorkingDir\mount /Commit
#& Dism /Unmount-image /MountDir:$WorkingDir\mount /discard

