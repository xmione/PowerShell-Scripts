<#
    Author  : Solomio S. Sisante
    Creatod : October 19, 2024
    FileName: ipset.ps1
    Purpose : To import modules from ipset.psm1

    Note    : There is a batch file import-ipset.bat that you can right click and run as admin from the Windows Explorer to run this script.

    .\ipset.ps1

#>

# Get the current script root directory
$scriptRoot = $PSScriptRoot
$scriptFileFullPath = "$scriptRoot\ipset.psm1"
$moduleName = [System.IO.Path]::GetFileNameWithoutExtension($scriptFileFullPath)

# Check if the module is loaded
if (Get-Module -Name $moduleName) {
    Write-Host "Removing module: $moduleName"
    try {
        Remove-Module -Name $moduleName -Force
    } catch {
        Write-Host "Failed to remove module: $moduleName - $_"
    }
} else {
    Write-Host "Module $moduleName is not loaded."
}

# Optional: Confirm the module has been removed
Write-Host "============================================================"
Write-Host "Modules after removal:"
Get-Module

# Import the specified module
Write-Host "Importing module from $scriptFileFullPath"
Import-Module -Name $scriptFileFullPath

Write-Host "============================================================"
Write-Host "Modules after importing:"
Get-Module