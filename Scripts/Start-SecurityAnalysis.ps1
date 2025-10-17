<#
.SYNOPSIS
    Master script to orchestrate full security analysis
.DESCRIPTION
    Runs security scans on all modules and generates comprehensive reports
.EXAMPLE
    .\Start-SecurityAnalysis.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptRoot

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "PowerShell Security Analysis System" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Define paths
$sourcePath = Join-Path $projectRoot "source"
$reportPath = Join-Path $projectRoot "Report"

# Create report directory
if (-not (Test-Path $reportPath)) {
    New-Item -Path $reportPath -ItemType Directory -Force | Out-Null
    Write-Host "Created report directory: $reportPath" -ForegroundColor Green
}

# Discover modules to analyze
Write-Host "Discovering modules in source directory..." -ForegroundColor Cyan
$moduleDirs = Get-ChildItem -Path $sourcePath -Directory

Write-Host "Found $($moduleDirs.Count) modules to analyze:" -ForegroundColor Green
foreach ($mod in $moduleDirs) {
    Write-Host "  - $($mod.Name)" -ForegroundColor Gray
}
Write-Host ""

# Analyze each module
foreach ($moduleDir in $moduleDirs) {
    $moduleName = $moduleDir.Name
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Analyzing Module: $moduleName" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    
    try {
        # Run security scan
        $scanScript = Join-Path $scriptRoot "Invoke-SecurityScan.ps1"
        $findings = & $scanScript -Path $moduleDir.FullName -OutputPath $reportPath -ModuleName $moduleName
        
        Write-Host "`nModule $moduleName analysis complete" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to analyze module $moduleName : $_"
    }
    
    Write-Host ""
}

# Generate reports
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Generating Security Reports" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

try {
    $reportScript = Join-Path $scriptRoot "New-SecurityReport.ps1"
    & $reportScript -FindingsPath $reportPath -OutputPath $reportPath
    
    Write-Host "`n=== Analysis Complete ===" -ForegroundColor Green
    Write-Host "Reports available in: $reportPath" -ForegroundColor Cyan
    Write-Host "  - ExecutiveSummary.md" -ForegroundColor Gray
    
    $reportFiles = Get-ChildItem -Path $reportPath -Filter "*_Report.md"
    foreach ($report in $reportFiles) {
        Write-Host "  - $($report.Name)" -ForegroundColor Gray
    }
}
catch {
    Write-Error "Failed to generate reports: $_"
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Security Analysis Complete" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
