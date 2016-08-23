<#

    Author  : Scott Matthews
    Purpose : To automate creation of a custom WinPE Images
    Requires: Windows ADK (https://go.microsoft.com/fwlink/p/?LinkId=526740)
    Notes   : Logs can be found at C:\Windows\Logs\DISM

#>

[CmdletBinding()]
Param ()

#Variables
$WinPePath          = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64'
$ToolsPath          = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64'

$OptionalComponents = @(
    #Powershell Components
    "$WinPePath\WinPE_OCs\WinPE-WMI.cab"
    "$WinPePath\WinPE_OCs\en-us\WinPE-WMI_en-us.cab"

    "$WinPePath\WinPE_OCs\WinPE-NetFX.cab"
    "$WinPePath\WinPE_OCs\en-us\WinPE-NetFX_en-us.cab"
    
    "$WinPePath\WinPE_OCs\WinPE-Scripting.cab"
    "$WinPePath\WinPE_OCs\en-us\WinPE-Scripting_en-us.cab"
    
    "$WinPePath\WinPE_OCs\WinPE-PowerShell.cab"
    "$WinPePath\WinPE_OCs\en-us\WinPE-PowerShell_en-us.cab"
    
    "$WinPePath\WinPE_OCs\WinPE-StorageWMI.cab"
    "$WinPePath\WinPE_OCs\en-us\WinPE-StorageWMI_en-us.cab"
    
    "$WinPePath\WinPE_OCs\WinPE-DismCmdlets.cab"
    "$WinPePath\WinPE_OCs\en-us\WinPE-DismCmdlets_en-us.cab"
    
    #ADSI Components
    "$WinPePath\WinPE_OCs\WinPE-HTA.cab"
    "$WinPePath\WinPE_OCs\en-us\WinPE-HTA_en-us.cab"
    
    "$WinPePath\WinPE_OCs\WinPE-MDAC.cab"
    "$WinPePath\WinPE_OCs\en-us\WinPE-MDAC_en-us.cab"

)

#Check for Windos ADK
If (-not (Test-Path -Path $WinPePath)){
    Write-Error "Cannot find Windows $WinPePath, You can download the ADK from 'https://go.microsoft.com/fwlink/p/?LinkId=526740'" -ErrorAction Stop
}
If (-not (Test-Path -Path $ToolsPath)){
    Write-Error "Cannot find Windows $ToolsPath, You can download the ADK from 'https://go.microsoft.com/fwlink/p/?LinkId=526740'" -ErrorAction Stop
}
If ([Environment]::OSVersion.Version -lt [Version]::Parse('10.0.14393.0') ) {
    Write-Error "OS Version must be at least 10.0.14393.0!" -ErrorAction Stop
}


Try {
    #Import DISM PowerShell Module
    Import-Module "$ToolsPath\DISM" -ErrorAction Stop
    Push-Location $PSScriptRoot

    #Copy a fresh copy of winpe.wim
    Write-Host "Copying fresh WinPE Image..." -ForegroundColor Yellow
    Copy-Item -Path "$WinPePath\en-Us\winpe.wim" -Destination ".\winpe.wim" -Force -Verbose -ErrorAction Stop

    #Mount
    Write-Host "Mounting Image..." -ForegroundColor Yellow
    Mount-WindowsImage -Path ".\mount" -ImagePath ".\winpe.wim" -Index 1 -Verbose -ErrorAction Stop
    #& dism.exe /Mount-Image /ImageFile:.\winpe.wim /MountDir:.\mount /Index:1

    #Add optional components
    Write-Host "Adding optional components..." -ForegroundColor Yellow
    $OptionalComponents | ForEach-Object {    
        Add-WindowsPackage -Path ".\mount" -PackagePath $_ -Verbose | Out-Null
        #& dism.exe /Add-Package /Image:.\mount /PackagePath:$_
    }

    #Inject Drivers
    Get-ChildItem -Path .\driver -Directory | ForEach-Object {
        Write-Host "Injecting $($_.Name) drivers..." -ForegroundColor Yellow
        #& dism.exe /Add-Driver /Image:.\mount /Driver:$($_.FullName) /Recurse /ForceUnsigned
        Add-WindowsDriver -Path ".\mount" -Driver $_.FullName -Recurse -ForceUnsigned
    }

    #Copy Custom Scripts
    Write-Host "Copying Custom Scripts..." -ForegroundColor Yellow
    Copy-Item -Path ".\scripts" -Destination ".\mount" -Recurse -Force -ErrorAction Stop -Verbose

    #Copy Start startnet.cmd
    Write-Host "Copying startnet.cmd..."-ForegroundColor Yellow
    Copy-Item -Path ".\startnet.cmd" -Destination ".\mount\windows\system32\startnet.cmd" -Force -ErrorAction Stop -Verbose

    #Unmount
    Write-Host "Unmounting Image..." -ForegroundColor Yellow
    #Dismount-WindowsImage -Path ".\mount" -Discard -Verbose -ErrorAction Stop
    Dismount-WindowsImage -Path ".\mount" -Save -Verbose -ErrorAction Stop
    #& dism.exe /Unmount-Image /MountDir:.\mount /Discard

}
Catch {
    $PSCmdlet.ThrowTerminatingError($_)
}
Finally {
    Pop-Location
}

