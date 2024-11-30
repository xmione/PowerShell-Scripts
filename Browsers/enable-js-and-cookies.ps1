<##======================================================================================================================================================================================
File Name : enablejsandcookies.ps1
Created By: Solomio S. Sisante
Created On: November 29, 2024
Created To: Enable Chrome and Edge browsers JavaScript and Cookiess
How to Use: 
            Start-Process "powershell.exe" -ArgumentList "-NoExit", "-ExecutionPolicy Bypass", "-Command", "Set-Location -Path $($PWD.Path); .\enable-js-and-cookies.ps1" -Verb RunAs
#======================================================================================================================================================================================#>
function Enable-JSAndCookies {
    # Enable JavaScript and Cookies in Chrome
    $chromeRegPath = "HKCU:\Software\Policies\Google\Chrome"
    if (-not (Test-Path $chromeRegPath)) {
        New-Item -Path $chromeRegPath -Force
    }
    Set-ItemProperty -Path $chromeRegPath -Name "JavaScriptEnabled" -Value 1
    Set-ItemProperty -Path $chromeRegPath -Name "CookiesEnabled" -Value 1

    Write-Host "JavaScript and cookies enabled in Google Chrome."

    # Enable JavaScript and Cookies in Edge
    $edgeRegPath = "HKCU:\Software\Policies\Microsoft\Edge"
    if (-not (Test-Path $edgeRegPath)) {
        New-Item -Path $edgeRegPath -Force
    }
    Set-ItemProperty -Path $edgeRegPath -Name "JavaScriptEnabled" -Value 1
    Set-ItemProperty -Path $edgeRegPath -Name "CookiesEnabled" -Value 1

    Write-Host "JavaScript and cookies enabled in Microsoft Edge."
}

# Call the function
Enable-JSAndCookies
