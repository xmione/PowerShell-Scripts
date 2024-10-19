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
using System.Threading;

public class KeyListener {
    [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
    public static extern short GetAsyncKeyState(int keyCode);
    
    public const int VK_ESCAPE = 0x1B; // Escape key

    public static bool IsEscapePressed() {
        return GetAsyncKeyState(VK_ESCAPE) != 0;
    }
}
"@

# Loop to continuously switch windows
Write-Host "Press the Escape key to stop the window switching."

while ($true) {
    # Switch to the third window with a 1-second pause between Tab presses
    Switch-Window -TabCount 3 -PauseBetweenTabs 1000
    
    # Switch to the fourth window
    Switch-Window -TabCount 4 -PauseBetweenTabs 1000

    # Check if the Escape key has been pressed
    if ([KeyListener]::IsEscapePressed()) {
        Write-Host "Escape key pressed. Stopping..."
        break
    }

    # Sleep between cycles
    Start-Sleep -Milliseconds 500
}
