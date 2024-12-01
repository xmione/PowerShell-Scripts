# .\Print-Folder-Structure
Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force
$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path
Write-Output "Removing modules..."
Write-Output "Removing module Print-Folder-Structure"
Remove-Module Print-Folder-Structure
Write-Output "Importing modules..."
Write-Output "Importing module Print-Folder-Structure"
Import-Module $ScriptDir\Print-Folder-Structure.psm1
