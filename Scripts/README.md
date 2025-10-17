# Security Analysis Scripts

This directory contains the PowerShell scripts that perform security analysis on PowerShell modules.

## Scripts

### Start-SecurityAnalysis.ps1
**Master orchestration script** that coordinates the entire security analysis process.

**Usage:**
```powershell
.\Start-SecurityAnalysis.ps1
```

**What it does:**
1. Discovers all modules in the `source/` directory
2. Runs security scans on each module
3. Generates comprehensive reports
4. Creates both executive summary and detailed per-module reports

**Output:**
- Findings XML files for each module in `Report/` directory
- ExecutiveSummary.md
- Individual module reports (e.g., nishang-0.7.6_Report.md)

### Invoke-SecurityScan.ps1
**Core scanning engine** that analyzes PowerShell code for security issues.

**Usage:**
```powershell
.\Invoke-SecurityScan.ps1 -Path "C:\Path\To\Module" -OutputPath "C:\Path\To\Report" -ModuleName "ModuleName"
```

**Parameters:**
- `-Path`: Directory containing PowerShell files to analyze
- `-OutputPath`: Where to save findings
- `-ModuleName`: Name for the module being scanned

**What it does:**
1. Loads security rules from `Rules\SecurityRules.ps1`
2. Discovers all `.ps1`, `.psm1`, and `.psd1` files
3. Parses each file using PowerShell AST (Abstract Syntax Tree)
4. Applies both AST-based and regex pattern rules
5. Collects findings with file paths, line numbers, and code excerpts
6. Exports findings to XML for report generation
7. Displays real-time progress and statistics

**Detection Methods:**
- **AST Analysis**: Parses PowerShell syntax tree to detect commands and patterns
- **Regex Matching**: Uses pattern matching for text-based detection
- **Alias Detection**: Recognizes command aliases (e.g., `iex` for `Invoke-Expression`)

### New-SecurityReport.ps1
**Report generation script** that creates markdown reports from findings.

**Usage:**
```powershell
.\New-SecurityReport.ps1 -FindingsPath "C:\Path\To\Findings" -OutputPath "C:\Path\To\Reports"
```

**Parameters:**
- `-FindingsPath`: Directory containing `*_Findings.xml` files
- `-OutputPath`: Where to save generated reports

**What it does:**
1. Loads all findings XML files
2. Calculates statistics and severity distribution
3. Generates Executive Summary with:
   - Overall risk assessment
   - Severity breakdown
   - Top categories
   - Per-module summaries
   - Critical findings highlight
   - Recommendations
4. Creates detailed per-module reports with:
   - Summary statistics
   - Findings organized by category and rule
   - Code excerpts with file paths and line numbers
   - CVSS scores and remediation guidance

**Report Format:**
- Markdown format for easy readability
- Links between executive summary and detailed reports
- Code syntax highlighting
- CVSS scoring for risk quantification

## Workflow

```
Start-SecurityAnalysis.ps1
         ↓
    Discovers modules
         ↓
    For each module:
         ↓
    Invoke-SecurityScan.ps1
         ↓
    - Loads rules
    - Parses AST
    - Applies patterns
    - Saves findings to XML
         ↓
    New-SecurityReport.ps1
         ↓
    - Loads all findings
    - Generates reports
    - Creates markdown files
```

## Output Structure

```
Report/
├── ExecutiveSummary.md
├── ModuleName_Findings.xml
├── ModuleName_Report.md
├── ...
```

## Customization

### Adding New Detection Patterns
Edit `Rules\SecurityRules.ps1` to add new rules.

### Modifying Report Format
Edit `New-SecurityReport.ps1` to change report layout or add sections.

### Adjusting Severity Thresholds
Edit risk assessment logic in `New-SecurityReport.ps1`:
```powershell
$riskLevel = if ($criticalCount -gt 10) {
    "**CRITICAL** - Immediate action required"
} elseif ($criticalCount -gt 0 -or $highCount -gt 20) {
    "**HIGH** - Urgent attention needed"
}
```

## Performance

- **Small modules** (< 20 files): < 1 minute
- **Medium modules** (20-50 files): 1-3 minutes
- **Large modules** (50-100 files): 3-5 minutes

Performance depends on:
- Number of PowerShell files
- File size and complexity
- Number of rules applied

## Error Handling

The scripts handle:
- Parse errors in PowerShell files (reported as findings)
- Missing or inaccessible files (warnings issued)
- Invalid rule patterns (errors logged, scan continues)

## Dependencies

- **PowerShell 5.1+** or **PowerShell 7+**
- No external modules required
- Uses built-in .NET parser for AST analysis

## Extending the Scanner

### Adding Custom Analysis
Add custom analysis functions to `Invoke-SecurityScan.ps1`:

```powershell
# Example: Check for specific organizational patterns
if ($content -match 'CompanyName-InternalCmdlet') {
    # Create custom finding
}
```

### Integration with CI/CD
Run the scanner as part of automated pipelines:

```powershell
.\Start-SecurityAnalysis.ps1
if ($LASTEXITCODE -ne 0) {
    throw "Security scan failed"
}
```

## Troubleshooting

### Issue: Script execution is disabled
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: Parse errors reported
- Check PowerShell syntax in reported files
- Some files may use unsupported syntax
- Parse errors are reported as findings for review

### Issue: Too many false positives
- Review `Rules\RuleContextGuidelines.md`
- Adjust rule severity in `SecurityRules.ps1`
- Consider module purpose (security tools vs enterprise scripts)
