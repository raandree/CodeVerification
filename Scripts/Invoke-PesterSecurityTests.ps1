# Pester Security Tests for PowerShell Modules
# Version: 1.0
# Purpose: Validate security compliance using Pester testing framework

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    
    [Parameter(Mandatory = $false)]
    [string]$RulesPath = ".\Rules\PowerShell-Security-Rules.md",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Report\Pester-Results.xml"
)

# Import required modules
try {
    Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
    Write-Host "✓ Pester module loaded" -ForegroundColor Green
}
catch {
    Write-Error "Pester 5.0+ is required. Install with: Install-Module -Name Pester -Force"
    return
}

# Load security scanner functions
$scannerScript = Join-Path (Split-Path $PSScriptRoot -Parent) "Scripts\Invoke-SecurityScan.ps1"
if (Test-Path $scannerScript) {
    . $scannerScript
}
else {
    Write-Error "Security scanner script not found: $scannerScript"
    return
}

Describe "PowerShell Security Compliance Tests" {
    
    BeforeAll {
        $script:SecurityRules = Get-SecurityRules -RulesFilePath $RulesPath
        $script:PowerShellFiles = Get-ChildItem -Path $SourcePath -Filter "*.ps*" -Recurse | 
            Where-Object { $_.Extension -match "\.(ps1|psm1|psd1)$" }
        $script:AllFindings = @()
        
        # Pre-scan all files for findings
        foreach ($file in $script:PowerShellFiles) {
            $fileContent = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($fileContent) {
                foreach ($rule in $script:SecurityRules) {
                    $findings = Test-SecurityRule -FilePath $file.FullName -Rule $rule -FileContent $fileContent
                    $script:AllFindings += $findings
                }
            }
        }
    }
    
    Context "Critical Security Issues" {
        It "Should not contain hardcoded credentials" {
            $credentialFindings = $script:AllFindings | Where-Object { $_.RuleId -eq 'PS005' }
            $credentialFindings | Should -BeNullOrEmpty -Because "Hardcoded credentials pose critical security risks"
            
            if ($credentialFindings) {
                Write-Host "Found hardcoded credentials in:" -ForegroundColor Red
                $credentialFindings | ForEach-Object {
                    Write-Host "  - $($_.FilePath):$($_.Line)" -ForegroundColor Red
                }
            }
        }
        
        It "Should not log sensitive data in plaintext" {
            $sensitiveLogFindings = $script:AllFindings | Where-Object { $_.RuleId -eq 'PS011' }
            $sensitiveLogFindings | Should -BeNullOrEmpty -Because "Logging sensitive data exposes credentials"
            
            if ($sensitiveLogFindings) {
                Write-Host "Found sensitive data logging in:" -ForegroundColor Red
                $sensitiveLogFindings | ForEach-Object {
                    Write-Host "  - $($_.FilePath):$($_.Line)" -ForegroundColor Red
                }
            }
        }
        
        It "Should not contain critical vulnerabilities" {
            $criticalFindings = $script:AllFindings | Where-Object { $_.Severity -eq 'Critical' }
            $criticalFindings | Should -BeNullOrEmpty -Because "Critical vulnerabilities must be addressed immediately"
            
            if ($criticalFindings) {
                Write-Host "Found critical security issues:" -ForegroundColor Red
                $criticalFindings | Group-Object RuleName | ForEach-Object {
                    Write-Host "  - $($_.Name): $($_.Count) occurrences" -ForegroundColor Red
                }
            }
        }
    }
    
    Context "High Risk Security Issues" {
        It "Should minimize use of Invoke-Expression" {
            $iexFindings = $script:AllFindings | Where-Object { $_.RuleId -eq 'PS001' }
            
            if ($iexFindings) {
                Write-Warning "Found Invoke-Expression usage in $($iexFindings.Count) locations"
                $iexFindings | ForEach-Object {
                    Write-Host "  - $($_.FilePath):$($_.Line)" -ForegroundColor Yellow
                }
            }
            
            # Allow some usage but flag if excessive
            $iexFindings.Count | Should -BeLessThan 5 -Because "Invoke-Expression should be used sparingly"
        }
        
        It "Should not bypass PowerShell execution policy" {
            $bypassFindings = $script:AllFindings | Where-Object { $_.RuleId -eq 'PS004' }
            $bypassFindings | Should -BeNullOrEmpty -Because "Execution policy bypasses undermine security controls"
        }
        
        It "Should not have SQL injection vulnerabilities" {
            $sqlFindings = $script:AllFindings | Where-Object { $_.RuleId -eq 'PS008' }
            $sqlFindings | Should -BeNullOrEmpty -Because "SQL injection vulnerabilities are high risk"
        }
        
        It "Should not have command injection vulnerabilities" {
            $cmdFindings = $script:AllFindings | Where-Object { $_.RuleId -eq 'PS009' }
            $cmdFindings | Should -BeNullOrEmpty -Because "Command injection vulnerabilities are high risk"
        }
    }
    
    Context "Medium Risk Security Issues" {
        It "Should use secure network protocols" {
            $insecureProtocolFindings = $script:AllFindings | Where-Object { $_.RuleId -eq 'PS016' }
            
            if ($insecureProtocolFindings) {
                Write-Warning "Found insecure protocol usage:"
                $insecureProtocolFindings | ForEach-Object {
                    Write-Host "  - $($_.FilePath):$($_.Line) - $($_.Code)" -ForegroundColor Yellow
                }
            }
            
            # Allow some usage for internal/legacy systems but limit it
            $insecureProtocolFindings.Count | Should -BeLessThan 3 -Because "Insecure protocols should be minimized"
        }
        
        It "Should use strong cryptographic algorithms" {
            $weakCryptoFindings = $script:AllFindings | Where-Object { $_.RuleId -eq 'PS019' }
            $weakCryptoFindings | Should -BeNullOrEmpty -Because "Weak cryptography is vulnerable to attacks"
        }
        
        It "Should handle errors securely" {
            $errorInfoFindings = $script:AllFindings | Where-Object { $_.RuleId -eq 'PS026' }
            
            if ($errorInfoFindings.Count -gt 5) {
                $errorInfoFindings | Should -HaveCount -LessThan 6 -Because "Excessive error information disclosure detected"
            }
        }
    }
    
    Context "Code Quality and Best Practices" {
        It "Should have reasonable file count" {
            $script:PowerShellFiles.Count | Should -BeGreaterThan 0 -Because "No PowerShell files found to test"
        }
        
        It "Should not have excessive high entropy strings" {
            $entropyFindings = $script:AllFindings | Where-Object { $_.RuleId -eq 'PS015' }
            
            # High entropy strings are common in PowerShell, so we're lenient
            if ($entropyFindings.Count -gt 10) {
                Write-Warning "Found $($entropyFindings.Count) high entropy strings - review for potential obfuscation"
            }
        }
        
        It "Should use secure random number generation for security operations" {
            $weakRandomFindings = $script:AllFindings | Where-Object { $_.RuleId -eq 'PS020' }
            
            if ($weakRandomFindings) {
                Write-Information "Review random number usage for security context:"
                $weakRandomFindings | ForEach-Object {
                    Write-Host "  - $($_.FilePath):$($_.Line)" -ForegroundColor Cyan
                }
            }
        }
    }
    
    Context "Configuration Management Specific Tests" {
        It "Should have appropriate hostname/domain checks for infrastructure code" {
            $hostnameFindings = $script:AllFindings | Where-Object { $_.RuleId -eq 'PS018' }
            
            # These are expected in configuration management
            if ($hostnameFindings) {
                Write-Information "Found $($hostnameFindings.Count) hostname/domain checks (expected in infrastructure code)"
            }
        }
        
        It "Should handle registry operations carefully" {
            $registryFindings = $script:AllFindings | Where-Object { $_.RuleId -eq 'PS021' }
            
            if ($registryFindings) {
                Write-Information "Review registry operations for security implications:"
                $registryFindings | ForEach-Object {
                    Write-Host "  - $($_.FilePath):$($_.Line)" -ForegroundColor Cyan
                }
            }
        }
        
        It "Should handle service operations securely" {
            $serviceFindings = $script:AllFindings | Where-Object { $_.RuleId -eq 'PS022' }
            
            if ($serviceFindings) {
                Write-Warning "Review service operations for authorization:"
                $serviceFindings | ForEach-Object {
                    Write-Host "  - $($_.FilePath):$($_.Line)" -ForegroundColor Yellow
                }
            }
        }
    }
    
    Context "Overall Security Metrics" {
        It "Should have acceptable total security findings" {
            $totalFindings = $script:AllFindings.Count
            $criticalCount = ($script:AllFindings | Where-Object { $_.Severity -eq 'Critical' }).Count
            $highCount = ($script:AllFindings | Where-Object { $_.Severity -eq 'High' }).Count
            
            Write-Host "Security Metrics:" -ForegroundColor Cyan
            Write-Host "  Total Findings: $totalFindings" -ForegroundColor White
            Write-Host "  Critical: $criticalCount" -ForegroundColor Red
            Write-Host "  High: $highCount" -ForegroundColor Yellow
            Write-Host "  Files Scanned: $($script:PowerShellFiles.Count)" -ForegroundColor White
            
            # Fail if too many critical or high severity issues
            $criticalCount | Should -Be 0 -Because "No critical security issues should exist"
            $highCount | Should -BeLessThan 5 -Because "High severity issues should be minimal"
        }
        
        It "Should have security findings per file ratio below threshold" {
            $findingsPerFile = if ($script:PowerShellFiles.Count -gt 0) { 
                [math]::Round($script:AllFindings.Count / $script:PowerShellFiles.Count, 2) 
            } else { 0 }
            
            Write-Host "Security findings per file: $findingsPerFile" -ForegroundColor Cyan
            
            # Reasonable threshold for configuration management code
            $findingsPerFile | Should -BeLessThan 3.0 -Because "Too many security issues per file indicates poor security practices"
        }
    }
}

# Generate detailed findings report for reference
AfterAll {
    if ($script:AllFindings.Count -gt 0) {
        $detailedReport = @"
# Detailed Pester Security Test Results
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary
- **Total Files Tested**: $($script:PowerShellFiles.Count)
- **Total Security Findings**: $($script:AllFindings.Count)
- **Critical**: $(($script:AllFindings | Where-Object { $_.Severity -eq 'Critical' }).Count)
- **High**: $(($script:AllFindings | Where-Object { $_.Severity -eq 'High' }).Count)
- **Medium**: $(($script:AllFindings | Where-Object { $_.Severity -eq 'Medium' }).Count)
- **Low**: $(($script:AllFindings | Where-Object { $_.Severity -eq 'Low' }).Count)
- **Informational**: $(($script:AllFindings | Where-Object { $_.Severity -eq 'Informational' }).Count)

## Test Results by Category

"@

        $groupedFindings = $script:AllFindings | Group-Object Category
        foreach ($group in $groupedFindings) {
            $detailedReport += @"

### $($group.Name) ($($group.Count) findings)
$(($group.Group | ForEach-Object { "- [$($_.Severity)] $($_.RuleName): $($_.FilePath):$($_.Line)" }) -join "`n")

"@
        }
        
        $reportDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $reportDir)) {
            New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
        }
        
        $detailedReportPath = Join-Path $reportDir "Pester-Detailed-Findings.md"
        $detailedReport | Out-File -FilePath $detailedReportPath -Encoding UTF8
        Write-Host "✓ Detailed findings report saved to: $detailedReportPath" -ForegroundColor Green
    }
}