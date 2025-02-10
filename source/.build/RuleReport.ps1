task RuleReport {
    $c = Get-DatumRsopCache

    foreach ($key in $c.Keys)
    {
        $syncServer = $c.$key
        $rules = $syncServer.AADSyncRules.Items
        Write-Host "`u{1f5a5} Sync Server '$key' has $($rules.Count) rules" -ForegroundColor Magenta

        $rules = foreach ($rule in $rules.GetEnumerator())
        {
            $rule.Value | ForEach-Object {
                [pscustomobject]$rule
            }
        }
        $rules | Sort-Object -Property Precedence | Format-Table -Property Name, Disabled, Precedence, ConnectorName
    }
}
