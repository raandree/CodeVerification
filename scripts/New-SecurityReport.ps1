<#
.SYNOPSIS
    Generates security reports from scan findings

.DESCRIPTION
    Converts JSON findings from security scans into markdown reports.
    Creates both executive summary and detailed module-specific reports.

.PARAMETER FindingsPath
    Path to the directory containing findings JSON files

.PARAMETER OutputPath
    Path where markdown reports will be generated

.EXAMPLE
    .\New-SecurityReport.ps1 -FindingsPath ".\findings" -OutputPath ".\Report"

.NOTES
    Author: Security Review System
    Date: October 17, 2025
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FindingsPath,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "=== Security Report Generator ===" -ForegroundColor Cyan

# Validate paths
if (-not (Test-Path $FindingsPath)) {
    throw "Findings path not found: $FindingsPath"
}

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Load all findings files
Write-Host "Loading findings..." -ForegroundColor Yellow
$findingsFiles = Get-ChildItem -Path $FindingsPath -Filter "*_findings.json"

if ($findingsFiles.Count -eq 0) {
    throw "No findings files found in $FindingsPath"
}

$allModuleData = @()

foreach ($file in $findingsFiles) {
    $data = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
    $allModuleData += $data
}

Write-Host "  Loaded findings for $($allModuleData.Count) modules" -ForegroundColor Green

# Generate Executive Summary
Write-Host "Generating Executive Summary..." -ForegroundColor Yellow

$executiveSummary = @"
# Security Review Executive Summary

**Review Date**: $(Get-Date -Format "MMMM dd, yyyy")  
**Project**: PowerShell Module Security Verification  
**Modules Reviewed**: $($allModuleData.Count)

## Overview

This security review analyzed PowerShell DSC modules for security vulnerabilities, unsafe coding practices, and potential malicious code patterns. The review used custom detection rules combined with industry-standard PSScriptAnalyzer tool.

## Executive Summary Statistics

"@

# Calculate aggregate statistics
$totalFiles = ($allModuleData | ForEach-Object { $_.Summary.FilesScanned } | Measure-Object -Sum).Sum
$totalFindings = ($allModuleData | ForEach-Object { $_.Summary.TotalFindings } | Measure-Object -Sum).Sum
$totalCritical = ($allModuleData | ForEach-Object { $_.Summary.FindingsBySeverity.Critical } | Measure-Object -Sum).Sum
$totalHigh = ($allModuleData | ForEach-Object { $_.Summary.FindingsBySeverity.High } | Measure-Object -Sum).Sum
$totalMedium = ($allModuleData | ForEach-Object { $_.Summary.FindingsBySeverity.Medium } | Measure-Object -Sum).Sum
$totalLow = ($allModuleData | ForEach-Object { $_.Summary.FindingsBySeverity.Low } | Measure-Object -Sum).Sum

$executiveSummary += @"

| Metric | Count |
|--------|-------|
| Total PowerShell Files Scanned | $totalFiles |
| Total Security Findings | $totalFindings |
| Critical Severity | $totalCritical |
| High Severity | $totalHigh |
| Medium Severity | $totalMedium |
| Low Severity | $totalLow |

## Risk Assessment

"@

# Risk assessment
if ($totalCritical -gt 0) {
    $executiveSummary += @"
**⚠️ CRITICAL RISK**: $totalCritical critical severity findings require immediate attention. These represent direct security threats such as hardcoded credentials, arbitrary code execution vulnerabilities, or malicious code patterns.

"@
}

if ($totalHigh -gt 0) {
    $executiveSummary += @"
**⚠️ HIGH RISK**: $totalHigh high severity findings represent significant security concerns requiring prompt remediation. These include information disclosure, injection vulnerabilities, and dangerous operations without proper validation.

"@
}

if ($totalMedium -gt 0) {
    $executiveSummary += @"
**⚠️ MEDIUM RISK**: $totalMedium medium severity findings should be reviewed and addressed. These include weak cryptography, missing validation, and suspicious behaviors.

"@
}

if ($totalCritical -eq 0 -and $totalHigh -eq 0) {
    $executiveSummary += @"
**✅ ACCEPTABLE RISK**: No critical or high severity findings detected. Medium and low severity findings represent best practice violations and should be addressed during normal development cycles.

"@
}

$executiveSummary += @"

## Findings by Module

"@

# Module-level summary table
$executiveSummary += "| Module | Files | Critical | High | Medium | Low | Total |`n"
$executiveSummary += "|--------|-------|----------|------|--------|-----|-------|`n"

foreach ($moduleData in $allModuleData) {
    $summary = $moduleData.Summary
    $executiveSummary += "| $($summary.ModuleName) | $($summary.FilesScanned) | $($summary.FindingsBySeverity.Critical) | $($summary.FindingsBySeverity.High) | $($summary.FindingsBySeverity.Medium) | $($summary.FindingsBySeverity.Low) | $($summary.TotalFindings) |`n"
}

$executiveSummary += @"

## Top Vulnerability Categories

"@

# Aggregate findings by category
$allFindings = $allModuleData | ForEach-Object { $_.Findings }
$categoryGroups = $allFindings | Group-Object Category | Sort-Object Count -Descending | Select-Object -First 10

$executiveSummary += "| Category | Findings |`n"
$executiveSummary += "|----------|----------|`n"

foreach ($group in $categoryGroups) {
    $executiveSummary += "| $($group.Name) | $($group.Count) |`n"
}

$executiveSummary += @"

## Recommendations

### Immediate Actions Required

"@

if ($totalCritical -gt 0) {
    $executiveSummary += "1. **Address all $totalCritical critical findings immediately** - These represent direct security threats`n"
    $executiveSummary += "2. **Review hardcoded credentials** - Remove all plaintext passwords and implement secure credential storage`n"
    $executiveSummary += "3. **Eliminate code execution vulnerabilities** - Replace Invoke-Expression with safer alternatives`n"
}
else {
    $executiveSummary += "1. **No immediate critical actions required**`n"
}

$executiveSummary += @"

### Short-Term Actions (Within Sprint)

1. Address high severity findings related to information disclosure
2. Implement proper input validation across all parameters
3. Review and secure all network communication
4. Add proper error handling to empty catch blocks

### Long-Term Improvements

1. Implement comprehensive comment-based help for all functions
2. Standardize on named parameters instead of positional
3. Add output type attributes for better pipeline support
4. Review and update cryptographic implementations to use current best practices

## Detailed Reports

Detailed findings for each module are available in the following reports:

"@

foreach ($moduleData in $allModuleData) {
    $executiveSummary += "- [$($moduleData.Summary.ModuleName) Detailed Report](./$($moduleData.Summary.ModuleName)_DetailedReport.md)`n"
}

$executiveSummary += @"

## Methodology

This security review employed:

1. **Custom Detection Rules**: 35 security rules covering critical vulnerabilities, code execution risks, credential exposure, and best practice violations
2. **AST-Based Analysis**: PowerShell Abstract Syntax Tree parsing for deep code analysis
3. **PSScriptAnalyzer Integration**: Industry-standard static analysis tool
4. **PowerShell-Aware Rules**: Rules tuned to minimize false positives while identifying real security issues
5. **CVSS Scoring**: Industry-standard Common Vulnerability Scoring System for severity ratings

## Important Notes

- **High Entropy Strings**: Findings related to high entropy are flagged for manual review. PowerShell code naturally has descriptive naming with high entropy.
- **Credential Handling**: Use of PSCredential and SecureString parameters is correct and expected in PowerShell DSC modules.
- **Username Logging**: Logging usernames or user IDs for debugging purposes is acceptable. Only plaintext password logging is flagged as critical.

---

*Generated by PowerShell Security Scanner on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

# Save executive summary
$execSummaryPath = Join-Path $OutputPath "ExecutiveSummary.md"
$executiveSummary | Set-Content -Path $execSummaryPath -Encoding UTF8

Write-Host "  Executive Summary saved to: $execSummaryPath" -ForegroundColor Green

# Generate detailed reports for each module
Write-Host "Generating detailed module reports..." -ForegroundColor Yellow

foreach ($moduleData in $allModuleData) {
    $moduleName = $moduleData.Summary.ModuleName
    Write-Host "  Processing $moduleName..." -ForegroundColor Gray
    
    $detailedReport = @"
# Security Review: $moduleName

**Review Date**: $(Get-Date -Format "MMMM dd, yyyy")  
**Module Path**: $($moduleData.Summary.ModulePath)  
**Files Scanned**: $($moduleData.Summary.FilesScanned)  
**Total Findings**: $($moduleData.Summary.TotalFindings)

## Summary

| Severity | Count |
|----------|-------|
| Critical | $($moduleData.Summary.FindingsBySeverity.Critical) |
| High | $($moduleData.Summary.FindingsBySeverity.High) |
| Medium | $($moduleData.Summary.FindingsBySeverity.Medium) |
| Low | $($moduleData.Summary.FindingsBySeverity.Low) |

## Detailed Findings

"@

    # Group findings by severity
    $criticalFindings = $moduleData.Findings | Where-Object { $_.Severity -eq 'Critical' }
    $highFindings = $moduleData.Findings | Where-Object { $_.Severity -eq 'High' }
    $mediumFindings = $moduleData.Findings | Where-Object { $_.Severity -eq 'Medium' }
    $lowFindings = $moduleData.Findings | Where-Object { $_.Severity -eq 'Low' }
    
    # Critical findings
    if ($criticalFindings) {
        $detailedReport += "### 🔴 Critical Severity Findings`n`n"
        
        $groupedCritical = $criticalFindings | Group-Object RuleId
        foreach ($group in $groupedCritical) {
            $finding = $group.Group[0]
            $detailedReport += "#### $($finding.RuleName) (Rule: $($finding.RuleId))`n`n"
            $detailedReport += "**Category**: $($finding.Category)  `n"
            $detailedReport += "**CVSS Score**: $($finding.CVSS)  `n"
            $detailedReport += "**Occurrences**: $($group.Count)  `n`n"
            $detailedReport += "**Description**: $($finding.Message)`n`n"
            
            # List all occurrences
            $detailedReport += "**Locations**:`n`n"
            foreach ($item in $group.Group) {
                $relPath = $item.File -replace [regex]::Escape($moduleData.Summary.ModulePath), ''
                $relPath = $relPath.TrimStart('\', '/')
                $detailedReport += "- **File**: ``$relPath```n"
                $detailedReport += "  - **Line**: $($item.Line)`n"
                $detailedReport += "  - **Code**: ````powershell`n$($item.Code)`n``````n`n"
            }
            
            $detailedReport += "**Remediation**: $($finding.Remediation)`n`n"
            $detailedReport += "---`n`n"
        }
    }
    
    # High findings
    if ($highFindings) {
        $detailedReport += "### 🟠 High Severity Findings`n`n"
        
        $groupedHigh = $highFindings | Group-Object RuleId
        foreach ($group in $groupedHigh) {
            $finding = $group.Group[0]
            $detailedReport += "#### $($finding.RuleName) (Rule: $($finding.RuleId))`n`n"
            $detailedReport += "**Category**: $($finding.Category)  `n"
            $detailedReport += "**CVSS Score**: $($finding.CVSS)  `n"
            $detailedReport += "**Occurrences**: $($group.Count)  `n`n"
            
            # List up to 5 occurrences for high
            $sampleCount = [Math]::Min(5, $group.Count)
            $detailedReport += "**Sample Locations** (showing $sampleCount of $($group.Count)):`n`n"
            foreach ($item in ($group.Group | Select-Object -First 5)) {
                $relPath = $item.File -replace [regex]::Escape($moduleData.Summary.ModulePath), ''
                $relPath = $relPath.TrimStart('\', '/')
                $detailedReport += "- **File**: ``$relPath`` - **Line**: $($item.Line)`n"
                $detailedReport += "````powershell`n$($item.Code)`n``````n`n"
            }
            
            $detailedReport += "**Remediation**: $($finding.Remediation)`n`n"
            $detailedReport += "---`n`n"
        }
    }
    
    # Medium findings (summarized)
    if ($mediumFindings) {
        $detailedReport += "### 🟡 Medium Severity Findings`n`n"
        
        $groupedMedium = $mediumFindings | Group-Object RuleId
        foreach ($group in $groupedMedium) {
            $finding = $group.Group[0]
            $detailedReport += "#### $($finding.RuleName) (Rule: $($finding.RuleId))`n`n"
            $detailedReport += "**Category**: $($finding.Category) | **CVSS**: $($finding.CVSS) | **Occurrences**: $($group.Count)`n`n"
            $detailedReport += "**Description**: $($finding.Message)`n`n"
            $detailedReport += "**Remediation**: $($finding.Remediation)`n`n"
            $detailedReport += "---`n`n"
        }
    }
    
    # Low findings (summarized)
    if ($lowFindings) {
        $detailedReport += "### ⚪ Low Severity Findings (Best Practices)`n`n"
        
        $groupedLow = $lowFindings | Group-Object RuleId
        $detailedReport += "| Rule | Category | Count |`n"
        $detailedReport += "|------|----------|-------|`n"
        foreach ($group in $groupedLow) {
            $finding = $group.Group[0]
            $detailedReport += "| $($finding.RuleName) | $($finding.Category) | $($group.Count) |`n"
        }
        $detailedReport += "`n"
    }
    
    $detailedReport += @"

## Conclusion

This module has been scanned for security vulnerabilities and coding best practices. Review all findings and implement the recommended remediations.

**Priority Actions**:
1. Address all Critical findings immediately
2. Review and remediate High findings
3. Plan Medium findings for next development cycle
4. Address Low findings as part of code quality improvements

---

*Generated by PowerShell Security Scanner on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@
    
    # Save detailed report
    $detailedReportPath = Join-Path $OutputPath "$($moduleName)_DetailedReport.md"
    $detailedReport | Set-Content -Path $detailedReportPath -Encoding UTF8
    
    Write-Host "    Saved: $detailedReportPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Report Generation Complete ===" -ForegroundColor Cyan
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
Write-Host ""
