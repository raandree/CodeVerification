<#
.SYNOPSIS
    Export security scan results to JSON format
.DESCRIPTION
    Converts security scan findings to JSON for CI/CD integration
#>

function Export-SecurityReportJSON {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Findings,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Metadata = @{}
    )
    
    $report = @{
        metadata = @{
            generatedAt = (Get-Date -Format 'o')
            scanner = 'CodeVerification-SecurityScanner'
            version = '1.1.0'
        } + $Metadata
        summary = @{
            totalFindings = $Findings.Count
            critical = ($Findings | Where-Object { $_.Severity -eq 'Critical' }).Count
            high = ($Findings | Where-Object { $_.Severity -eq 'High' }).Count
            medium = ($Findings | Where-Object { $_.Severity -eq 'Medium' }).Count
            low = ($Findings | Where-Object { $_.Severity -eq 'Low' }).Count
        }
        findings = $Findings | ForEach-Object {
            @{
                id = $_.Rule
                name = $_.Name
                severity = $_.Severity
                category = $_.Category
                description = $_.Description
                file = $_.File
                line = $_.Line
                context = $_.Context
                remediation = $_.Remediation
                cvss = $_.CVSS
            }
        }
    }
    
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "JSON report exported to: $OutputPath" -ForegroundColor Green
}

Export-ModuleMember -Function Export-SecurityReportJSON
