Class PromTrackerItems : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {

		$mds = @()
		$t = Get-Content "$env:USERPROFILE\.friendly-chainsaw\tracker.json" -raw | ConvertFrom-Json -ErrorAction Stop
		foreach ($i in $t){
			$mds += $i
		}
        return [string[]] ($mds | select -expandProperty name)
    }
}