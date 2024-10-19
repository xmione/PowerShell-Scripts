# Define a function to simulate mouse scrolls
function Scroll-Mouse {
    param (
        [int]$ScrollAmount = 120,            # Amount to scroll (positive for up, negative for down)
        [int]$ScrollDurationInMilliseconds = 5000  # Duration to scroll in milliseconds
    )

    # Add .NET types for mouse scrolling
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;

    public class MouseHelper {
        [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
        public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, int dwExtraInfo);

        public const uint MOUSEEVENTF_WHEEL = 0x0800; // Scroll wheel event
    }
"@

    # Calculate the number of scrolls to perform based on duration
    $interval = 100  # Interval in milliseconds
    $iterations = [math]::Floor($ScrollDurationInMilliseconds / $interval)

    # Perform the scrolling in intervals
    for ($i = 0; $i -lt $iterations; $i++) {
        [MouseHelper]::mouse_event([MouseHelper]::MOUSEEVENTF_WHEEL, 0, 0, $ScrollAmount, 0)
        Start-Sleep -Milliseconds $interval
    }
}

# Define a function to simulate Alt+Tab key presses with a pause between Tab presses
function Switch-Window {
    param (
        [int]$TabCount = 1,                  # Number of Tab presses
        [int]$PauseBetweenTabs = 500         # Pause between Tab presses in milliseconds (default: 500ms)
    )

    # Add the required .NET types for key simulation
    Add-Type -TypeDefinition @"
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
            // Hold Alt down
            keybd_event(VK_MENU, 0, KEYEVENTF_KEYDOWN, 0);
            
            for (int i = 0; i < tabPresses; i++) {
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

    # Call the method to simulate Alt+Tab with a pause between each Tab press
    [KeyboardHelper]::AltTab($TabCount, $PauseBetweenTabs)
}

# Add .NET type for key detection
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class KeyListener {
    [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
    public static extern short GetAsyncKeyState(int keyCode);
    
    public const int VK_ESCAPE = 0x1B; // Escape key

    public static bool IsEscapePressed() {
        return GetAsyncKeyState(VK_ESCAPE) != 0;
    }
}
"@

# Loop to continuously switch windows and scroll
Write-Host "Press the Escape key to stop the window switching and scrolling."

while ($true) {
    # Switch to the third window
    Switch-Window -TabCount 3 -PauseBetweenTabs 1000
    
    # Check if the Escape key has been pressed
    if ([KeyListener]::IsEscapePressed()) {
        Write-Host "Escape key pressed. Stopping..."
        break
    }

    # Scroll up for 5 seconds
    Scroll-Mouse -ScrollAmount 120 -ScrollDurationInMilliseconds 5000

    # Check if the Escape key has been pressed
    if ([KeyListener]::IsEscapePressed()) {
        Write-Host "Escape key pressed. Stopping..."
        break
    }

    # Switch to the fourth window
    Switch-Window -TabCount 4 -PauseBetweenTabs 1000

    # Check if the Escape key has been pressed
    if ([KeyListener]::IsEscapePressed()) {
        Write-Host "Escape key pressed. Stopping..."
        break
    }

    # Scroll down for 5 seconds
    Scroll-Mouse -ScrollAmount -120 -ScrollDurationInMilliseconds 5000

    # Check if the Escape key has been pressed
    if ([KeyListener]::IsEscapePressed()) {
        Write-Host "Escape key pressed. Stopping..."
        break
    }

    # Sleep between cycles to reduce CPU load
    Start-Sleep -Milliseconds 500
}
