function Get-Credentials {
    param (
        [string]$PromptIP = "Enter the IP address:",
        [string]$PromptUsername = "Enter the username:",
        [string]$PromptPassword = "Enter the password:"
    )

    # Prompt for IP address
    $ipAddress = Read-Host -Prompt $PromptIP

    # Prompt for username
    $username = Read-Host -Prompt $PromptUsername

    # Prompt for password (masked input)
    $password = Read-Host -Prompt $PromptPassword -AsSecureString

    # Create a PSCredential object
    $credentials = New-Object System.Management.Automation.PSCredential ($username, $password)

    # Return the results as a custom object
    [PSCustomObject]@{
        IPAddress = $ipAddress
        Username  = $credentials.UserName
        Password  = $credentials.GetNetworkCredential().Password
    }
}

# Call the function
$creds = Get-Credentials

# Display the results (username and IP address)
Write-Output "IP Address: $($creds.IPAddress)"
Write-Output "Username: $($creds.Username)"
