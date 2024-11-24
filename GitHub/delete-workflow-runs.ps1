<#===========================================================================================================
File Name : delete-workflow-runs.ps1
Created By: Solomio S. Sisante
Created On: November 23, 2024
Created To: List and delete GitHub Action Workflow runs
How to Use: .\delete-workflow-runs.ps1 -GitHubToken "mygithubtoken" -Owner "xmione" -Repo "htdocs"
#===========================================================================================================#>
param (
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,

    [Parameter(Mandatory=$true)]
    [string]$Owner,

    [Parameter(Mandatory=$true)]
    [string]$Repo
)

# Set up headers for authentication
$Headers = @{
    "Authorization" = "token $GitHubToken"
    "Accept" = "application/vnd.github.v3+json"
}

# Step 1: List workflow runs and save to a .lst file
$DateTime = (Get-Date).ToString("yyyy-MM-ddTHH-mm-ss")
$ListFile = "wfruns-$DateTime.lst"

# URL to list workflow runs
$RunsUrl = "https://api.github.com/repos/$Owner/$Repo/actions/runs"

# Initialize the file to store the list of workflow runs
$WorkflowRuns = @()

# Fetch workflow runs (you may want to handle pagination for large numbers of runs)
$response = Invoke-RestMethod -Uri $RunsUrl -Method Get -Headers $Headers

# Collect the workflow runs into the list
$response.workflow_runs | ForEach-Object {
    $run = @{
        "id" = $_.id
        "name" = $_.name
        "status" = $_.status
        "conclusion" = $_.conclusion
    }
    $WorkflowRuns += $run
}

# Save the list to the .lst file
$WorkflowRuns | Out-File -FilePath $ListFile

Write-Host "Workflow runs have been saved to $ListFile"

# Step 2: Read the list from the .lst file and delete each workflow run
$WorkflowRuns | ForEach-Object {
    $RunId = $_.id
    $RunName = $_.name
    Write-Host "Deleting workflow run $RunName (ID: $RunId)..."

    # URL to delete the workflow run
    $DeleteUrl = "https://api.github.com/repos/$Owner/$Repo/actions/runs/$RunId"

    # Delete the workflow run
    try {
        $response = Invoke-RestMethod -Uri $DeleteUrl -Method Delete -Headers $Headers -ErrorAction Stop
        if ($response -eq $null -or $response -eq "") {
            Write-Host "Successfully deleted workflow run $RunName (ID: $RunId)"
        } else {
            Write-Host "Unexpected response while deleting workflow run $RunName (ID: $RunId): $($response | ConvertTo-Json -Depth 10)"
        }
    } catch {
        Write-Host "Error while deleting workflow run $RunName (ID: $RunId): $($_.Exception.Message)"
        Write-Host "Full Error: $($_ | ConvertTo-Json -Depth 10)"
    }
    
    
}

Write-Host "Finished processing workflow runs."

