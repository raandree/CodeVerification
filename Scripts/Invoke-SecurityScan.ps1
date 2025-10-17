<#
.SYNOPSIS
    PowerShell Security Scanner - Main Analysis Engine
.DESCRIPTION
    Scans PowerShell code for security vulnerabilities using custom rules and PSScriptAnalyzer.
    Generates comprehensive security findings with context-aware severity assessment.
.PARAMETER Path
    Path to PowerShell files or directory to scan
.PARAMETER OutputPath
    Path where reports will be generated
.PARAMETER ModuleName
    Name of the module being scanned (for report naming)
.EXAMPLE
    .\Invoke-SecurityScan.ps1 -Path "C:\CodeVerification\source\nishang-0.7.6" -OutputPath "C:\CodeVerification\Report" -ModuleName "nishang"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $true)]
    [string]$ModuleName
)

$ErrorActionPreference = 'Continue'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load security rules
Write-Host "Loading security detection rules..." -ForegroundColor Cyan
. "$scriptRoot\..\Rules\SecurityRules.ps1"
$rules = $SecurityRules

Write-Host "Loaded $($rules.Count) security rules" -ForegroundColor Green

# Initialize findings collection
$allFindings = @()

# Get all PowerShell files
Write-Host "`nScanning for PowerShell files in: $Path" -ForegroundColor Cyan
$psFiles = Get-ChildItem -Path $Path -Include *.ps1, *.psm1, *.psd1 -Recurse -ErrorAction SilentlyContinue

Write-Host "Found $($psFiles.Count) PowerShell files to analyze" -ForegroundColor Green

# Process each file
$fileCount = 0
foreach ($file in $psFiles) {
    $fileCount++
    Write-Progress -Activity "Scanning Files" -Status "Processing $($file.Name)" -PercentComplete (($fileCount / $psFiles.Count) * 100)
    
    Write-Host "`n[$fileCount/$($psFiles.Count)] Analyzing: $($file.FullName)" -ForegroundColor Yellow
    
    try {
        # Read file content
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        
        # Parse AST
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
        
        # Check for parse errors
        if ($errors) {
            Write-Warning "Parse errors in $($file.Name): $($errors.Count) errors"
            $finding = [PSCustomObject]@{
                Rule = 'PARSE_ERROR'
                Category = 'ParseError'
                File = $file.FullName
                Line = 0
                Code = $errors[0].Message
                Description = "File contains PowerShell syntax errors: $($errors.Count) errors found"
                Remediation = "Fix syntax errors before security analysis"
                Severity = 'High'
                CVSS = 0
            }
            $allFindings += $finding
        }
        
        # Apply custom security rules
        foreach ($rule in $rules) {
            # Pattern-based detection (regex)
            if ($rule.Pattern) {
                try {
                    $matches = [regex]::Matches($content, $rule.Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                    
                    if ($matches.Count -gt 0) {
                        foreach ($match in $matches) {
                            # Get line number
                            $lineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
                            $line = ($content -split "`n")[$lineNumber - 1]
                            
                            $finding = [PSCustomObject]@{
                                Rule = "$($rule.Id) - $($rule.Name)"
                                Category = $rule.Category
                                File = $file.FullName
                                Line = $lineNumber
                                Code = $line.Trim()
                                Description = $rule.Description
                                Remediation = $rule.Remediation
                                Severity = $rule.Severity
                                CVSS = $rule.CVSS
                            }
                            $allFindings += $finding
                        }
                    }
                }
                catch {
                    Write-Warning "Error applying pattern rule $($rule.Id): $_"
                }
            }
            
            # AST-based detection
            if ($rule.ASTPattern -and $rule.CommandName) {
                try {
                    $commandNames = $rule.CommandName -split '\|'
                    
                    $commandAsts = $ast.FindAll({
                        param($node)
                        $node -is [System.Management.Automation.Language.CommandAst]
                    }, $true)
                    
                    foreach ($cmdAst in $commandAsts) {
                        $cmdName = $cmdAst.GetCommandName()
                        
                        if ($cmdName -and ($commandNames -contains $cmdName)) {
                            $lineNumber = $cmdAst.Extent.StartLineNumber
                            $line = $cmdAst.Extent.Text
                            
                            $finding = [PSCustomObject]@{
                                Rule = "$($rule.Id) - $($rule.Name)"
                                Category = $rule.Category
                                File = $file.FullName
                                Line = $lineNumber
                                Code = $line.Trim()
                                Description = $rule.Description
                                Remediation = $rule.Remediation
                                Severity = $rule.Severity
                                CVSS = $rule.CVSS
                            }
                            $allFindings += $finding
                        }
                        
                        # Check aliases
                        if ($rule.Aliases) {
                            foreach ($alias in $rule.Aliases) {
                                if ($cmdName -eq $alias) {
                                    $lineNumber = $cmdAst.Extent.StartLineNumber
                                    $line = $cmdAst.Extent.Text
                                    
                                    $finding = [PSCustomObject]@{
                                        Rule = "$($rule.Id) - $($rule.Name)"
                                        Category = $rule.Category
                                        File = $file.FullName
                                        Line = $lineNumber
                                        Code = $line.Trim()
                                        Description = "$($rule.Description) (via alias '$alias')"
                                        Remediation = $rule.Remediation
                                        Severity = $rule.Severity
                                        CVSS = $rule.CVSS
                                    }
                                    $allFindings += $finding
                                }
                            }
                        }
                    }
                }
                catch {
                    Write-Warning "Error applying AST rule $($rule.Id): $_"
                }
            }
        }
    }
    catch {
        Write-Error "Failed to process $($file.Name): $_"
    }
}

Write-Progress -Activity "Scanning Files" -Completed

# Generate statistics
Write-Host "`n=== Scan Complete ===" -ForegroundColor Cyan
Write-Host "Total findings: $($allFindings.Count)" -ForegroundColor Yellow

$severityCounts = $allFindings | Group-Object Severity | Select-Object Name, Count
Write-Host "`nFindings by Severity:" -ForegroundColor Cyan
foreach ($sev in $severityCounts) {
    $color = switch ($sev.Name) {
        'Critical' { 'Red' }
        'High' { 'DarkRed' }
        'Medium' { 'Yellow' }
        'Low' { 'Gray' }
        default { 'White' }
    }
    Write-Host "  $($sev.Name): $($sev.Count)" -ForegroundColor $color
}

$categoryCounts = $allFindings | Group-Object Category | Sort-Object Count -Descending | Select-Object Name, Count
Write-Host "`nTop Categories:" -ForegroundColor Cyan
foreach ($cat in $categoryCounts | Select-Object -First 10) {
    Write-Host "  $($cat.Name): $($cat.Count)" -ForegroundColor Gray
}

# Export findings
$findingsFile = Join-Path $OutputPath "$ModuleName`_Findings.xml"
$allFindings | Export-Clixml -Path $findingsFile
Write-Host "`nFindings exported to: $findingsFile" -ForegroundColor Green

# Return findings for report generation
return $allFindings
