# PowerShell Security Scanner
# Version: 1.0
# Purpose: Automated security scanning of PowerShell modules using custom rules and PSScriptAnalyzer

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    
    [Parameter(Mandatory = $false)]
    [string]$RulesPath = ".\Rules\PowerShell-Security-Rules.md",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Report",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Critical", "High", "Medium", "Low", "Informational")]
    [string]$MinimumSeverity = "Low",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludePSScriptAnalyzer,
    
    [Parameter(Mandatory = $false)]
    [switch]$DetailedOutput
)

# Import required modules
try {
    Import-Module PSScriptAnalyzer -ErrorAction Stop
    Write-Host "✓ PSScriptAnalyzer module loaded" -ForegroundColor Green
}
catch {
    Write-Warning "PSScriptAnalyzer module not found. Install with: Install-Module -Name PSScriptAnalyzer"
    if (-not $PSBoundParameters.ContainsKey('IncludePSScriptAnalyzer')) {
        Write-Host "Continuing with custom rules only..." -ForegroundColor Yellow
    }
    else {
        return
    }
}

# Define severity levels for comparison
$SeverityLevels = @{
    'Critical' = 5
    'High' = 4
    'Medium' = 3
    'Low' = 2
    'Informational' = 1
}

# Security findings collection
$SecurityFindings = @()
$TotalFilesScanned = 0
$TotalIssuesFound = 0

function Get-SecurityRules {
    param([string]$RulesFilePath)
    
    if (-not (Test-Path $RulesFilePath)) {
        Write-Error "Rules file not found: $RulesFilePath"
        return @()
    }
    
    $rules = @()
    $content = Get-Content $RulesFilePath -Raw
    
    # Parse rules from markdown format
    $ruleMatches = [regex]::Matches($content, '### (?<Name>PS\d+ - .+?)\r?\nId = ''(?<Id>PS\d+)''\r?\nName = ''(?<DisplayName>.+?)''\r?\nSeverity = ''(?<Severity>.+?)''\r?\nCategory = ''(?<Category>.+?)''\r?\nDescription = ''(?<Description>.+?)''\r?\nASTPattern = ''(?<ASTPattern>.+?)''\r?\n(?:CommandName = ''(?<CommandName>.+?)''\r?\n)?(?:Parameters = ''(?<Parameters>.+?)''\r?\n)?(?:Pattern = ''(?<Pattern>.+?)''\r?\n)?(?:Aliases = ''(?<Aliases>.+?)''\r?\n)?(?:Exclusions = ''(?<Exclusions>.+?)''\r?\n)?(?:Context = ''(?<Context>.+?)''\r?\n)?Remediation = ''(?<Remediation>.+?)''\r?\nCVSS = (?<CVSS>[\d.]+)')
    
    foreach ($match in $ruleMatches) {
        $rule = @{
            Id = $match.Groups['Id'].Value
            Name = $match.Groups['DisplayName'].Value
            Severity = $match.Groups['Severity'].Value
            Category = $match.Groups['Category'].Value
            Description = $match.Groups['Description'].Value
            ASTPattern = $match.Groups['ASTPattern'].Value
            CommandName = $match.Groups['CommandName'].Value
            Parameters = $match.Groups['Parameters'].Value
            Pattern = $match.Groups['Pattern'].Value
            Aliases = $match.Groups['Aliases'].Value
            Exclusions = $match.Groups['Exclusions'].Value
            Context = $match.Groups['Context'].Value
            Remediation = $match.Groups['Remediation'].Value
            CVSS = [decimal]$match.Groups['CVSS'].Value
        }
        $rules += $rule
    }
    
    Write-Host "✓ Loaded $($rules.Count) security rules" -ForegroundColor Green
    return $rules
}

function Test-SecurityRule {
    param(
        [string]$FilePath,
        [hashtable]$Rule,
        [string]$FileContent
    )
    
    $findings = @()
    
    try {
        # Parse PowerShell AST
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$null, [ref]$null)
        
        # Check for pattern matches based on rule type
        switch -Regex ($Rule.ASTPattern) {
            'CommandAst' {
                $commandAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
                foreach ($cmdAst in $commandAsts) {
                    if ($Rule.CommandName -and $cmdAst.GetCommandName() -match $Rule.CommandName) {
                        $finding = Test-RulePattern -Rule $Rule -AST $cmdAst -FilePath $FilePath -Content $FileContent
                        if ($finding) { $findings += $finding }
                    }
                }
            }
            'StringConstantExpressionAst' {
                $stringAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true)
                foreach ($strAst in $stringAsts) {
                    $finding = Test-RulePattern -Rule $Rule -AST $strAst -FilePath $FilePath -Content $FileContent
                    if ($finding) { $findings += $finding }
                }
            }
            'VariableExpressionAst' {
                $varAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)
                foreach ($varAst in $varAsts) {
                    $finding = Test-RulePattern -Rule $Rule -AST $varAst -FilePath $FilePath -Content $FileContent
                    if ($finding) { $findings += $finding }
                }
            }
            'ScriptBlockExpressionAst' {
                $sbAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ScriptBlockExpressionAst] }, $true)
                foreach ($sbAst in $sbAsts) {
                    $finding = Test-RulePattern -Rule $Rule -AST $sbAst -FilePath $FilePath -Content $FileContent
                    if ($finding) { $findings += $finding }
                }
            }
        }
    }
    catch {
        Write-Warning "Error parsing file $FilePath`: $($_.Exception.Message)"
    }
    
    return $findings
}

function Test-RulePattern {
    param(
        [hashtable]$Rule,
        [System.Management.Automation.Language.Ast]$AST,
        [string]$FilePath,
        [string]$Content
    )
    
    $matched = $false
    $matchedText = ""
    
    # Check pattern match
    if ($Rule.Pattern) {
        $text = $AST.ToString()
        if ($text -match $Rule.Pattern) {
            $matched = $true
            $matchedText = $matches[0]
        }
    }
    else {
        $matched = $true
        $matchedText = $AST.ToString()
    }
    
    # Check exclusions
    if ($matched -and $Rule.Exclusions) {
        $text = $AST.ToString()
        if ($text -match $Rule.Exclusions) {
            $matched = $false
        }
    }
    
    if ($matched) {
        return @{
            RuleId = $Rule.Id
            RuleName = $Rule.Name
            Severity = $Rule.Severity
            Category = $Rule.Category
            Description = $Rule.Description
            FilePath = $FilePath
            Line = $AST.Extent.StartLineNumber
            Column = $AST.Extent.StartColumnNumber
            Code = $matchedText
            Remediation = $Rule.Remediation
            CVSS = $Rule.CVSS
            Context = $Rule.Context
        }
    }
    
    return $null
}

function Invoke-PSScriptAnalyzerScan {
    param([string]$Path)
    
    if (-not (Get-Module PSScriptAnalyzer -ErrorAction SilentlyContinue)) {
        return @()
    }
    
    Write-Host "Running PSScriptAnalyzer..." -ForegroundColor Yellow
    
    try {
        $results = Invoke-ScriptAnalyzer -Path $Path -Recurse -IncludeDefaultRules
        
        $psaFindings = @()
        foreach ($result in $results) {
            # Map PSScriptAnalyzer severity to our scale
            $severity = switch ($result.Severity) {
                'Error' { 'High' }
                'Warning' { 'Medium' }
                'Information' { 'Low' }
                default { 'Low' }
            }
            
            $psaFindings += @{
                RuleId = "PSA_$($result.RuleName)"
                RuleName = $result.RuleName
                Severity = $severity
                Category = 'PSScriptAnalyzer'
                Description = $result.Message
                FilePath = $result.ScriptPath
                Line = $result.Line
                Column = $result.Column
                Code = $result.Extent.Text
                Remediation = "Review PSScriptAnalyzer documentation for rule: $($result.RuleName)"
                CVSS = 3.0
                Context = "PSScriptAnalyzer built-in rule"
            }
        }
        
        Write-Host "✓ PSScriptAnalyzer found $($psaFindings.Count) issues" -ForegroundColor Green
        return $psaFindings
    }
    catch {
        Write-Warning "Error running PSScriptAnalyzer: $($_.Exception.Message)"
        return @()
    }
}

function Export-SecurityReport {
    param(
        [array]$Findings,
        [string]$OutputDirectory,
        [string]$ModuleName
    )
    
    if (-not (Test-Path $OutputDirectory)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    }
    
    $reportPath = Join-Path $OutputDirectory "$ModuleName-Security-Report.md"
    
    $report = @"
# Security Analysis Report - $ModuleName
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary
- **Total Files Scanned**: $TotalFilesScanned
- **Total Issues Found**: $($Findings.Count)
- **Critical Issues**: $(($Findings | Where-Object { $_.Severity -eq 'Critical' }).Count)
- **High Issues**: $(($Findings | Where-Object { $_.Severity -eq 'High' }).Count)
- **Medium Issues**: $(($Findings | Where-Object { $_.Severity -eq 'Medium' }).Count)
- **Low Issues**: $(($Findings | Where-Object { $_.Severity -eq 'Low' }).Count)
- **Informational Issues**: $(($Findings | Where-Object { $_.Severity -eq 'Informational' }).Count)

## Findings by Severity

"@

    # Group findings by severity
    $groupedFindings = $Findings | Group-Object Severity | Sort-Object { $SeverityLevels[$_.Name] } -Descending
    
    foreach ($group in $groupedFindings) {
        $report += @"

### $($group.Name) Issues ($($group.Count))

"@
        
        foreach ($finding in $group.Group) {
            $report += @"

#### $($finding.RuleName) ($($finding.RuleId))
**Category**: $($finding.Category)  
**File**: $($finding.FilePath)  
**Line**: $($finding.Line)  
**CVSS Score**: $($finding.CVSS)

**Description**: $($finding.Description)

**Code**:
``````powershell
$($finding.Code)
``````

**Remediation**: $($finding.Remediation)

$(if ($finding.Context) { "**Context**: $($finding.Context)" })

---

"@
        }
    }
    
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "✓ Report saved to: $reportPath" -ForegroundColor Green
}

# Main execution
Write-Host "PowerShell Security Scanner v1.0" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Validate paths
if (-not (Test-Path $SourcePath)) {
    Write-Error "Source path not found: $SourcePath"
    return
}

# Load security rules
$rules = Get-SecurityRules -RulesFilePath $RulesPath
if ($rules.Count -eq 0) {
    Write-Error "No security rules loaded. Exiting."
    return
}

# Filter rules by minimum severity
$minSeverityLevel = $SeverityLevels[$MinimumSeverity]
$filteredRules = $rules | Where-Object { $SeverityLevels[$_.Severity] -ge $minSeverityLevel }
Write-Host "✓ Using $($filteredRules.Count) rules (severity >= $MinimumSeverity)" -ForegroundColor Green

# Get PowerShell files to scan
$psFiles = Get-ChildItem -Path $SourcePath -Filter "*.ps*" -Recurse | Where-Object { $_.Extension -match "\.(ps1|psm1|psd1)$" }
$TotalFilesScanned = $psFiles.Count
Write-Host "✓ Found $TotalFilesScanned PowerShell files to scan" -ForegroundColor Green

# Scan each file
foreach ($file in $psFiles) {
    Write-Host "Scanning: $($file.FullName)" -ForegroundColor Gray
    
    $fileContent = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $fileContent) { continue }
    
    foreach ($rule in $filteredRules) {
        $findings = Test-SecurityRule -FilePath $file.FullName -Rule $rule -FileContent $fileContent
        $SecurityFindings += $findings
    }
}

# Run PSScriptAnalyzer if requested
if ($IncludePSScriptAnalyzer) {
    $psaFindings = Invoke-PSScriptAnalyzerScan -Path $SourcePath
    $SecurityFindings += $psaFindings
}

$TotalIssuesFound = $SecurityFindings.Count

# Generate reports
if ($SecurityFindings.Count -gt 0) {
    Write-Host "`n🔍 Security Scan Complete" -ForegroundColor Yellow
    Write-Host "Files Scanned: $TotalFilesScanned" -ForegroundColor White
    Write-Host "Issues Found: $TotalIssuesFound" -ForegroundColor White
    
    # Group by module
    $moduleFindings = $SecurityFindings | Group-Object { 
        $relativePath = $_.FilePath.Replace($SourcePath, "").Trim('\')
        $parts = $relativePath.Split('\')
        if ($parts.Count -gt 0) { $parts[0] } else { "Unknown" }
    }
    
    foreach ($module in $moduleFindings) {
        Export-SecurityReport -Findings $module.Group -OutputDirectory $OutputPath -ModuleName $module.Name
    }
    
    # Create executive summary
    $execSummaryPath = Join-Path $OutputPath "Executive-Summary.md"
    $execSummary = @"
# Executive Security Summary
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Overall Security Posture
- **Total PowerShell Files Analyzed**: $TotalFilesScanned
- **Total Security Issues Identified**: $TotalIssuesFound
- **Modules Analyzed**: $($moduleFindings.Count)

## Risk Distribution
$(($SecurityFindings | Group-Object Severity | Sort-Object { $SeverityLevels[$_.Name] } -Descending | ForEach-Object { "- **$($_.Name)**: $($_.Count) issues" }) -join "`n")

## Modules Analysis
$(($moduleFindings | ForEach-Object { "- **$($_.Name)**: $($_.Group.Count) issues" }) -join "`n")

## Top Security Concerns
$(($SecurityFindings | Group-Object RuleName | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object { "- **$($_.Name)**: $($_.Count) occurrences" }) -join "`n")

## Recommendations
1. Address all Critical and High severity issues immediately
2. Review Medium severity issues for business context
3. Implement secure coding practices training
4. Establish regular security code reviews
5. Consider implementing automated security scanning in CI/CD pipeline

"@
    
    $execSummary | Out-File -FilePath $execSummaryPath -Encoding UTF8
    Write-Host "✓ Executive summary saved to: $execSummaryPath" -ForegroundColor Green
}
else {
    Write-Host "`n✅ No security issues found!" -ForegroundColor Green
}

Write-Host "`nScan completed successfully." -ForegroundColor Cyan