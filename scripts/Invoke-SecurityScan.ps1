<#
.SYNOPSIS
    Security scanner for PowerShell DSC modules
.DESCRIPTION
    Performs static analysis of PowerShell files to detect security vulnerabilities,
    malicious patterns, and compliance issues.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SourcePath = "$PSScriptRoot\..\source",
    
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = "$PSScriptRoot\..\security-reports",
    
    [Parameter(Mandatory=$false)]
    [string]$ModuleName
)

# Load detection rules
$rulesPath = "$PSScriptRoot\detection-rules.psd1"
$detectionRules = Import-PowerShellDataFile -Path $rulesPath

# Initialize findings collection
$allFindings = @()

# Helper function to calculate string entropy
function Get-StringEntropy {
    param([string]$String)
    
    if ([string]::IsNullOrEmpty($String)) { return 0 }
    
    $charFrequency = @{}
    foreach ($char in $String.ToCharArray()) {
        $charFrequency[$char] = ($charFrequency[$char] ?? 0) + 1
    }
    
    $entropy = 0
    foreach ($count in $charFrequency.Values) {
        $probability = $count / $String.Length
        $entropy -= $probability * [Math]::Log($probability, 2)
    }
    
    return $entropy
}

# Helper function to analyze file
function Invoke-FileAnalysis {
    param(
        [string]$FilePath,
        [array]$Rules
    )
    
    $findings = @()
    
    Write-Verbose "Analyzing: $FilePath"
    
    try {
        # Read file content
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        # Parse AST
        $tokens = @()
        $errors = @()
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $FilePath,
            [ref]$tokens,
            [ref]$errors
        )
        
        # Check for parsing errors
        if ($errors.Count -gt 0) {
            $findings += @{
                Severity = 'Medium'
                Rule = 'PARSE_ERROR'
                Description = "File contains $($errors.Count) parsing error(s)"
                File = $FilePath
                Line = $errors[0].Extent.StartLineNumber
                Details = $errors[0].Message
            }
        }
        
        # Apply regex-based rules
        foreach ($rule in $Rules | Where-Object { $_.RegexPattern }) {
            if ($content -match $rule.RegexPattern) {
                $findings += @{
                    Severity = $rule.Severity
                    Rule = $rule.Id
                    Name = $rule.Name
                    Category = $rule.Category
                    Description = $rule.Description
                    File = $FilePath
                    Line = 'Multiple'
                    Remediation = $rule.Remediation
                    CVSS = $rule.CVSS
                }
            }
        }
        
        # Apply AST-based rules for Invoke-Expression
        $invokeExpressions = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.CommandAst] -and
            $node.GetCommandName() -eq 'Invoke-Expression'
        }, $true)
        
        foreach ($invExp in $invokeExpressions) {
            $rule = $Rules | Where-Object { $_.Id -eq 'PS001' } | Select-Object -First 1
            if ($rule) {
                $findings += @{
                    Severity = $rule.Severity
                    Rule = $rule.Id
                    Name = $rule.Name
                    Category = $rule.Category
                    Description = $rule.Description
                    File = $FilePath
                    Line = $invExp.Extent.StartLineNumber
                    Context = $invExp.Extent.Text
                    Remediation = $rule.Remediation
                    CVSS = $rule.CVSS
                }
            }
        }
        
        # Entropy analysis for high-entropy strings (potential obfuscation)
        $stringLiterals = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.StringConstantExpressionAst]
        }, $true)
        
        foreach ($str in $stringLiterals) {
            $strValue = $str.Value
            if ($strValue.Length -gt 100) {
                $entropy = Get-StringEntropy -String $strValue
                if ($entropy -gt 4.5) {
                    $findings += @{
                        Severity = 'High'
                        Rule = 'PS012'
                        Name = 'High Entropy String Detected'
                        Category = 'Obfuscation'
                        Description = "String with entropy $([Math]::Round($entropy, 2)) detected (possible obfuscation or encoding)"
                        File = $FilePath
                        Line = $str.Extent.StartLineNumber
                        Context = $strValue.Substring(0, [Math]::Min(100, $strValue.Length)) + "..."
                        Remediation = 'Decode or explain the purpose of this encoded content'
                        CVSS = 7.0
                    }
                }
            }
        }
        
    }
    catch {
        Write-Warning "Error analyzing ${FilePath}: $($_.Exception.Message)"
        $findings += @{
            Severity = 'Low'
            Rule = 'ERROR'
            Description = "Analysis error: $($_.Exception.Message)"
            File = $FilePath
            Line = 0
        }
    }
    
    return $findings
}

# Main execution
Write-Host "`n=== PowerShell Module Security Scanner ===" -ForegroundColor Cyan
Write-Host "Source Path: $SourcePath" -ForegroundColor Gray
Write-Host "Report Path: $ReportPath" -ForegroundColor Gray
Write-Host ""

# Discover all PowerShell files
$psFiles = Get-ChildItem -Path $SourcePath -Recurse -Include "*.ps1","*.psm1","*.psd1" -File

Write-Host "Found $($psFiles.Count) PowerShell files to analyze" -ForegroundColor Cyan
Write-Host "Loading $($detectionRules.Rules.Count) detection rules`n" -ForegroundColor Cyan

# Analyze each file
$fileCount = 0
foreach ($file in $psFiles) {
    $fileCount++
    Write-Progress -Activity "Scanning files" -Status "Processing $($file.Name)" -PercentComplete (($fileCount / $psFiles.Count) * 100)
    
    $findings = Invoke-FileAnalysis -FilePath $file.FullName -Rules $detectionRules.Rules
    
    if ($findings.Count -gt 0) {
        $allFindings += $findings
        Write-Host "[!] $($findings.Count) finding(s) in: $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Progress -Activity "Scanning files" -Completed

# Summary statistics
$criticalCount = ($allFindings | Where-Object { $_.Severity -eq 'Critical' }).Count
$highCount = ($allFindings | Where-Object { $_.Severity -eq 'High' }).Count
$mediumCount = ($allFindings | Where-Object { $_.Severity -eq 'Medium' }).Count
$lowCount = ($allFindings | Where-Object { $_.Severity -eq 'Low' }).Count

Write-Host "`n=== Scan Summary ===" -ForegroundColor Cyan
Write-Host "Total Findings: $($allFindings.Count)" -ForegroundColor White
Write-Host "  Critical: $criticalCount" -ForegroundColor Red
Write-Host "  High:     $highCount" -ForegroundColor DarkRed
Write-Host "  Medium:   $mediumCount" -ForegroundColor Yellow
Write-Host "  Low:      $lowCount" -ForegroundColor Gray

# Calculate risk score
$riskScore = ($criticalCount * 10) + ($highCount * 5) + ($mediumCount * 2) + ($lowCount * 0.5)
Write-Host "`nOverall Risk Score: $riskScore" -ForegroundColor $(if($riskScore -gt 50){"Red"}elseif($riskScore -gt 20){"Yellow"}else{"Green"})

# Generate report
$reportFile = Join-Path $ReportPath "security-scan-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$report = @"
# PowerShell Module Security Scan Report
**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Files Scanned:** $($psFiles.Count)
**Total Findings:** $($allFindings.Count)

## Executive Summary

- **Critical Findings:** $criticalCount
- **High Findings:** $highCount
- **Medium Findings:** $mediumCount
- **Low Findings:** $lowCount
- **Overall Risk Score:** $riskScore

## Risk Assessment

$(if($criticalCount -gt 0){"**⛔ DEPLOYMENT BLOCKED:** Critical security issues detected. DO NOT deploy until resolved."}
elseif($highCount -gt 3){"**⚠️ HIGH RISK:** Multiple high-severity issues require immediate attention."}
elseif($highCount -gt 0 -or $mediumCount -gt 5){"**⚠️ MODERATE RISK:** Security review required before deployment."}
else{"**✅ LOW RISK:** No critical issues detected. Review medium/low findings for best practices."})

## Detailed Findings

"@

# Group findings by severity
foreach ($severity in @('Critical', 'High', 'Medium', 'Low')) {
    $severityFindings = $allFindings | Where-Object { $_.Severity -eq $severity }
    if ($severityFindings.Count -gt 0) {
        $report += "`n### $severity Severity ($($severityFindings.Count) findings)`n`n"
        
        foreach ($finding in $severityFindings) {
            $report += @"
#### $($finding.Name ?? $finding.Rule)
- **Rule:** $($finding.Rule)
- **Category:** $($finding.Category ?? 'N/A')
- **File:** ``$($finding.File.Replace($SourcePath, '.'))``
- **Line:** $($finding.Line)
- **Description:** $($finding.Description)
$(if($finding.Context){"- **Code:** ````$($finding.Context)````"})
- **Remediation:** $($finding.Remediation ?? 'Review and validate this code')
$(if($finding.CVSS){"- **CVSS Score:** $($finding.CVSS)"})

"@
        }
    }
}

# Save report
$report | Out-File -FilePath $reportFile -Encoding UTF8
Write-Host "`nReport saved to: $reportFile" -ForegroundColor Green

# Return findings for pipeline
return $allFindings
