# Define a function to recursively print directory structure
# Call the function for the current directory
# Print-Folder-Structure -path .

Function Print-Folder-Structure {
    param([string]$path, [int]$indentLevel = 0)

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
            if ($item.PSIsContainer) {
                # Recursively call function for directories
                Print-Folder-Structure -path $item.FullName -indentLevel ($indentLevel + 1)
            } else {
                # Determine the correct indentation for the item
                $itemIndent = "    " * ($indentLevel + 1)
                # Print the item with appropriate indentation
                Write-Output ("$itemIndent├── " + $item.Name)
            }
        }
    }
}


Export-ModuleMember -Function Print-Folder-Structure

 
