# Comprehensive Security Analysis
# Purpose: Run detailed security analysis using PSScriptAnalyzer and custom rules

param(
    [string]$SourcePath = ".\source",
    [string]$OutputPath = ".\Report"
)

Write-Host "Comprehensive PowerShell Security Analysis" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Check for PSScriptAnalyzer
$hasPSA = $false
try {
    Import-Module PSScriptAnalyzer -ErrorAction Stop
    $hasPSA = $true
    Write-Host "✓ PSScriptAnalyzer loaded" -ForegroundColor Green
}
catch {
    Write-Warning "PSScriptAnalyzer not available. Install with: Install-Module -Name PSScriptAnalyzer"
}

# Get all PowerShell files
$psFiles = Get-ChildItem -Path $SourcePath -Filter "*.ps*" -Recurse | Where-Object { $_.Extension -match "\.(ps1|psm1|psd1)$" }
Write-Host "✓ Found $($psFiles.Count) PowerShell files" -ForegroundColor Green

# Initialize findings collection
$allFindings = @()

# Run PSScriptAnalyzer if available
if ($hasPSA) {
    Write-Host "`nRunning PSScriptAnalyzer..." -ForegroundColor Yellow
    try {
        $psaResults = Invoke-ScriptAnalyzer -Path $SourcePath -Recurse -IncludeDefaultRules
        
        foreach ($result in $psaResults) {
            $severity = switch ($result.Severity) {
                'Error' { 'High' }
                'Warning' { 'Medium' }
                'Information' { 'Low' }
                default { 'Low' }
            }
            
            $allFindings += [PSCustomObject]@{
                Rule = "PSA_$($result.RuleName)"
                Category = 'PSScriptAnalyzer'
                File = $result.ScriptPath
                Line = $result.Line
                Code = if ($result.Extent.Text.Length -gt 200) { $result.Extent.Text.Substring(0, 200) + "..." } else { $result.Extent.Text }
                Description = $result.Message
                Remediation = "Review PSScriptAnalyzer documentation for rule: $($result.RuleName)"
                Severity = $severity
                CVSS = 3.0
            }
        }
        Write-Host "✓ PSScriptAnalyzer found $($psaResults.Count) issues" -ForegroundColor Green
    }
    catch {
        Write-Warning "Error running PSScriptAnalyzer: $($_.Exception.Message)"
    }
}

# Run custom security checks
Write-Host "`nRunning custom security analysis..." -ForegroundColor Yellow

foreach ($file in $psFiles) {
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        
        $lines = Get-Content $file.FullName
        $lineNumber = 0
        
        foreach ($line in $lines) {
            $lineNumber++
            
            # PS001 - Invoke-Expression Usage
            if ($line -match "Invoke-Expression|iex\s+") {
                $allFindings += [PSCustomObject]@{
                    Rule = "PS001"
                    Category = "CodeExecution"
                    File = $file.FullName
                    Line = $lineNumber
                    Code = $line.Trim()
                    Description = "Use of Invoke-Expression which can execute arbitrary code from strings"
                    Remediation = "Replace Invoke-Expression with safer alternatives like `"&`" operator or dot-sourcing"
                    Severity = "High"
                    CVSS = 7.5
                }
            }
            
            # PS005 - Hardcoded Credentials (more specific)
            if ($line -match 'password\s*[:=]\s*["''][^"''*\s]{8,}["'']' -and $line -notmatch 'password.*(\*+|example|placeholder|changeme|test)') {
                $allFindings += [PSCustomObject]@{
                    Rule = "PS005"
                    Category = "CredentialSecurity"
                    File = $file.FullName
                    Line = $lineNumber
                    Code = $line.Trim()
                    Description = "Potential hardcoded credential detected"
                    Remediation = "Use secure credential storage mechanisms like Windows Credential Manager"
                    Severity = "Critical"
                    CVSS = 9.8
                }
            }
            
            # PS006 - Credential Logging
            if ($line -match '(Write-Host|Write-Output|Write-Verbose|Out-File).*(\$credential|\$cred|\.Password)' -and $line -notmatch '\*+') {
                $allFindings += [PSCustomObject]@{
                    Rule = "PS006"
                    Category = "CredentialSecurity"
                    File = $file.FullName
                    Line = $lineNumber
                    Code = $line.Trim()
                    Description = "Potential logging of credential information"
                    Remediation = "Never log credential objects or plaintext passwords"
                    Severity = "High"
                    CVSS = 8.5
                }
            }
            
            # PS008 - SQL Injection Risk
            if ($line -match '(SELECT|INSERT|UPDATE|DELETE).*\$.*[+]') {
                $allFindings += [PSCustomObject]@{
                    Rule = "PS008"
                    Category = "InputValidation"
                    File = $file.FullName
                    Line = $lineNumber
                    Code = $line.Trim()
                    Description = "Potential SQL injection vulnerability in database query"
                    Remediation = "Use parameterized queries and input validation"
                    Severity = "High"
                    CVSS = 8.2
                }
            }
            
            # PS009 - Command Injection Risk
            if ($line -match '(Start-Process|Invoke-Item|cmd\.exe|powershell\.exe).*\$.*[+]') {
                $allFindings += [PSCustomObject]@{
                    Rule = "PS009"
                    Category = "InputValidation"
                    File = $file.FullName
                    Line = $lineNumber
                    Code = $line.Trim()
                    Description = "Potential command injection vulnerability"
                    Remediation = "Validate and sanitize all user inputs before using in commands"
                    Severity = "High"
                    CVSS = 8.0
                }
            }
            
            # PS016 - Insecure Network Protocols (but filter out comments and documentation)
            if ($line -match 'http://' -and $line -notmatch '^\s*#' -and $line -notmatch '^\s*\*' -and $line -notmatch 'e\.g|example') {
                $allFindings += [PSCustomObject]@{
                    Rule = "PS016"
                    Category = "NetworkSecurity"
                    File = $file.FullName
                    Line = $lineNumber
                    Code = $line.Trim()
                    Description = "Use of insecure HTTP protocol"
                    Remediation = "Use secure protocols like HTTPS"
                    Severity = "Medium"
                    CVSS = 5.2
                }
            }
            
            # PS019 - Weak Cryptographic Algorithms
            if ($line -match '\b(MD5|SHA1|DES|RC4)\b' -and $line -notmatch '^\s*#') {
                $allFindings += [PSCustomObject]@{
                    Rule = "PS019"
                    Category = "Cryptography"
                    File = $file.FullName
                    Line = $lineNumber
                    Code = $line.Trim()
                    Description = "Use of weak or deprecated cryptographic algorithm"
                    Remediation = "Use strong cryptographic algorithms like AES and SHA-256"
                    Severity = "Medium"
                    CVSS = 5.5
                }
            }
        }
    }
    catch {
        Write-Warning "Error analyzing $($file.FullName): $($_.Exception.Message)"
    }
}

Write-Host "✓ Custom analysis completed" -ForegroundColor Green

# Group findings by module/directory
$moduleFindings = $allFindings | Group-Object { 
    $relativePath = $_.File.Replace((Resolve-Path $SourcePath).Path, "").Trim('\')
    $parts = $relativePath.Split('\')
    if ($parts.Count -gt 0) { $parts[0] } else { "Unknown" }
}

# Generate executive summary
$execSummaryPath = Join-Path $OutputPath "Executive-Summary.md"
$execSummary = @"
# Executive Security Summary
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Overall Security Posture
- **Total PowerShell Files Analyzed**: $($psFiles.Count)
- **Total Security Issues Identified**: $($allFindings.Count)
- **Modules Analyzed**: $($moduleFindings.Count)

## Risk Distribution
$(($allFindings | Group-Object Severity | Sort-Object { @{'Critical'=5;'High'=4;'Medium'=3;'Low'=2;'Informational'=1}[$_.Name] } -Descending | ForEach-Object { "- **$($_.Name)**: $($_.Count) issues" }) -join "`n")

## Modules Analysis
$(($moduleFindings | ForEach-Object { "- **$($_.Name)**: $($_.Group.Count) issues" }) -join "`n")

## Top Security Concerns
$(($allFindings | Group-Object Description | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object { "- **$($_.Name)**: $($_.Count) occurrences" }) -join "`n")

## Critical Findings Summary
$(if (($allFindings | Where-Object Severity -eq 'Critical').Count -gt 0) {
    "⚠️  **CRITICAL ISSUES FOUND** - Immediate attention required"
} else {
    "✅ No critical security issues identified"
})

## High Risk Findings Summary
$(if (($allFindings | Where-Object Severity -eq 'High').Count -gt 0) {
    "⚠️  **HIGH RISK ISSUES FOUND** - Should be addressed promptly"
} else {
    "✅ No high risk security issues identified"
})

## Recommendations
1. Address all Critical and High severity issues immediately
2. Review Medium severity issues for business context
3. Implement secure coding practices training
4. Establish regular security code reviews
5. Consider implementing automated security scanning in CI/CD pipeline

## Module-Specific Recommendations
$(($moduleFindings | ForEach-Object {
    $critical = ($_.Group | Where-Object Severity -eq 'Critical').Count
    $high = ($_.Group | Where-Object Severity -eq 'High').Count
    $medium = ($_.Group | Where-Object Severity -eq 'Medium').Count
    
    "### $($_.Name)"
    "- Issues: $($_.Group.Count) total (Critical: $critical, High: $high, Medium: $medium)"
    if ($critical -gt 0 -or $high -gt 0) {
        "- **Priority**: High - Contains critical or high severity issues"
    } elseif ($medium -gt 3) {
        "- **Priority**: Medium - Multiple medium severity issues require review"
    } else {
        "- **Priority**: Low - Minor issues or good security posture"
    }
    ""
}) -join "`n")

"@

$execSummary | Out-File -FilePath $execSummaryPath -Encoding UTF8
Write-Host "✓ Executive summary saved to: $execSummaryPath" -ForegroundColor Green

# Generate detailed reports for each module
foreach ($module in $moduleFindings) {
    $moduleReportPath = Join-Path $OutputPath "$($module.Name)-Security-Report.md"
    
    $moduleReport = @"
# Security Analysis Report - $($module.Name)
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Module Summary
- **Module Name**: $($module.Name)
- **Total Issues Found**: $($module.Group.Count)
- **Critical Issues**: $(($module.Group | Where-Object Severity -eq 'Critical').Count)
- **High Issues**: $(($module.Group | Where-Object Severity -eq 'High').Count)
- **Medium Issues**: $(($module.Group | Where-Object Severity -eq 'Medium').Count)
- **Low Issues**: $(($module.Group | Where-Object Severity -eq 'Low').Count)

## Findings by Severity

"@

    # Group module findings by severity
    $severityGroups = $module.Group | Group-Object Severity | Sort-Object { @{'Critical'=5;'High'=4;'Medium'=3;'Low'=2;'Informational'=1}[$_.Name] } -Descending
    
    foreach ($group in $severityGroups) {
        $moduleReport += @"

### $($group.Name) Issues ($($group.Count))

"@
        
        foreach ($finding in $group.Group) {
            $moduleReport += @"

#### Rule: $($finding.Rule)
**Category**: $($finding.Category)  
**File**: $($finding.File)  
**Line**: $($finding.Line)  
**CVSS Score**: $($finding.CVSS)

**Code**:
``````powershell
$($finding.Code)
``````

**Description**: $($finding.Description)

**Remediation**: $($finding.Remediation)

---

"@
        }
    }
    
    $moduleReport | Out-File -FilePath $moduleReportPath -Encoding UTF8
    Write-Host "✓ Module report saved to: $moduleReportPath" -ForegroundColor Green
}

# Final summary
Write-Host "`n📊 Analysis Complete!" -ForegroundColor Cyan
Write-Host "Files Analyzed: $($psFiles.Count)" -ForegroundColor White
Write-Host "Total Issues: $($allFindings.Count)" -ForegroundColor White

if ($allFindings.Count -gt 0) {
    $allFindings | Group-Object Severity | Sort-Object { @{'Critical'=5;'High'=4;'Medium'=3;'Low'=2;'Informational'=1}[$_.Name] } -Descending | ForEach-Object {
        $color = switch ($_.Name) {
            'Critical' { 'Red' }
            'High' { 'Yellow' }
            'Medium' { 'Cyan' }
            default { 'White' }
        }
        Write-Host "$($_.Name): $($_.Count)" -ForegroundColor $color
    }
}

Write-Host "`nReports saved in: $OutputPath" -ForegroundColor Green