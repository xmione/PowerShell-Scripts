# Define a function to recursively print directory structure
# Call the function for the specified directory

<#
    $excludeFolders = @(
        "C:\repo\NextJS\AccSolNextGridComponent\dist",
        "C:\repo\NextJS\AccSolNextGridComponent\.next",
        "C:\repo\NextJS\AccSolNextGridComponent\.github",
        "C:\repo\NextJS\AccSolNextGridComponent\node_modules"
    )

    Print-Folder-Structure -path "C:\repo\NextJS\AccSolNextGridComponent" -excludeFolders $excludeFolders     
#>
Function Print-Folder-Structure {
    param(
        [string]$path,
        [int]$indentLevel = 0,
        [string[]]$excludeFolders = @()
    )

    # Check if the current folder or any of its parents are in the exclude list
    foreach ($excludeFolder in $excludeFolders) {
        if ($path.StartsWith($excludeFolder)) {
            return
        }
    }

    # Get the directory name without the full path
    $folderName = Split-Path -Leaf $path

    # Construct the indentation string based on current level
    $indent = "    " * $indentLevel

    # Print the current folder with the appropriate indentation
    Write-Output ("$indent├── $folderName")

    # Get the list of items in the current directory
    $items = Get-ChildItem $path

    foreach ($item in $items) {
        # Skip . and .. special directories
        if ($item.Name -notin @('.', '..')) {
            # Check if the item is in the exclude list
            if ($item.FullName -notin $excludeFolders) {
                if ($item.PSIsContainer) {
                    # Recursively call function for directories
                    Print-Folder-Structure -path $item.FullName -indentLevel ($indentLevel + 1) -excludeFolders $excludeFolders
                } else {
                    # Determine the correct indentation for the item
                    $itemIndent = "    " * ($indentLevel + 1)
                    # Print the item with appropriate indentation
                    Write-Output ("$itemIndent├── " + $item.Name)
                }
            }
        }
    }
}

# Export the function so it can be used externally
Export-ModuleMember -Function Print-Folder-Structure

 
 
