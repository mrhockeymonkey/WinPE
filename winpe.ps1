<#

    Author  : Scott Matthews
    Purpose : To automate creation of a custom WinPE Image
    Requires: Windows ADK (https://go.microsoft.com/fwlink/p/?LinkId=526740)

#>

[CmdletBinding()]
Param ()

#Variables
$AdkPath = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64'
$OptionalComponents = @(
    #Powershell Components
    "$AdkPath\WinPE_OCs\en-us\WinPE-WMI.cab"
    "$AdkPath\WinPE_OCs\en-us\WinPE-WMI_en-us.cab"
    "$AdkPath\WinPE_OCs\en-us\WinPE-NetFX.cab"
    "$AdkPath\WinPE_OCs\en-us\WinPE-NetFX_en-us.cab"
    "$AdkPath\WinPE_OCs\en-us\WinPE-Scripting.cab"
    "$AdkPath\WinPE_OCs\en-us\WinPE-Scripting_en-us.cab"
    "$AdkPath\WinPE_OCs\en-us\WinPE-PowerShell.cab"
    "$AdkPath\WinPE_OCs\en-us\WinPE-PowerShell_en-us.cab"
    "$AdkPath\WinPE_OCs\en-us\WinPE-StorageWMI.cab"
    "$AdkPath\WinPE_OCs\en-us\WinPE-StorageWMI_en-us.cab"
    "$AdkPath\WinPE_OCs\en-us\WinPE-DismCmdlets.cab"
    "$AdkPath\WinPE_OCs\en-us\WinPE-DismCmdlets_en-us.cab"
    #ADSI Components
    "$AdkPath\WinPE_OCs\en-us\WinPE-WinPE-HTA.cab"
    "$AdkPath\WinPE_OCs\en-us\WinPE-WinPE-HTA_en-us.cab"
    "$AdkPath\WinPE_OCs\en-us\WinPE-WinPE-MDAC_en-us.cab"
    "$AdkPath\WinPE_OCs\en-us\WinPE-WinPE-MDAC_en-us.cab"
)

#Check for Windos ADK
Test-Path -Path $AdkPath

#Copy a fresh copy of winpe.wim
Write-Host "Copying fresh WinPE Image..." -ForegroundColor Yellow
Copy-Item -Path "$AdkPath\..." -Destination ".\winpe.wim" -Force -Verbose -ErrorAction Stop

#Mount WinPE Image using DISM
Write-Host "Mounting Image..." -ForegroundColor Yellow
& dism.exe /Mount-Image /ImageFile:.\winpe.wim /Index:1 /MountDir:.\mount

#Add optional components
Write-Host "Adding optional components..." -ForegroundColor Yellow
$OptionalComponents | ForEach-Object {
    & dism.exe /Add-Package /Image:.\mount /PackagePath:$_
}

#Inject Drivers
Get-ChildItem -Path .\driver -Directory | ForEach-Object {
    Write-Host "Injecting $($_.Name) drivers..." -ForegroundColor Yellow
    & dism.exe /Add-Driver /Image:.\mount /Driver:$($_.FullName) /Recurse /ForceUnsigned
}

#Copy Custom Scripts 

#Unmount WinPE 
Write-Host "Unmounting Image..." -ForegroundColor Yellow
& dism.exe /Unmount-Image /MountDir:.\mount /Commit
#& dism.exe /Unmount-Image /MountDir:.\mount /Discard