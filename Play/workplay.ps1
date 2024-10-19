Add-Type -AssemblyName 'System.Windows.Forms'
Add-Type -AssemblyName 'System.Threading'

function MoveMouseInArc {
    param (
        [int]$startX,
        [int]$startY,
        [int]$endX,
        [int]$endY,
        [int]$duration
    )
    $steps = 100
    $deltaX = ($endX - $startX) / $steps
    $deltaY = ($endY - $startY) / $steps

    for ($i = 0; $i -le $steps; $i++) {
        $t = $i / $steps
        # Compute the arc (Bezier curve approximation)
        $x = [math]::Pow((1 - $t), 2) * $startX + 2 * (1 - $t) * $t * ($startX + $endX) / 2 + [math]::Pow($t, 2) * $endX
        $y = [math]::Pow((1 - $t), 2) * $startY + 2 * (1 - $t) * $t * ($startY + $endY) / 2 + [math]::Pow($t, 2) * $endY
        [Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point([math]::Round($x), [math]::Round($y))
        Start-Sleep -Milliseconds ($duration * 10 / $steps) # Adjust timing for smoothness
    }
}

function SimulateKeyPress {
    param (
        [string]$key,
        [int]$duration
    )
    $endTime = [DateTime]::Now.AddSeconds($duration)
    while ([DateTime]::Now -lt $endTime) {
        [System.Windows.Forms.SendKeys]::SendWait($key)
        MoveMouseRandomly
        Start-Sleep -Milliseconds 100
    }
}

function MoveMouseRandomly {
    $random = New-Object System.Random
    $currentPos = [Windows.Forms.Cursor]::Position
    $newX = $random.Next(100, 800)
    $newY = $random.Next(200, 900)
    MoveMouseInArc $currentPos.X $currentPos.Y $newX $newY 2
}

# Flag to control the loop
$global:stopScript = $false

# Listener for the Escape key
$form = [Windows.Forms.Form]::new()
$form.add_KeyDown({
    if ($_.KeyCode -eq [Windows.Forms.Keys]::Escape) {
        $global:stopScript = $true
        $form.Close()
    }
})
$form.Show()
$form.Focus()

$altTabCount = 3

while (-not $global:stopScript) {
    # 1. Alt+Tab 3 or 4 times with 1-second intervals, then pause for 1 second while moving the mouse
    for ($i = 0; $i -lt $altTabCount; $i++) {
        if ($i -eq 0) {
            [System.Windows.Forms.SendKeys]::SendWait("%{TAB}")
        } else {
            [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
        }
        MoveMouseRandomly
        Start-Sleep -Seconds 1
    }
    [System.Windows.Forms.SendKeys]::SendWait("%{TAB}")  # Release Alt key after sequence
    Start-Sleep -Seconds 1

    # Toggle between 3 and 4 Alt+Tabs for each cycle
    $altTabCount = if ($altTabCount -eq 3) { 4 } else { 3 }

    # 2. Scroll up for 10 seconds then pause for 1 second while moving the mouse
    $endTime = [DateTime]::Now.AddSeconds(10)
    while ([DateTime]::Now -lt $endTime -and -not $global:stopScript) {
        [System.Windows.Forms.SendKeys]::SendWait("{UP}")
        MoveMouseRandomly
        Start-Sleep -Milliseconds 100
    }
    Start-Sleep -Seconds 1

    # 3. Scroll down for 10 seconds then pause for 1 second while moving the mouse
    $endTime = [DateTime]::Now.AddSeconds(10)
    while ([DateTime]::Now -lt $endTime -and -not $global:stopScript) {
        [System.Windows.Forms.SendKeys]::SendWait("{DOWN}")
        MoveMouseRandomly
        Start-Sleep -Milliseconds 100
    }
    Start-Sleep -Seconds 1

    # 4. Press left arrow for 5 seconds then pause for 1 second while moving the mouse
    SimulateKeyPress("{LEFT}", 5)
    Start-Sleep -Seconds 1

    # 5. Press right arrow for 5 seconds then pause for 1 second while moving the mouse
    SimulateKeyPress("{RIGHT}", 5)
    Start-Sleep -Seconds 1
}

$form.Dispose()
