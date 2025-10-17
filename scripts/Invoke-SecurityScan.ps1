<#
.SYNOPSIS
    Main security scanning script for PowerShell modules

.DESCRIPTION
    Scans PowerShell modules for security vulnerabilities using custom detection rules
    and PSScriptAnalyzer integration. Generates findings for report generation.

.PARAMETER ModulePath
    Path to the PowerShell module to scan

.PARAMETER OutputPath
    Path where findings JSON will be saved

.PARAMETER RulesPath
    Path to the detection rules file. Defaults to ../detection-rules/SecurityRules.ps1

.PARAMETER IncludePSScriptAnalyzer
    Include PSScriptAnalyzer built-in rules in the scan

.PARAMETER Severity
    Minimum severity level to report (Critical, High, Medium, Low)

.EXAMPLE
    .\Invoke-SecurityScan.ps1 -ModulePath "E:\CodeVerification\source\AADConnectDsc" -OutputPath ".\findings"

.NOTES
    Requires PSScriptAnalyzer module
    Author: Security Review System
    Date: October 17, 2025
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ModulePath,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$RulesPath = (Join-Path $PSScriptRoot "..\detection-rules\SecurityRules.ps1"),
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludePSScriptAnalyzer,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Critical', 'High', 'Medium', 'Low')]
    [string]$Severity = 'Low'
)

#Requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Import helper functions
. (Join-Path $PSScriptRoot "Get-SecurityFindings.ps1")

Write-Host "=== PowerShell Security Scanner ===" -ForegroundColor Cyan
Write-Host "Module: $ModulePath" -ForegroundColor White
Write-Host "Output: $OutputPath" -ForegroundColor White
Write-Host ""

# Validate paths
if (-not (Test-Path $ModulePath)) {
    throw "Module path not found: $ModulePath"
}

if (-not (Test-Path $RulesPath)) {
    throw "Rules file not found: $RulesPath"
}

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Load detection rules
Write-Host "[1/5] Loading detection rules..." -ForegroundColor Yellow
$rules = & $RulesPath
Write-Host "      Loaded $($rules.Count) security rules" -ForegroundColor Green

# Get all PowerShell files
Write-Host "[2/5] Discovering PowerShell files..." -ForegroundColor Yellow
$files = Get-ChildItem -Path $ModulePath -Include *.ps1, *.psm1, *.psd1 -Recurse -File
Write-Host "      Found $($files.Count) PowerShell files" -ForegroundColor Green

# Initialize findings collection
$allFindings = @()

# Scan each file
Write-Host "[3/5] Scanning files with custom rules..." -ForegroundColor Yellow
$fileCount = 0
foreach ($file in $files) {
    $fileCount++
    Write-Progress -Activity "Scanning Files" -Status "Processing $($file.Name)" -PercentComplete (($fileCount / $files.Count) * 100)
    
    try {
        $fileFindings = Get-SecurityFindings -FilePath $file.FullName -Rules $rules
        if ($fileFindings) {
            $allFindings += $fileFindings
        }
    }
    catch {
        Write-Warning "Error scanning $($file.FullName): $_"
    }
}
Write-Progress -Activity "Scanning Files" -Completed
Write-Host "      Found $($allFindings.Count) potential issues" -ForegroundColor Green

# Run PSScriptAnalyzer if requested
$psaFindings = @()
if ($IncludePSScriptAnalyzer) {
    Write-Host "[4/5] Running PSScriptAnalyzer..." -ForegroundColor Yellow
    
    # Check if PSScriptAnalyzer is available
    if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
        Import-Module PSScriptAnalyzer
        
        try {
            $psaResults = Invoke-ScriptAnalyzer -Path $ModulePath -Recurse -Severity Error, Warning
            
            foreach ($result in $psaResults) {
                # Map PSScriptAnalyzer severity to our severity levels
                $mappedSeverity = switch ($result.Severity.ToString()) {
                    'Error' { 'High' }
                    'Warning' { 'Medium' }
                    'Information' { 'Low' }
                    default { 'Low' }
                }
                
                # Extract code snippet if available
                $code = ""
                if ($result.Extent) {
                    $code = $result.Extent.Text
                }
                elseif ($result.Line) {
                    # Read the line from file
                    try {
                        $fileLines = Get-Content -Path $result.ScriptPath
                        if ($result.Line -le $fileLines.Count) {
                            $code = $fileLines[$result.Line - 1]
                        }
                    }
                    catch {
                        $code = "(Unable to extract code)"
                    }
                }
                
                $psaFindings += [PSCustomObject]@{
                    Source = 'PSScriptAnalyzer'
                    RuleId = $result.RuleName
                    RuleName = $result.RuleName
                    Severity = $mappedSeverity
                    Category = 'PSScriptAnalyzer'
                    File = $result.ScriptPath
                    Line = $result.Line
                    Column = $result.Column
                    Code = $code
                    Message = $result.Message
                    Remediation = "See PSScriptAnalyzer documentation for $($result.RuleName)"
                    CVSS = 0.0
                }
            }
            
            Write-Host "      PSScriptAnalyzer found $($psaResults.Count) issues" -ForegroundColor Green
        }
        catch {
            Write-Warning "PSScriptAnalyzer scan failed: $_"
        }
    }
    else {
        Write-Warning "PSScriptAnalyzer module not installed. Run: Install-Module PSScriptAnalyzer"
    }
}
else {
    Write-Host "[4/5] Skipping PSScriptAnalyzer (not requested)" -ForegroundColor Gray
}

# Combine findings
$combinedFindings = @($allFindings) + @($psaFindings)

# Filter by severity
$severityOrder = @{
    'Critical' = 4
    'High' = 3
    'Medium' = 2
    'Low' = 1
}

$minSeverityLevel = $severityOrder[$Severity]
$filteredFindings = @($combinedFindings | Where-Object { 
    $severityOrder[$_.Severity] -ge $minSeverityLevel 
})

Write-Host "[5/5] Generating output..." -ForegroundColor Yellow

# Generate summary
$criticalCount = @($filteredFindings | Where-Object { $_.Severity -eq 'Critical' }).Count
$highCount = @($filteredFindings | Where-Object { $_.Severity -eq 'High' }).Count
$mediumCount = @($filteredFindings | Where-Object { $_.Severity -eq 'Medium' }).Count
$lowCount = @($filteredFindings | Where-Object { $_.Severity -eq 'Low' }).Count

$summary = @{
    ScanDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ModulePath = $ModulePath
    ModuleName = (Split-Path $ModulePath -Leaf)
    FilesScanned = $files.Count
    TotalFindings = $filteredFindings.Count
    FindingsBySeverity = @{
        Critical = $criticalCount
        High = $highCount
        Medium = $mediumCount
        Low = $lowCount
    }
    FindingsByCategory = $filteredFindings | Group-Object Category | ForEach-Object {
        @{ $_.Name = $_.Count }
    }
}

# Save findings
$outputFile = Join-Path $OutputPath "$($summary.ModuleName)_findings.json"
$output = @{
    Summary = $summary
    Findings = $filteredFindings
}

$output | ConvertTo-Json -Depth 10 | Set-Content -Path $outputFile -Encoding UTF8

Write-Host ""
Write-Host "=== Scan Complete ===" -ForegroundColor Cyan
Write-Host "Total Findings: $($filteredFindings.Count)" -ForegroundColor White
Write-Host "  Critical: $($summary.FindingsBySeverity.Critical)" -ForegroundColor Red
Write-Host "  High:     $($summary.FindingsBySeverity.High)" -ForegroundColor Magenta
Write-Host "  Medium:   $($summary.FindingsBySeverity.Medium)" -ForegroundColor Yellow
Write-Host "  Low:      $($summary.FindingsBySeverity.Low)" -ForegroundColor Gray
Write-Host ""
Write-Host "Results saved to: $outputFile" -ForegroundColor Green
Write-Host ""

# Return findings for pipeline use
return $filteredFindings
