<#
.SYNOPSIS
    Generate security analysis reports from findings
.DESCRIPTION
    Creates detailed markdown reports for each module and an executive summary
.PARAMETER FindingsPath
    Path to findings XML files
.PARAMETER OutputPath
    Path where reports will be generated
.EXAMPLE
    .\New-SecurityReport.ps1 -FindingsPath "C:\CodeVerification\Report" -OutputPath "C:\CodeVerification\Report"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FindingsPath,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

# Get all findings files
$findingsFiles = Get-ChildItem -Path $FindingsPath -Filter "*_Findings.xml"

if ($findingsFiles.Count -eq 0) {
    Write-Error "No findings files found in $FindingsPath"
    return
}

$allModuleFindings = @{}

# Load all findings
foreach ($findingFile in $findingsFiles) {
    $moduleName = $findingFile.BaseName -replace '_Findings$', ''
    $findings = Import-Clixml -Path $findingFile.FullName
    $allModuleFindings[$moduleName] = $findings
    
    Write-Host "Loaded $($findings.Count) findings for module: $moduleName" -ForegroundColor Cyan
}

# Generate Executive Summary
Write-Host "`nGenerating Executive Summary..." -ForegroundColor Cyan

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# Executive Summary: PowerShell Security Analysis")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("**Date**: $(Get-Date -Format 'yyyy-MM-DD')")
[void]$sb.AppendLine("**Analyst**: Automated Security Scanner")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Overview")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("This report presents the security analysis results for PowerShell modules in the source directory.")
[void]$sb.AppendLine("")

# Overall statistics
$totalFindings = ($allModuleFindings.Values | Measure-Object -Property Count -Sum).Sum
[void]$sb.AppendLine("### Summary Statistics")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- **Modules Analyzed**: $($allModuleFindings.Count)")
[void]$sb.AppendLine("- **Total Findings**: $totalFindings")
[void]$sb.AppendLine("")

# Severity breakdown
$allFindings = $allModuleFindings.Values | ForEach-Object { $_ }
$severityGroups = $allFindings | Group-Object Severity | Sort-Object Name

[void]$sb.AppendLine("### Findings by Severity")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Severity | Count | Percentage |")
[void]$sb.AppendLine("|----------|-------|------------|")

foreach ($sev in @('Critical', 'High', 'Medium', 'Low')) {
    $count = ($severityGroups | Where-Object { $_.Name -eq $sev }).Count
    if (-not $count) { $count = 0 }
    $pct = if ($totalFindings -gt 0) { [math]::Round(($count / $totalFindings) * 100, 1) } else { 0 }
    [void]$sb.AppendLine("| $sev | $count | $pct% |")
}

[void]$sb.AppendLine("")

# Risk assessment
$criticalCount = ($severityGroups | Where-Object { $_.Name -eq 'Critical' }).Count
$highCount = ($severityGroups | Where-Object { $_.Name -eq 'High' }).Count

[void]$sb.AppendLine("### Risk Assessment")
[void]$sb.AppendLine("")

$riskLevel = if ($criticalCount -gt 10) {
    "**CRITICAL** - Immediate action required"
} elseif ($criticalCount -gt 0 -or $highCount -gt 20) {
    "**HIGH** - Urgent attention needed"
} elseif ($highCount -gt 0) {
    "**MEDIUM** - Review and remediate"
} else {
    "**LOW** - Monitor and maintain"
}

[void]$sb.AppendLine("Overall Risk Level: $riskLevel")
[void]$sb.AppendLine("")

# Top categories
$categoryGroups = $allFindings | Group-Object Category | Sort-Object Count -Descending | Select-Object -First 10

[void]$sb.AppendLine("### Top Finding Categories")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Category | Count |")
[void]$sb.AppendLine("|----------|-------|")

foreach ($cat in $categoryGroups) {
    [void]$sb.AppendLine("| $($cat.Name) | $($cat.Count) |")
}

[void]$sb.AppendLine("")

# Per-module summary
[void]$sb.AppendLine("## Module Analysis Summary")
[void]$sb.AppendLine("")

foreach ($moduleName in $allModuleFindings.Keys | Sort-Object) {
    $findings = $allModuleFindings[$moduleName]
    $modSevGroups = $findings | Group-Object Severity
    
    $critCount = ($modSevGroups | Where-Object { $_.Name -eq 'Critical' }).Count
    $highCount = ($modSevGroups | Where-Object { $_.Name -eq 'High' }).Count
    $medCount = ($modSevGroups | Where-Object { $_.Name -eq 'Medium' }).Count
    $lowCount = ($modSevGroups | Where-Object { $_.Name -eq 'Low' }).Count
    
    [void]$sb.AppendLine("### $moduleName")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("- **Total Findings**: $($findings.Count)")
    [void]$sb.AppendLine("- **Critical**: $critCount | **High**: $highCount | **Medium**: $medCount | **Low**: $lowCount")
    [void]$sb.AppendLine("- **Detailed Report**: [$moduleName Report](./$moduleName" + "_Report.md)")
    [void]$sb.AppendLine("")
}

# Critical findings highlight
$criticalFindings = $allFindings | Where-Object { $_.Severity -eq 'Critical' } | Select-Object -First 10

if ($criticalFindings) {
    [void]$sb.AppendLine("## Critical Findings Highlight")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Top critical security issues requiring immediate attention:")
    [void]$sb.AppendLine("")
    
    $criticalByRule = $criticalFindings | Group-Object Rule | Sort-Object Count -Descending | Select-Object -First 5
    
    foreach ($ruleGroup in $criticalByRule) {
        [void]$sb.AppendLine("### $($ruleGroup.Name)")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("- **Occurrences**: $($ruleGroup.Count)")
        [void]$sb.AppendLine("- **Description**: $($ruleGroup.Group[0].Description)")
        [void]$sb.AppendLine("")
    }
}

# Recommendations
[void]$sb.AppendLine("## Recommendations")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("1. **Immediate Actions**:")
[void]$sb.AppendLine("   - Review and remediate all Critical severity findings")
[void]$sb.AppendLine("   - Assess High severity findings for business impact")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("2. **Short-term Actions**:")
[void]$sb.AppendLine("   - Address Medium severity vulnerabilities")
[void]$sb.AppendLine("   - Implement security controls for identified patterns")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("3. **Long-term Actions**:")
[void]$sb.AppendLine("   - Establish secure coding standards")
[void]$sb.AppendLine("   - Implement automated security scanning in CI/CD")
[void]$sb.AppendLine("   - Provide security training for developers")
[void]$sb.AppendLine("")

# Module context note
[void]$sb.AppendLine("## Important Context Notes")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("### Nishang Module")
[void]$sb.AppendLine("The nishang module is a penetration testing framework. Many security findings are expected and intentional features of offensive security tools. Findings should be interpreted as documentation of tool capabilities rather than vulnerabilities to fix.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("### DSC Modules")
[void]$sb.AppendLine("DSC (Desired State Configuration) modules legitimately perform system configuration tasks that may trigger security rules. Context-aware assessment is required to distinguish configuration management from malicious activity.")
[void]$sb.AppendLine("")

$execSummaryPath = Join-Path $OutputPath "ExecutiveSummary.md"
$sb.ToString() | Out-File -FilePath $execSummaryPath -Encoding utf8
Write-Host "Executive Summary generated: $execSummaryPath" -ForegroundColor Green

# Generate detailed per-module reports
foreach ($moduleName in $allModuleFindings.Keys | Sort-Object) {
    Write-Host "Generating detailed report for: $moduleName" -ForegroundColor Cyan
    
    $findings = $allModuleFindings[$moduleName]
    $reportPath = Join-Path $OutputPath ($moduleName + "_Report.md")
    
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# Security Analysis Report: $moduleName")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("**Date**: $(Get-Date -Format 'yyyy-MM-DD')")
    [void]$sb.AppendLine("**Module**: $moduleName")
    [void]$sb.AppendLine("**Total Findings**: $($findings.Count)")
    [void]$sb.AppendLine("")
    
    # Statistics
    $sevGroups = $findings | Group-Object Severity
    [void]$sb.AppendLine("## Summary")
    [void]$sb.AppendLine("")
    foreach ($sev in @('Critical', 'High', 'Medium', 'Low')) {
        $count = ($sevGroups | Where-Object { $_.Name -eq $sev }).Count
        if (-not $count) { $count = 0 }
        [void]$sb.AppendLine("- **$sev**: $count")
    }
    [void]$sb.AppendLine("")
    
    # Group findings by category, then rule
    $byCategory = $findings | Group-Object Category | Sort-Object Name
    
    [void]$sb.AppendLine("## Detailed Findings")
    [void]$sb.AppendLine("")
    
    foreach ($catGroup in $byCategory) {
        [void]$sb.AppendLine("### Category: $($catGroup.Name)")
        [void]$sb.AppendLine("")
        
        $byRule = $catGroup.Group | Group-Object Rule | Sort-Object Name
        
        foreach ($ruleGroup in $byRule) {
            [void]$sb.AppendLine("#### $($ruleGroup.Name)")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("**Severity**: $($ruleGroup.Group[0].Severity)")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("**Description**: $($ruleGroup.Group[0].Description)")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("**Remediation**: $($ruleGroup.Group[0].Remediation)")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("**CVSS Score**: $($ruleGroup.Group[0].CVSS)")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("**Occurrences**: $($ruleGroup.Count)")
            [void]$sb.AppendLine("")
            
            # List occurrences (limit to first 20 per rule to avoid huge reports)
            $occurrences = $ruleGroup.Group | Select-Object -First 20
            
            foreach ($finding in $occurrences) {
                $fileRef = "``" + $finding.File + "``"
                [void]$sb.AppendLine("**File**: $fileRef")
                [void]$sb.AppendLine("")
                [void]$sb.AppendLine("- **Line**: $($finding.Line)")
                [void]$sb.AppendLine("  ``````powershell")
                [void]$sb.AppendLine("  $($finding.Code)")
                [void]$sb.AppendLine("  ``````")
                [void]$sb.AppendLine("")
            }
            
            if ($ruleGroup.Count -gt 20) {
                $remaining = $ruleGroup.Count - 20
                [void]$sb.AppendLine("($remaining more occurrences not shown)")
                [void]$sb.AppendLine("")
            }
            
            [void]$sb.AppendLine("---")
            [void]$sb.AppendLine("")
        }
    }
    
    $sb.ToString() | Out-File -FilePath $reportPath -Encoding utf8
    Write-Host "  Report generated: $reportPath" -ForegroundColor Green
}

Write-Host "`n=== Report Generation Complete ===" -ForegroundColor Cyan
Write-Host "Executive Summary: $execSummaryPath" -ForegroundColor Green
Write-Host "Module Reports in: $OutputPath" -ForegroundColor Green
