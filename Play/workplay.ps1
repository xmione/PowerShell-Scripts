# Stop script on any error
$ErrorActionPreference = "Stop"

# Function to add a type only if it does not already exist
function Add-TypeIfNotExists {
    param (
        [string]$typeName,
        [string]$typeDefinition
    )
    # Check if the type already exists in the current context
    if (-not [Type]::GetType($typeName, $false)) {
        try {
            Add-Type -TypeDefinition $typeDefinition -ErrorAction Stop
            Write-Host "Type $typeName added successfully."
        } catch {
            Write-Host "Could not add type ${typeName}: $($_.Exception.Message)" -ForegroundColor Red
            throw # Rethrow the error to stop the script
        }
    } else {
        Write-Host "Type $typeName already exists."
    }
}

# Define MouseHelper type definition
$mouseHelperDefinition = @"
using System;
using System.Runtime.InteropServices;
public class MouseHelper {
    [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, int dwExtraInfo);
    public const uint MOUSEEVENTF_WHEEL = 0x0800;
}
"@

# Define KeyboardHelper type definition
$keyboardHelperDefinition = @"
using System;
using System.Runtime.InteropServices;
public class KeyboardHelper {
    [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
    public static extern short GetKeyState(int keyCode);
        
    [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
    public static extern void keybd_event(byte virtualKey, byte scanCode, int flags, int extraInfo);
        
    public const int KEYEVENTF_KEYDOWN = 0x0000;
    public const int KEYEVENTF_KEYUP = 0x0002;
    public const byte VK_MENU = 0x12; // Alt key
    public const byte VK_TAB = 0x09;  // Tab key
    public static void PressKey(byte virtualKey, int duration) {
        keybd_event(virtualKey, 0, KEYEVENTF_KEYDOWN, 0);
        System.Threading.Thread.Sleep(duration);
        keybd_event(virtualKey, 0, KEYEVENTF_KEYUP, 0);
    }
    public static void AltTab(int tabPresses, int pauseBetweenTabs) {
        keybd_event(VK_MENU, 0, KEYEVENTF_KEYDOWN, 0);
        for (int i = 0; i < tabPresses; i++) {
            keybd_event(VK_TAB, 0, KEYEVENTF_KEYDOWN, 0);
            keybd_event(VK_TAB, 0, KEYEVENTF_KEYUP, 0);
            System.Threading.Thread.Sleep(pauseBetweenTabs);
        }
        keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0);
    }
}
"@

# Add .NET type for key detection
$keyListenerDefinition =  @"
using System;
using System.Runtime.InteropServices;
public class KeyListener {
    [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
    public static extern short GetAsyncKeyState(int keyCode);
    public const int VK_ESCAPE = 0x1B;
    public static bool IsEscapePressed() {
        return GetAsyncKeyState(VK_ESCAPE) != 0;
    }
    public static bool IsKeyPressed(int keyCode) {
        return GetAsyncKeyState(keyCode) != 0;
    }
}
"@

# Add the types
Add-TypeIfNotExists -typeName "MouseHelper" -typeDefinition $mouseHelperDefinition
Add-TypeIfNotExists -typeName "KeyboardHelper" -typeDefinition $keyboardHelperDefinition
Add-TypeIfNotExists -typeName "KeyListener" -typeDefinition $keyListenerDefinition

# Log the results
Write-Host "Types added or already exist."

function Scroll-Mouse {
    param (
        [string]$Direction = "UP",
        [int]$ScrollAmount = 120,
        [int]$ScrollDurationInMilliseconds = 5000
    )
    $scrollAmountAdjusted = if ($Direction -eq "DOWN") { -$ScrollAmount } else { $ScrollAmount }
    Write-Host "Scrolling: $Direction At: $scrollAmountAdjusted for $ScrollDurationInMilliseconds"
    $interval = 100
    $iterations = [math]::Floor($ScrollDurationInMilliseconds / $interval)
    for ($i = 0; $i -lt $iterations; $i++) {
        $scrollValue = if ($scrollAmountAdjusted -lt 0) {
            [uint32]$scrollAmountAdjusted + [uint32][Math]::Pow(2, 32)
        } else {
            [uint32]$scrollAmountAdjusted
        }
        [MouseHelper]::mouse_event([MouseHelper]::MOUSEEVENTF_WHEEL, 0, 0, $scrollValue, 0)
        Start-Sleep -Milliseconds $interval
    }
}

# Test it for real:
Scroll-Mouse -Direction "DOWN" -ScrollAmount 120 -ScrollDurationInMilliseconds 5000


function Press-ArrowKey {
    param (
        [string]$Direction,
        [int]$DurationInMilliseconds = 5000
    )
    Write-Host "Arrow: $Direction"
    $key = if ($Direction -eq "LEFT") { [KeyboardHelper]::VK_LEFT } else { [KeyboardHelper]::VK_RIGHT }
    [KeyboardHelper]::PressKey($key, $DurationInMilliseconds)
}

function Switch-Window {
    param (
        [int]$TabCount = 1,
        [int]$PauseBetweenTabs = 500
    )
    Write-Host "Switching window..."
    [KeyboardHelper]::AltTab($TabCount, $PauseBetweenTabs)
}

function Check-Escape {
    return [KeyListener]::IsEscapePressed()
}

function Execute-Command {
    param (
        [string]$Command
    )
    switch -Wildcard ($Command) {
        'SW-*' {
            $parts = $Command -split '-'
            $tabCount = [int]$parts[1]
            $pauseBetweenTabs = [int]$parts[2]
            Switch-Window -TabCount $tabCount -PauseBetweenTabs $pauseBetweenTabs
        }
        'S-*' {
            $duration = [int]($Command -replace 'S-', '')
            Start-Sleep -Seconds $duration
        }
        'SUP-*' {
            $parts = $Command -split '-'
            $amount = [int]$parts[1]
            $duration = [int]$parts[2]
            Scroll-Mouse -Direction 'UP' -ScrollAmount $amount -ScrollDurationInMilliseconds $duration
        }
        'SDOWN-*' {
            $parts = $Command -split '-'
            $amount = [int]$parts[1]
            $duration = [int]$parts[2]
            Scroll-Mouse -Direction 'DOWN' -ScrollAmount $amount -ScrollDurationInMilliseconds $duration
        }
        'LEFT-*' {
            $duration = [int]($Command -replace 'LEFT-', '')
            Press-ArrowKey -Direction 'LEFT' -DurationInMilliseconds $duration
        }
        'RIGHT-*' {
            $duration = [int]($Command -replace 'RIGHT-', '')
            Press-ArrowKey -Direction 'RIGHT' -DurationInMilliseconds $duration
        }
        default { Write-Host "Unknown command: $Command" }
    }
}

Write-Host "Press the Escape key to stop the command execution."
$scriptRoot = $PSScriptRoot
$procListFile = "$scriptRoot\proc.txt"

while ($true) {
    if (Test-Path $procListFile) {
        $commands = Get-Content $procListFile
        foreach ($command in $commands) {
            Execute-Command -Command $command.Trim()
            if (Check-Escape) {
                Write-Host "Execution stopped by Escape key."
                break
            }
        }
    }
    if (Check-Escape) {
        Write-Host "Execution stopped by Escape key."
        break
    }
}
Write-Host "Execution finished."
