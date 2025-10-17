# Enhanced PSScriptAnalyzer Integration Script
# This script provides comprehensive integration with PSScriptAnalyzer for PowerShell security analysis

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath = ".\source",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Report",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Critical", "High", "Medium", "Low", "Informational")]
    [string]$MinimumSeverity = "Informational",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeSuppressions,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [string[]]$CustomRulePaths = @()
)

# Ensure PSScriptAnalyzer is available
function Test-PSScriptAnalyzerAvailability {
    try {
        Import-Module PSScriptAnalyzer -Force -ErrorAction Stop
        Write-Host "✅ PSScriptAnalyzer module loaded successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Warning "⚠️ PSScriptAnalyzer module not found. Installing..."
        try {
            Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
            Import-Module PSScriptAnalyzer -Force
            Write-Host "✅ PSScriptAnalyzer installed and loaded successfully" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Error "❌ Failed to install PSScriptAnalyzer: $_"
            return $false
        }
    }
}

# Enhanced PSScriptAnalyzer analysis with custom rules
function Invoke-EnhancedPSScriptAnalyzer {
    param(
        [string]$Path,
        [string]$Severity,
        [string[]]$CustomRules,
        [bool]$IncludeSuppressions
    )
    
    Write-Host "🔍 Starting Enhanced PSScriptAnalyzer Analysis..." -ForegroundColor Cyan
    Write-Host "   Source: $Path" -ForegroundColor Gray
    Write-Host "   Minimum Severity: $Severity" -ForegroundColor Gray
    
    # Get all PowerShell files
    $powershellFiles = Get-ChildItem -Path $Path -Recurse -Include "*.ps1", "*.psm1", "*.psd1" | 
                      Where-Object { $_.Length -gt 0 }
    
    Write-Host "   Files to analyze: $($powershellFiles.Count)" -ForegroundColor Gray
    
    $allFindings = @()
    $processedFiles = 0
    
    # Define comprehensive rule sets
    $securityRules = @(
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingPlainTextForPassword', 
        'PSAvoidUsingUsernameAndPasswordParams',
        'PSUsePSCredentialType',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingComputerNameHardcoded',
        'PSAvoidGlobalVars',
        'PSReviewUnusedParameter',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidUsingCmdletAliases',
        'PSUseSingularNouns',
        'PSUseApprovedVerbs'
    )
    
    $performanceRules = @(
        'PSAvoidUsingWMICmdlet',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSAvoidUsingPositionalParameters'
    )
    
    $bestPracticeRules = @(
        'PSProvideCommentHelp',
        'PSAvoidDefaultValueSwitchParameter',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSMissingModuleManifestField',
        'PSAvoidTrailingWhitespace'
    )
    
    foreach ($file in $powershellFiles) {
        $processedFiles++
        Write-Progress -Activity "Analyzing PowerShell Files" -Status "Processing $($file.Name)" -PercentComplete (($processedFiles / $powershellFiles.Count) * 100)
        
        try {
            # Run PSScriptAnalyzer with all available rules
            $analysisParams = @{
                Path = $file.FullName
                Severity = $Severity
                Recurse = $false
                IncludeDefaultRules = $true
            }
            
            if ($IncludeSuppressions) {
                $analysisParams.Add('IncludeSuppressed', $true)
            }
            
            # Add custom rule paths if provided
            if ($CustomRules.Count -gt 0) {
                $analysisParams.Add('CustomRulePath', $CustomRules)
            }
            
            $findings = Invoke-ScriptAnalyzer @analysisParams
            
            # Enhance findings with additional metadata
            foreach ($finding in $findings) {
                $enhancedFinding = [PSCustomObject]@{
                    File = $file.Name
                    FullPath = $file.FullName
                    RelativePath = $file.FullName.Replace($Path, "").TrimStart('\', '/')
                    Rule = $finding.RuleName
                    Severity = $finding.Severity
                    Line = $finding.Line
                    Column = $finding.Column
                    Message = $finding.Message
                    ScriptName = $finding.ScriptName
                    Extent = $finding.Extent
                    SuggestedCorrections = $finding.SuggestedCorrections
                    Category = switch -Regex ($finding.RuleName) {
                        "Password|Credential|Secure" { "Security - Credentials" }
                        "Invoke|Expression|Eval" { "Security - Code Execution" }
                        "Global|Hardcoded" { "Security - Configuration" }
                        "Comment|Help|Documentation" { "Documentation" }
                        "Performance|WMI" { "Performance" }
                        "Approved|Singular|Reserved" { "Best Practices" }
                        default { "General" }
                    }
                    ImpactLevel = switch ($finding.Severity) {
                        "Error" { "High" }
                        "Warning" { "Medium" }
                        "Information" { "Low" }
                        default { "Unknown" }
                    }
                    AnalysisDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
                $allFindings += $enhancedFinding
            }
        }
        catch {
            Write-Warning "⚠️ Failed to analyze $($file.Name): $_"
        }
    }
    
    Write-Progress -Activity "Analyzing PowerShell Files" -Completed
    return $allFindings
}

# Generate comprehensive PSScriptAnalyzer report
function New-PSScriptAnalyzerReport {
    param(
        [array]$Findings,
        [string]$OutputPath
    )
    
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    $reportPath = Join-Path $OutputPath "PSScriptAnalyzer-Enhanced-Report.md"
    
    $report = @"
# Enhanced PSScriptAnalyzer Security Analysis Report

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Analysis Tool**: PSScriptAnalyzer Enhanced Integration  
**Total Findings**: $($Findings.Count)

## Executive Summary

### Findings Distribution

| Severity | Count | Percentage |
|----------|-------|------------|
| Error | $($Findings | Where-Object Severity -eq "Error" | Measure-Object | Select-Object -ExpandProperty Count) | $(if($Findings.Count -gt 0) { [math]::Round((($Findings | Where-Object Severity -eq "Error" | Measure-Object | Select-Object -ExpandProperty Count) / $Findings.Count) * 100, 2) } else { 0 })% |
| Warning | $($Findings | Where-Object Severity -eq "Warning" | Measure-Object | Select-Object -ExpandProperty Count) | $(if($Findings.Count -gt 0) { [math]::Round((($Findings | Where-Object Severity -eq "Warning" | Measure-Object | Select-Object -ExpandProperty Count) / $Findings.Count) * 100, 2) } else { 0 })% |
| Information | $($Findings | Where-Object Severity -eq "Information" | Measure-Object | Select-Object -ExpandProperty Count) | $(if($Findings.Count -gt 0) { [math]::Round((($Findings | Where-Object Severity -eq "Information" | Measure-Object | Select-Object -ExpandProperty Count) / $Findings.Count) * 100, 2) } else { 0 })% |

### Category Distribution

"@

    # Add category breakdown
    $categories = $Findings | Group-Object Category | Sort-Object Count -Descending
    foreach ($category in $categories) {
        $report += "`n| $($category.Name) | $($category.Count) | $(if($Findings.Count -gt 0) { [math]::Round(($category.Count / $Findings.Count) * 100, 2) } else { 0 })% |"
    }
    
    # Add detailed findings by file
    $report += @"

## Detailed Findings by File

"@

    $fileGroups = $Findings | Group-Object File | Sort-Object Name
    foreach ($fileGroup in $fileGroups) {
        $report += @"

### File: $($fileGroup.Name)

| Rule | Severity | Line | Message |
|------|----------|------|---------|
"@
        foreach ($finding in $fileGroup.Group | Sort-Object Line) {
            $report += "`n| $($finding.Rule) | $($finding.Severity) | $($finding.Line) | $($finding.Message -replace '\|', '\\|') |"
        }
    }
    
    # Add security-specific analysis
    $securityFindings = $Findings | Where-Object { $_.Category -like "*Security*" }
    if ($securityFindings.Count -gt 0) {
        $report += @"

## Security Analysis

### Critical Security Issues

$(if ($securityFindings | Where-Object Severity -eq "Error") {
    "⚠️ **Critical security issues found requiring immediate attention:**`n"
    ($securityFindings | Where-Object Severity -eq "Error" | ForEach-Object { "- **$($_.Rule)** in $($_.File) (Line $($_.Line)): $($_.Message)" }) -join "`n"
} else {
    "✅ No critical security issues found."
})

### Security Warnings

$(if ($securityFindings | Where-Object Severity -eq "Warning") {
    "⚠️ **Security warnings requiring review:**`n"
    ($securityFindings | Where-Object Severity -eq "Warning" | ForEach-Object { "- **$($_.Rule)** in $($_.File) (Line $($_.Line)): $($_.Message)" }) -join "`n"
} else {
    "✅ No security warnings found."
})

"@
    }
    
    # Add recommendations
    $report += @"

## Recommendations

### Immediate Actions Required
$(if ($Findings | Where-Object Severity -eq "Error") {
    ($Findings | Where-Object Severity -eq "Error" | Group-Object Rule | ForEach-Object { "- Address **$($_.Name)** violations ($($_.Count) instances)" }) -join "`n"
} else {
    "✅ No immediate actions required."
})

### Security Improvements
- Review all credential-related findings for proper secure string usage
- Validate input sanitization for any Invoke-Expression usage
- Implement proper error handling to prevent information disclosure
- Follow PowerShell security best practices for production deployment

### Code Quality Improvements
$(if ($Findings | Where-Object Severity -eq "Warning") {
    ($Findings | Where-Object Severity -eq "Warning" | Group-Object Rule | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object { "- Address **$($_.Name)** issues ($($_.Count) instances)" }) -join "`n"
} else {
    "✅ Code quality is good based on PSScriptAnalyzer rules."
})

## Analysis Tools and Rules

### PSScriptAnalyzer Rules Applied
- **Security Rules**: Credential handling, code execution, configuration security
- **Performance Rules**: WMI usage, cmdlet efficiency, parameter usage
- **Best Practice Rules**: PowerShell conventions, documentation, naming

### Custom Security Integration
- Enhanced categorization of findings
- Security-specific impact assessment
- Integration with custom security rules framework

---

**Report Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Next Review**: $(Get-Date -Format "yyyy-MM-dd" (Get-Date).AddDays(30))
"@

    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "📄 Enhanced PSScriptAnalyzer report generated: $reportPath" -ForegroundColor Green
    
    return $reportPath
}

# Main execution
function Invoke-Main {
    Write-Host "🚀 Enhanced PSScriptAnalyzer Integration Starting..." -ForegroundColor Cyan
    
    # Check prerequisites
    if (-not (Test-PSScriptAnalyzerAvailability)) {
        return
    }
    
    # Validate paths
    if (-not (Test-Path $SourcePath)) {
        Write-Error "❌ Source path does not exist: $SourcePath"
        return
    }
    
    # Run enhanced analysis
    $findings = Invoke-EnhancedPSScriptAnalyzer -Path $SourcePath -Severity $MinimumSeverity -CustomRules $CustomRulePaths -IncludeSuppressions $IncludeSuppressions.IsPresent
    
    # Display summary
    Write-Host "`n📊 Analysis Complete!" -ForegroundColor Green
    Write-Host "   Total Findings: $($findings.Count)" -ForegroundColor White
    
    if ($findings.Count -gt 0) {
        $severityGroups = $findings | Group-Object Severity
        foreach ($group in $severityGroups) {
            $color = switch ($group.Name) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Information" { "Cyan" }
                default { "White" }
            }
            Write-Host "   $($group.Name): $($group.Count)" -ForegroundColor $color
        }
        
        # Security-specific summary
        $securityFindings = $findings | Where-Object { $_.Category -like "*Security*" }
        if ($securityFindings.Count -gt 0) {
            Write-Host "`n🛡️ Security Findings: $($securityFindings.Count)" -ForegroundColor Red
            $securityGroups = $securityFindings | Group-Object Rule
            foreach ($secGroup in $securityGroups | Sort-Object Count -Descending) {
                Write-Host "   $($secGroup.Name): $($secGroup.Count)" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "   ✅ No issues found - excellent code quality!" -ForegroundColor Green
    }
    
    # Generate report if requested
    if ($GenerateReport -or $findings.Count -gt 0) {
        $reportPath = New-PSScriptAnalyzerReport -Findings $findings -OutputPath $OutputPath
        Write-Host "`n📄 Detailed report available: $reportPath" -ForegroundColor Cyan
    }
    
    # Export findings to CSV for further analysis
    if ($findings.Count -gt 0) {
        $csvPath = Join-Path $OutputPath "PSScriptAnalyzer-Findings.csv"
        $findings | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Host "📊 Raw findings exported: $csvPath" -ForegroundColor Cyan
    }
    
    Write-Host "`n✅ Enhanced PSScriptAnalyzer analysis completed successfully!" -ForegroundColor Green
}

# Execute main function
Invoke-Main