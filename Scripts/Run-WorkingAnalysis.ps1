# Working Security Analysis Script
param(
    [string]$SourcePath = ".\source",
    [string]$OutputPath = ".\Report"
)

Write-Host "PowerShell Security Analysis" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Get all PowerShell files
$psFiles = Get-ChildItem -Path $SourcePath -Filter "*.ps*" -Recurse | Where-Object { $_.Extension -match "\.(ps1|psm1|psd1)$" }
Write-Host "Found $($psFiles.Count) PowerShell files to scan" -ForegroundColor Green

# Initialize findings
$allFindings = @()

# Run analysis
Write-Host "Running security analysis..." -ForegroundColor Yellow

foreach ($file in $psFiles) {
    try {
        $lines = Get-Content $file.FullName -ErrorAction SilentlyContinue
        if (-not $lines) { continue }
        
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
                    Description = "Use of Invoke-Expression detected"
                    Remediation = "Replace with safer alternatives"
                    Severity = "High"
                    CVSS = 7.5
                }
            }
            
            # PS005 - Hardcoded Credentials (simple check)
            if ($line -match "password\s*=\s*[`"'].{8,}[`"']" -and $line -notmatch "password.*\*|example|placeholder") {
                $allFindings += [PSCustomObject]@{
                    Rule = "PS005"
                    Category = "CredentialSecurity"
                    File = $file.FullName
                    Line = $lineNumber
                    Code = $line.Trim()
                    Description = "Potential hardcoded credential detected"
                    Remediation = "Use secure credential storage"
                    Severity = "Critical"
                    CVSS = 9.8
                }
            }
            
            # PS016 - Insecure HTTP (filtered)
            if ($line -match "http://" -and $line -notmatch "^\s*#|^\s*\*|e\.g|example|comment") {
                $allFindings += [PSCustomObject]@{
                    Rule = "PS016"
                    Category = "NetworkSecurity"
                    File = $file.FullName
                    Line = $lineNumber
                    Code = $line.Trim()
                    Description = "Use of insecure HTTP protocol"
                    Remediation = "Use HTTPS instead"
                    Severity = "Medium"
                    CVSS = 5.2
                }
            }
            
            # PS019 - Weak Crypto
            if ($line -match "\b(MD5|SHA1|DES)\b" -and $line -notmatch "^\s*#") {
                $allFindings += [PSCustomObject]@{
                    Rule = "PS019"
                    Category = "Cryptography"
                    File = $file.FullName
                    Line = $lineNumber
                    Code = $line.Trim()
                    Description = "Use of weak cryptographic algorithm"
                    Remediation = "Use stronger algorithms like SHA-256"
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

# Group findings by module
$moduleFindings = $allFindings | Group-Object { 
    $relativePath = $_.File.Replace((Resolve-Path $SourcePath).Path, "").Trim('\')
    $parts = $relativePath.Split('\')
    if ($parts.Count -gt 0) { $parts[0] } else { "Unknown" }
}

# Executive Summary
$execSummaryPath = Join-Path $OutputPath "Executive-Summary.md"
$execSummary = @"
# Executive Security Summary
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Overall Security Posture
- **Total PowerShell Files Analyzed**: $($psFiles.Count)
- **Total Security Issues Identified**: $($allFindings.Count)
- **Modules Analyzed**: $($moduleFindings.Count)

## Risk Distribution
$((($allFindings | Group-Object Severity | Sort-Object Name | ForEach-Object { "- **$($_.Name)**: $($_.Count) issues" }) -join "`n"))

## Modules Analysis
$((($moduleFindings | ForEach-Object { "- **$($_.Name)**: $($_.Group.Count) issues" }) -join "`n"))

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

"@

$execSummary | Out-File -FilePath $execSummaryPath -Encoding UTF8
Write-Host "Executive summary saved to: $execSummaryPath" -ForegroundColor Green

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

## Detailed Findings

"@

    foreach ($finding in $module.Group | Sort-Object Severity, Rule) {
        $moduleReport += @"

### Rule: $($finding.Rule)
**Category**: $($finding.Category)  
**File**: $($finding.File)  
- **Line**: $($finding.Line)  
  **Code**: $($finding.Code)  

**Description**: $($finding.Description)  
**Remediation**: $($finding.Remediation)  
**CVSS Score**: $($finding.CVSS)

---

"@
    }
    
    $moduleReport | Out-File -FilePath $moduleReportPath -Encoding UTF8
    Write-Host "Module report saved to: $moduleReportPath" -ForegroundColor Green
}

# Summary
Write-Host "`nAnalysis Complete!" -ForegroundColor Cyan
Write-Host "Files Analyzed: $($psFiles.Count)" -ForegroundColor White
Write-Host "Total Issues: $($allFindings.Count)" -ForegroundColor White

if ($allFindings.Count -gt 0) {
    $allFindings | Group-Object Severity | Sort-Object Name | ForEach-Object {
        Write-Host "$($_.Name): $($_.Count)" -ForegroundColor Yellow
    }
}

Write-Host "Reports saved in: $OutputPath" -ForegroundColor Green