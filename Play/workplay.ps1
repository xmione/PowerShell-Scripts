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
    public static void AltTab(int tabPresses, int pauseBetweenTabs) {
        Console.WriteLine("Performing Alt+Tab {0} times with a pause of {1}ms.", tabPresses, pauseBetweenTabs);

        // Hold Alt down
        keybd_event(VK_MENU, 0, KEYEVENTF_KEYDOWN, 0);
        
        for (int i = 0; i < tabPresses; i++) {
            Console.WriteLine("Performing Alt+Tab {0} time/s.", i);

            // Press Tab
            keybd_event(VK_TAB, 0, KEYEVENTF_KEYDOWN, 0);
            keybd_event(VK_TAB, 0, KEYEVENTF_KEYUP, 0);
            // Pause before pressing Tab again
            System.Threading.Thread.Sleep(pauseBetweenTabs);
        }
        // Release Alt
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
# Add the types
$mouseAdded = Add-TypeIfNotExists -typeName "MouseHelper" -typeDefinition $mouseHelperDefinition
$keyboardAdded = Add-TypeIfNotExists -typeName "KeyboardHelper" -typeDefinition $keyboardHelperDefinition
$keyListenerAdded = Add-TypeIfNotExists -typeName "KeyListener" -typeDefinition $keyListenerDefinition

# Log the results
Write-Host "MouseHelper added: $mouseAdded"
Write-Host "KeyboardHelper added: $keyboardAdded"
Write-Host "KeyListener added: $keyListenerAdded"


# Define a function to simulate mouse scrolls
function Scroll-Mouse {
    param (
        [string]$Direction = "Up",
        [int]$ScrollAmount = 120,
        [int]$ScrollDurationInMilliseconds = 5000
    )
    # Keep scroll amount positive and adjust the scroll direction
    $scrollAmountAdjusted = if ($Direction -eq "Down") { -$ScrollAmount } else { $ScrollAmount }
    $interval = 100
    $iterations = [math]::Floor($ScrollDurationInMilliseconds / $interval)
    for ($i = 0; $i -lt $iterations; $i++) {
        [MouseHelper]::mouse_event([MouseHelper]::MOUSEEVENTF_WHEEL, 0, 0, [Math]::Abs($scrollAmountAdjusted), 0)
        Start-Sleep -Milliseconds $interval
    }
}

# Example function to press arrow keys
function Press-ArrowKey {
    param (
        [string]$Direction,
        [int]$DurationInMilliseconds = 5000
    )
    $key = if ($Direction -eq "Left") { [KeyboardHelper]::VK_LEFT } else { [KeyboardHelper]::VK_RIGHT }
    [KeyboardHelper]::PressKey($key, $DurationInMilliseconds)
}

# Function to simulate Alt+Tab key presses
function Switch-Window {
    param (
        [int]$TabCount = 1,
        [int]$PauseBetweenTabs = 500
    )
    
    Write-Host "Switching window..."
    [KeyboardHelper]::AltTab($TabCount, $PauseBetweenTabs)
}

# Function to check for escape key press
function Check-Escape {
    return [KeyListener]::IsEscapePressed()
}

# Function to execute commands from proc.txt
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
        'MUP-*' {
            $parts = $Command -split '-'
            $amount = [int]$parts[1]
            $duration = [int]$parts[2]
            Scroll-Mouse -Direction 'Up' -ScrollAmount $amount -ScrollDurationInMilliseconds $duration
        }
        'MDOWN-*' {
            $parts = $Command -split '-'
            $amount = [int]$parts[1]
            $duration = [int]$parts[2]
            Scroll-Mouse -Direction 'Down' -ScrollAmount $amount -ScrollDurationInMilliseconds $duration
        }
        'Left-*' {
            $duration = [int]($Command -replace 'Left-', '')
            Press-ArrowKey -Direction 'Left' -DurationInMilliseconds $duration
        }
        'Right-*' {
            $duration = [int]($Command -replace 'Right-', '')
            Press-ArrowKey -Direction 'Right' -DurationInMilliseconds $duration
        }
        default { Write-Host "Unknown command: $Command" }
    }
}

# Main loop to continuously execute commands from proc.txt
Write-Host "Press the Escape key to stop the command execution."
$scriptRoot = $PSScriptRoot
$procListFile = "$scriptRoot\proc.txt"
while ($true) {
    # Read commands from proc.txt
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
