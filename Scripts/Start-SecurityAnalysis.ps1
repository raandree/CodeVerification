# Master Security Analysis Script
# Version: 1.0
# Purpose: Run comprehensive security analysis using both custom rules and Pester tests

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SourcePath = ".\source",
    
    [Parameter(Mandatory = $false)]
    [string]$RulesPath = ".\Rules\PowerShell-Security-Rules.md",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Report",
    
    [Parameter(Mandatory = $false)]
    [switch]$RunPesterTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludePSScriptAnalyzer,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Critical", "High", "Medium", "Low", "Informational")]
    [string]$MinimumSeverity = "Low"
)

# Set up environment
$ErrorActionPreference = "Stop"
$startTime = Get-Date

Write-Host @"
╔══════════════════════════════════════════════════════════════════════════════╗
║                    PowerShell Security Analysis Suite                        ║
║                              Version 1.0                                    ║
╚══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Validate prerequisites
function Test-Prerequisites {
    Write-Host "`n🔍 Checking Prerequisites..." -ForegroundColor Yellow
    
    $issues = @()
    
    # Check source path
    if (-not (Test-Path $SourcePath)) {
        $issues += "Source path not found: $SourcePath"
    }
    
    # Check rules file
    if (-not (Test-Path $RulesPath)) {
        $issues += "Rules file not found: $RulesPath"
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $issues += "PowerShell 5.0 or higher required. Current version: $($PSVersionTable.PSVersion)"
    }
    
    # Check for PSScriptAnalyzer if requested
    if ($IncludePSScriptAnalyzer) {
        try {
            Import-Module PSScriptAnalyzer -ErrorAction Stop
            Write-Host "✓ PSScriptAnalyzer available" -ForegroundColor Green
        }
        catch {
            Write-Warning "PSScriptAnalyzer not available. Install with: Install-Module -Name PSScriptAnalyzer"
            $script:IncludePSScriptAnalyzer = $false
        }
    }
    
    # Check for Pester if requested
    if ($RunPesterTests) {
        try {
            Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
            Write-Host "✓ Pester 5.0+ available" -ForegroundColor Green
        }
        catch {
            Write-Warning "Pester 5.0+ not available. Install with: Install-Module -Name Pester -Force"
            $script:RunPesterTests = $false
        }
    }
    
    if ($issues.Count -gt 0) {
        Write-Host "`n❌ Prerequisites check failed:" -ForegroundColor Red
        $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        return $false
    }
    
    Write-Host "✅ All prerequisites met" -ForegroundColor Green
    return $true
}

# Main analysis function
function Start-SecurityAnalysis {
    Write-Host "`n📊 Starting Security Analysis..." -ForegroundColor Yellow
    
    # Create output directory
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-Host "✓ Created output directory: $OutputPath" -ForegroundColor Green
    }
    
    # Run custom security scan
    Write-Host "`n🔎 Running Custom Security Rules Scan..." -ForegroundColor Cyan
    $scannerParams = @{
        SourcePath = $SourcePath
        RulesPath = $RulesPath
        OutputPath = $OutputPath
        MinimumSeverity = $MinimumSeverity
    }
    
    if ($IncludePSScriptAnalyzer) {
        $scannerParams.IncludePSScriptAnalyzer = $true
    }
    
    try {
        $scannerScript = Join-Path $PSScriptRoot "Invoke-SecurityScan.ps1"
        & $scannerScript @scannerParams
        Write-Host "✅ Custom security scan completed" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to run custom security scan: $($_.Exception.Message)"
        return $false
    }
    
    # Run Pester tests if requested
    if ($RunPesterTests) {
        Write-Host "`n🧪 Running Pester Security Tests..." -ForegroundColor Cyan
        
        try {
            $pesterScript = Join-Path $PSScriptRoot "Invoke-PesterSecurityTests.ps1"
            $pesterParams = @{
                SourcePath = $SourcePath
                RulesPath = $RulesPath
                OutputPath = Join-Path $OutputPath "Pester-Results.xml"
            }
            
            # Run Pester tests
            $pesterConfig = [PesterConfiguration]@{
                Run = @{
                    Path = $pesterScript
                    PassThru = $true
                }
                Output = @{
                    Verbosity = 'Detailed'
                }
                TestResult = @{
                    Enabled = $true
                    OutputPath = $pesterParams.OutputPath
                    OutputFormat = 'NUnitXml'
                }
            }
            
            $pesterResult = Invoke-Pester -Configuration $pesterConfig
            
            Write-Host "`n📋 Pester Test Results:" -ForegroundColor Cyan
            Write-Host "  Total Tests: $($pesterResult.TotalCount)" -ForegroundColor White
            Write-Host "  Passed: $($pesterResult.PassedCount)" -ForegroundColor Green
            Write-Host "  Failed: $($pesterResult.FailedCount)" -ForegroundColor Red
            Write-Host "  Skipped: $($pesterResult.SkippedCount)" -ForegroundColor Yellow
            
            if ($pesterResult.FailedCount -gt 0) {
                Write-Host "❌ Some security tests failed!" -ForegroundColor Red
            }
            else {
                Write-Host "✅ All security tests passed!" -ForegroundColor Green
            }
            
        }
        catch {
            Write-Error "Failed to run Pester tests: $($_.Exception.Message)"
            return $false
        }
    }
    
    return $true
}

# Generate final summary
function New-FinalSummary {
    Write-Host "`n📝 Generating Final Summary..." -ForegroundColor Yellow
    
    $summaryPath = Join-Path $OutputPath "Analysis-Summary.md"
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    # Count files in source
    $psFiles = Get-ChildItem -Path $SourcePath -Filter "*.ps*" -Recurse | Where-Object { $_.Extension -match "\.(ps1|psm1|psd1)$" }
    
    # Count existing reports
    $reportFiles = Get-ChildItem -Path $OutputPath -Filter "*-Security-Report.md" -ErrorAction SilentlyContinue
    
    $summary = @"
# PowerShell Security Analysis Summary
**Analysis Date**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Duration**: $($duration.TotalMinutes.ToString("F2")) minutes  
**Analyst**: $env:USERNAME  
**Scope**: $SourcePath

## Analysis Scope
- **PowerShell Files Analyzed**: $($psFiles.Count)
- **Modules Reviewed**: $($reportFiles.Count)
- **Custom Security Rules**: Applied $((Get-Content $RulesPath -Raw | Select-String "### PS\d+" -AllMatches).Matches.Count) rules
- **PSScriptAnalyzer**: $(if ($IncludePSScriptAnalyzer) { "Included" } else { "Not included" })
- **Pester Security Tests**: $(if ($RunPesterTests) { "Executed" } else { "Not executed" })

## File Distribution
$(if ($psFiles.Count -gt 0) {
    $psFiles | Group-Object Extension | ForEach-Object { "- **$($_.Name)**: $($_.Count) files" } | Join-String -Separator "`n"
})

## Output Files Generated
$(Get-ChildItem -Path $OutputPath -File | ForEach-Object { "- [$($_.Name)](./$($_.Name))" } | Join-String -Separator "`n")

## Analysis Configuration
- **Minimum Severity**: $MinimumSeverity
- **Source Path**: $SourcePath
- **Rules File**: $RulesPath
- **Output Directory**: $OutputPath

## Next Steps
1. Review all generated security reports
2. Prioritize Critical and High severity findings
3. Validate Medium severity findings for business context
4. Address identified security vulnerabilities
5. Implement security best practices training
6. Consider integrating security scanning into CI/CD pipeline

## Tool Information
- **PowerShell Version**: $($PSVersionTable.PSVersion)
- **OS**: $($PSVersionTable.OS)
- **Analysis Tool**: PowerShell Security Analysis Suite v1.0

---
*This analysis was performed using automated security scanning tools. Manual review of findings is recommended to validate security concerns in the appropriate business context.*
"@

    $summary | Out-File -FilePath $summaryPath -Encoding UTF8
    Write-Host "✓ Final summary saved to: $summaryPath" -ForegroundColor Green
}

# Main execution
try {
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    # Run analysis
    if (-not (Start-SecurityAnalysis)) {
        exit 1
    }
    
    # Generate summary
    New-FinalSummary
    
    $endTime = Get-Date
    $totalDuration = $endTime - $startTime
    
    Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                         Analysis Complete!                                  ║
║                                                                              ║
║  Duration: $($totalDuration.TotalMinutes.ToString("F2").PadLeft(4)) minutes                                               ║
║  Reports: $OutputPath                                     ║
╚══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Green

}
catch {
    Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                           Analysis Failed!                                  ║
║                                                                              ║
║  Error: $($_.Exception.Message.PadRight(64).Substring(0,64))║
╚══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Red

    Write-Error $_.Exception.Message
    exit 1
}