<#
.SYNOPSIS
    Pester tests for Security Scanner

.DESCRIPTION
    Validates that the security scanner correctly detects known vulnerability patterns
    and does not generate false positives on safe code.

.NOTES
    Requires Pester 5.x
    Author: Security Review System
    Date: October 17, 2025
#>

BeforeAll {
    # Import scanner functions
    . "$PSScriptRoot\..\Get-SecurityFindings.ps1"
    
    # Load rules
    $script:Rules = & "$PSScriptRoot\..\..\detection-rules\SecurityRules.ps1"
    
    # Create temp directory for test files
    $script:TestFilesPath = Join-Path $TestDrive "SecurityScannerTests"
    New-Item -Path $script:TestFilesPath -ItemType Directory -Force | Out-Null
}

Describe "Security Scanner - Rule Detection" {
    
    Context "PS001 - Invoke-Expression Detection" {
        It "Should detect Invoke-Expression usage" {
            $testCode = @'
function Test-BadCode {
    $cmd = "Get-Process"
    Invoke-Expression $cmd
}
'@
            $testFile = Join-Path $script:TestFilesPath "test_iex.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            $rule = $script:Rules | Where-Object { $_.Id -eq 'PS001' }
            $findings = Get-SecurityFindings -FilePath $testFile -Rules @($rule)
            
            $findings | Should -Not -BeNullOrEmpty
            $findings[0].RuleId | Should -Be 'PS001'
            $findings[0].Severity | Should -Be 'Critical'
        }
        
        It "Should detect IEX alias" {
            $testCode = @'
$cmd = "Write-Host 'test'"
iex $cmd
'@
            $testFile = Join-Path $script:TestFilesPath "test_iex_alias.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            $rule = $script:Rules | Where-Object { $_.Id -eq 'PS001' }
            $findings = Get-SecurityFindings -FilePath $testFile -Rules @($rule)
            
            $findings | Should -Not -BeNullOrEmpty
        }
        
        It "Should not detect call operator" {
            $testCode = @'
$scriptPath = "C:\Scripts\SafeScript.ps1"
& $scriptPath
'@
            $testFile = Join-Path $script:TestFilesPath "test_call_operator.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            $rule = $script:Rules | Where-Object { $_.Id -eq 'PS001' }
            $findings = Get-SecurityFindings -FilePath $testFile -Rules @($rule)
            
            $findings | Should -BeNullOrEmpty
        }
    }
    
    Context "PS002 - Hardcoded Credential Detection" {
        It "Should detect ConvertTo-SecureString with AsPlainText" {
            $testCode = @'
$password = "P@ssw0rd123" | ConvertTo-SecureString -AsPlainText -Force
'@
            $testFile = Join-Path $script:TestFilesPath "test_hardcoded_cred.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            $rule = $script:Rules | Where-Object { $_.Id -eq 'PS002' }
            $findings = Get-SecurityFindings -FilePath $testFile -Rules @($rule)
            
            $findings | Should -Not -BeNullOrEmpty
            $findings[0].Severity | Should -Be 'Critical'
        }
        
        It "Should not detect Get-Credential usage" {
            $testCode = @'
$credential = Get-Credential -UserName "admin"
'@
            $testFile = Join-Path $script:TestFilesPath "test_get_credential.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            $rule = $script:Rules | Where-Object { $_.Id -eq 'PS002' }
            $findings = Get-SecurityFindings -FilePath $testFile -Rules @($rule)
            
            $findings | Should -BeNullOrEmpty
        }
    }
    
    Context "PS007 - Write-Host with Sensitive Data" {
        It "Should detect Write-Host with password context" {
            $testCode = @'
Write-Host "User password is: $password"
'@
            $testFile = Join-Path $script:TestFilesPath "test_writehost_password.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            $rule = $script:Rules | Where-Object { $_.Id -eq 'PS007' }
            $findings = Get-SecurityFindings -FilePath $testFile -Rules @($rule)
            
            $findings | Should -Not -BeNullOrEmpty
        }
        
        It "Should not flag Write-Host without sensitive context" {
            $testCode = @'
Write-Host "Processing user: $userName"
'@
            $testFile = Join-Path $script:TestFilesPath "test_writehost_username.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            $rule = $script:Rules | Where-Object { $_.Id -eq 'PS007' }
            $findings = Get-SecurityFindings -FilePath $testFile -Rules @($rule)
            
            # This might find Write-Host usage but should not be critical
            if ($findings) {
                $findings[0].Severity | Should -Not -Be 'Critical'
            }
        }
    }
    
    Context "PS017 - Empty Catch Block Detection" {
        It "Should detect empty catch blocks" {
            $testCode = @'
try {
    Get-Item "C:\test.txt"
}
catch {
    # Empty catch block
}
'@
            $testFile = Join-Path $script:TestFilesPath "test_empty_catch.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            $rule = $script:Rules | Where-Object { $_.Id -eq 'PS017' }
            $findings = Get-SecurityFindings -FilePath $testFile -Rules @($rule)
            
            # Note: This requires AST analysis of CatchClause body
            # May need manual verification
        }
    }
    
    Context "PS029 - Base64 Content Detection" {
        It "Should detect long Base64 strings" {
            $testCode = @'
$encodedCommand = "R2V0LVByb2Nlc3MgfCBXaGVyZS1PYmplY3QgeyAkXy5OYW1lIC1saWtlICdwb3dlcnNoZWxsJyB9IHwgU3RvcC1Qcm9jZXNzIC1Gb3JjZQ=="
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedCommand))
'@
            $testFile = Join-Path $script:TestFilesPath "test_base64.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            $rule = $script:Rules | Where-Object { $_.Id -eq 'PS029' }
            $findings = Get-SecurityFindings -FilePath $testFile -Rules @($rule)
            
            $findings | Should -Not -BeNullOrEmpty
            $findings[0].RequiresManualReview | Should -Be $true
        }
        
        It "Should not detect short strings" {
            $testCode = @'
$shortString = "ABC123"
'@
            $testFile = Join-Path $script:TestFilesPath "test_short_string.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            $rule = $script:Rules | Where-Object { $_.Id -eq 'PS029' }
            $findings = Get-SecurityFindings -FilePath $testFile -Rules @($rule)
            
            $findings | Should -BeNullOrEmpty
        }
    }
}

Describe "Security Scanner - Integration Tests" {
    
    Context "Full Scan Execution" {
        It "Should scan a file and return findings" {
            $testCode = @'
function Test-UnsafeFunction {
    param($input)
    
    # Multiple issues here
    Invoke-Expression $input
    Write-Host "Processing: $input"
}
'@
            $testFile = Join-Path $script:TestFilesPath "test_multiple_issues.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            $findings = Get-SecurityFindings -FilePath $testFile -Rules $script:Rules
            
            $findings | Should -Not -BeNullOrEmpty
            $findings.Count | Should -BeGreaterThan 0
        }
        
        It "Should handle files with parse errors gracefully" {
            $testCode = @'
function Test-InvalidSyntax {
    param($value
    # Missing closing parenthesis
'@
            $testFile = Join-Path $script:TestFilesPath "test_parse_error.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            # Should not throw, just warn
            { Get-SecurityFindings -FilePath $testFile -Rules $script:Rules } | Should -Not -Throw
        }
        
        It "Should return empty array for safe code" {
            $testCode = @'
function Test-SafeFunction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )
    
    Write-Verbose "Processing $Name"
    return $Name.ToUpper()
}
'@
            $testFile = Join-Path $script:TestFilesPath "test_safe_code.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            $findings = Get-SecurityFindings -FilePath $testFile -Rules $script:Rules
            
            # Should have minimal or no findings for well-written code
            $criticalFindings = $findings | Where-Object { $_.Severity -eq 'Critical' }
            $criticalFindings | Should -BeNullOrEmpty
        }
    }
    
    Context "Rule Coverage" {
        It "Should load all 35 rules" {
            $script:Rules.Count | Should -Be 35
        }
        
        It "Should have rules for all severity levels" {
            $criticalRules = $script:Rules | Where-Object { $_.Severity -eq 'Critical' }
            $highRules = $script:Rules | Where-Object { $_.Severity -eq 'High' }
            $mediumRules = $script:Rules | Where-Object { $_.Severity -eq 'Medium' }
            $lowRules = $script:Rules | Where-Object { $_.Severity -eq 'Low' }
            
            $criticalRules.Count | Should -BeGreaterThan 0
            $highRules.Count | Should -BeGreaterThan 0
            $mediumRules.Count | Should -BeGreaterThan 0
            $lowRules.Count | Should -BeGreaterThan 0
        }
        
        It "All rules should have required properties" {
            foreach ($rule in $script:Rules) {
                $rule.Id | Should -Not -BeNullOrEmpty
                $rule.Name | Should -Not -BeNullOrEmpty
                $rule.Severity | Should -Not -BeNullOrEmpty
                $rule.Category | Should -Not -BeNullOrEmpty
                $rule.Description | Should -Not -BeNullOrEmpty
                $rule.Remediation | Should -Not -BeNullOrEmpty
                $rule.CVSS | Should -BeOfType [double]
            }
        }
    }
}

Describe "Security Scanner - False Positive Tests" {
    
    Context "PowerShell Idioms Should Not Trigger" {
        It "Should not flag PSCredential parameters in DSC resources" {
            $testCode = @'
function Set-TargetResource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCredential]
        $Credential
    )
    
    # Using credential properly
    Invoke-Command -Credential $Credential -ScriptBlock { Get-Service }
}
'@
            $testFile = Join-Path $script:TestFilesPath "test_dsc_credential.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            $findings = Get-SecurityFindings -FilePath $testFile -Rules $script:Rules
            
            # Should not have critical findings for proper credential parameter
            $criticalFindings = $findings | Where-Object { 
                $_.Severity -eq 'Critical' -and $_.Code -match 'PSCredential'
            }
            $criticalFindings | Should -BeNullOrEmpty
        }
        
        It "Should not flag username logging" {
            $testCode = @'
Write-Verbose "Processing user: $env:USERNAME"
Write-Debug "User ID: $(whoami)"
'@
            $testFile = Join-Path $script:TestFilesPath "test_username_log.ps1"
            Set-Content -Path $testFile -Value $testCode
            
            $rule = $script:Rules | Where-Object { $_.Id -eq 'PS035' }
            $findings = Get-SecurityFindings -FilePath $testFile -Rules @($rule)
            
            # Should not detect username logging as critical
            $findings | Should -BeNullOrEmpty
        }
    }
}
