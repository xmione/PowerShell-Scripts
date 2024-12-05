<#
    Author  : Solomio S. Sisante
    Created : December 5, 2024
    FileName: logoff-user.ps1
    Purpose : To logoff a user

    Note    : You have to enable PS Remoting first by running this command:
                Enable-PSRemoting -Force

    Troubleshooting: If you encounter an error, you need to check if your host machine is in private mode only.
                        $networkName = (Get-NetConnectionProfile).Name

                      If it is public, set it to private by running this:
                        Set-NetConnectionProfile -Name $networkName -NetworkCategory Private

                      Then run this again:
                        Enable-PSRemoting -Force

    To run  :            
                .\logoff-user.ps1 -VMName "Windows 11 dev environment"
#>

param (
    [string] $VMName
)

Clear-Host

# Get credentials once
$cred = Get-Credential

Write-Host "Credentials: $cred"
# Enter-PSSession with the provided credentials
Enter-PSSession -VMName $VMName -Credential $cred
