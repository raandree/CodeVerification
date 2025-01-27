task DisplayAADConnectServerRules {
    $rsopCache = Get-DatumRsopCache

    $mappingInfo = foreach ($key in $rsopCache.Keys)
    {
        $rsop = $rsopCache[$key]

        @{
            ServerName = '{0} - {1}' -f $key, ($rsop.ConnectorNames -join ', ')
            Rules      = foreach ($rule in $rsop.AADSyncRules.Items)
            {
                '{0} {1} ({2})' -f $rule.Precedence, $rule.Name, $rule.ConnectorName
            }
        }
    }

    Write-Host 'Mapping information for AAD Connect servers:' -ForegroundColor Green
    $mappingInfo | ConvertTo-Yaml | Write-Host

}
