function Get-GitMergeStatus {

    $result = Start-MyProcess "git" "merge HEAD" -sleepTimer 0


    if ([string]::IsNullOrEmpty($result.stderr) ){
      Write-Output "Ready to Merge"
    }
    else {
        if ($result.stderr -like '*unresolved conflict*'){
            Write-Output 'Merge Conflict'
        }
        else{
            Write-Output "Unknown status"
        }
  }
} Export-ModuleMember -Function Get-GitMergeStatus
