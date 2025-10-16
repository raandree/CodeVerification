function Export-SecurityReportHTML {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Findings,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Metadata = @{}
    )
    
    $critical = ($Findings | Where-Object { $_.Severity -eq ''Critical'' }).Count
    $high = ($Findings | Where-Object { $_.Severity -eq ''High'' }).Count
    $medium = ($Findings | Where-Object { $_.Severity -eq ''Medium'' }).Count
    $low = ($Findings | Where-Object { $_.Severity -eq ''Low'' }).Count
    
    $riskScore = ($critical * 10) + ($high * 5) + ($medium * 2) + ($low * 0.5)
    $riskLevel = if($riskScore -gt 50){"Critical"}elseif($riskScore -gt 20){"High"}else{"Low"}
    
    $html = @"
<!DOCTYPE html>
<html lang=''en''>
<head>
    <meta charset=''UTF-8''>
    <meta name=''viewport'' content=''width=device-width, initial-scale=1.0''>
    <title>Security Scan Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, ''Segoe UI'', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; margin-bottom: 10px; }
        .meta { color: #666; font-size: 14px; margin-bottom: 30px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .stat-card { padding: 20px; border-radius: 6px; text-align: center; }
        .stat-card h3 { margin: 0; font-size: 32px; }
        .stat-card p { margin: 5px 0 0 0; color: #666; }
        .critical-card { background: #fee; border-left: 4px solid #d00; }
        .high-card { background: #fef0f0; border-left: 4px solid #c30; }
        .medium-card { background: #fffef0; border-left: 4px solid #fc0; }
        .low-card { background: #f0f8ff; border-left: 4px solid #08f; }
        .risk-badge { display: inline-block; padding: 5px 15px; border-radius: 20px; font-weight: bold; }
        .risk-critical { background: #d00; color: white; }
        .risk-high { background: #f80; color: white; }
        .risk-low { background: #0a0; color: white; }
        .findings { margin-top: 30px; }
        .finding { background: #fafafa; padding: 20px; margin-bottom: 15px; border-radius: 6px; border-left: 4px solid #ddd; }
        .finding h4 { margin: 0 0 10px 0; color: #333; }
        .finding-meta { display: flex; gap: 15px; margin-bottom: 10px; font-size: 14px; }
        .finding-meta span { background: #e0e0e0; padding: 3px 8px; border-radius: 3px; }
        .severity-critical { background: #d00; color: white; }
        .severity-high { background: #f80; color: white; }
        .severity-medium { background: #fc0; color: #000; }
        .severity-low { background: #08f; color: white; }
        code { background: #f0f0f0; padding: 2px 6px; border-radius: 3px; font-family: ''Courier New'', monospace; }
        .code-block { background: #2d2d2d; color: #f8f8f2; padding: 15px; border-radius: 6px; overflow-x: auto; margin: 10px 0; }
    </style>
</head>
<body>
    <div class=''container''>
        <h1>🛡️ Security Scan Report</h1>
        <div class=''meta''>
            Generated: $(Get-Date -Format ''yyyy-MM-dd HH:mm:ss'') | Total Findings: $($Findings.Count)
        </div>
        
        <div class=''summary''>
            <div class=''stat-card critical-card''>
                <h3>$critical</h3>
                <p>Critical</p>
            </div>
            <div class=''stat-card high-card''>
                <h3>$high</h3>
                <p>High</p>
            </div>
            <div class=''stat-card medium-card''>
                <h3>$medium</h3>
                <p>Medium</p>
            </div>
            <div class=''stat-card low-card''>
                <h3>$low</h3>
                <p>Low</p>
            </div>
        </div>
        
        <h2>Risk Assessment</h2>
        <p>Overall Risk Score: <strong>$riskScore</strong> | Risk Level: <span class=''risk-badge risk-$($riskLevel.ToLower())''>$riskLevel</span></p>
        
        <div class=''findings''>
            <h2>Detailed Findings</h2>
"@
    
    foreach ($finding in $Findings | Sort-Object {
        switch($_.Severity) {
            'Critical' { 0 }
            'High' { 1 }
            'Medium' { 2 }
            'Low' { 3 }
            default { 4 }
        }
    }) {
        $html += @"
            <div class=''finding''>
                <h4>$($finding.Name ?? $finding.Rule)</h4>
                <div class=''finding-meta''>
                    <span class=''severity-$($finding.Severity.ToLower())''>$($finding.Severity)</span>
                    <span>$($finding.Category ?? ''N/A'')</span>
                    <span>Rule: $($finding.Rule)</span>
                </div>
                <p><strong>Description:</strong> $($finding.Description)</p>
                <p><strong>File:</strong> <code>$($finding.File)</code> (Line $($finding.Line))</p>
                $(if($finding.Context){"<div class=''code-block''>$($finding.Context -replace '<','&lt;' -replace '>','&gt;')</div>"})
                <p><strong>Remediation:</strong> $($finding.Remediation ?? ''Review and validate this code'')</p>
                $(if($finding.CVSS){"<p><strong>CVSS Score:</strong> $($finding.CVSS)</p>"})
            </div>
"@
    }
    
    $html += @"
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "HTML report exported to: $OutputPath" -ForegroundColor Green
}

Export-ModuleMember -Function Export-SecurityReportHTML
