# Simple Security Scanner Test
# Purpose: Basic security scanning to test functionality

param(
    [string]$SourcePath = ".\source"
)

Write-Host "PowerShell Security Scanner Test" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Check if source path exists
if (-not (Test-Path $SourcePath)) {
    Write-Error "Source path not found: $SourcePath"
    exit 1
}

# Get PowerShell files
$psFiles = Get-ChildItem -Path $SourcePath -Filter "*.ps*" -Recurse | Where-Object { $_.Extension -match "\.(ps1|psm1|psd1)$" }
Write-Host "Found $($psFiles.Count) PowerShell files to scan" -ForegroundColor Green

# Create basic report directory
$reportDir = ".\Report"
if (-not (Test-Path $reportDir)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

# Basic security checks
$findings = @()

foreach ($file in $psFiles) {
    Write-Host "Scanning: $($file.Name)" -ForegroundColor Gray
    
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        
        # Simple pattern checks
        $lineNumber = 0
        $lines = Get-Content $file.FullName
        
        foreach ($line in $lines) {
            $lineNumber++
            
            # Check for Invoke-Expression
            if ($line -match "Invoke-Expression|iex\s") {
                $findings += [PSCustomObject]@{
                    Rule = "PS001"
                    Category = "CodeExecution"
                    File = $file.FullName
                    Line = $lineNumber
                    Code = $line.Trim()
                    Description = "Use of Invoke-Expression detected"
                    Remediation = "Replace with safer alternatives"
                    Severity = "High"
                }
            }
            
            # Check for hardcoded passwords (basic)
            if ($line -match "password\s*[:=]\s*[`"'][^`"'*]{6,}[`"']") {
                $findings += [PSCustomObject]@{
                    Rule = "PS005"
                    Category = "CredentialSecurity"
                    File = $file.FullName
                    Line = $lineNumber
                    Code = $line.Trim()
                    Description = "Potential hardcoded credential detected"
                    Remediation = "Use secure credential storage"
                    Severity = "Critical"
                }
            }
            
            # Check for insecure protocols
            if ($line -match "http://") {
                $findings += [PSCustomObject]@{
                    Rule = "PS016"
                    Category = "NetworkSecurity"
                    File = $file.FullName
                    Line = $lineNumber
                    Code = $line.Trim()
                    Description = "Insecure HTTP protocol detected"
                    Remediation = "Use HTTPS instead"
                    Severity = "Medium"
                }
            }
        }
    }
    catch {
        Write-Warning "Error scanning $($file.FullName): $($_.Exception.Message)"
    }
}

# Generate simple report
$reportPath = Join-Path $reportDir "Basic-Security-Report.md"
$report = @"
# Basic Security Analysis Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary
- **Files Scanned**: $($psFiles.Count)
- **Issues Found**: $($findings.Count)
- **Critical**: $(($findings | Where-Object Severity -eq 'Critical').Count)
- **High**: $(($findings | Where-Object Severity -eq 'High').Count)
- **Medium**: $(($findings | Where-Object Severity -eq 'Medium').Count)

## Findings

"@

if ($findings.Count -gt 0) {
    foreach ($finding in $findings) {
        $report += @"

### $($finding.Rule) - $($finding.Description)
**Category**: $($finding.Category)  
**Severity**: $($finding.Severity)  
**File**: $($finding.File)  
**Line**: $($finding.Line)  

**Code**:
``````
$($finding.Code)
``````

**Remediation**: $($finding.Remediation)

---

"@
    }
}
else {
    $report += "`nNo security issues detected in the scanned files.`n"
}

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "Report saved to: $reportPath" -ForegroundColor Green

Write-Host "`nScan Summary:" -ForegroundColor Cyan
Write-Host "  Files: $($psFiles.Count)" -ForegroundColor White
Write-Host "  Issues: $($findings.Count)" -ForegroundColor White
if ($findings.Count -gt 0) {
    $findings | Group-Object Severity | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor White
    }
}

Write-Host "`nBasic security scan completed!" -ForegroundColor Green