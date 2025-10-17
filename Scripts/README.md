# Scripts Directory

This directory contains the PowerShell security analysis tools and scripts developed for the security verification project.

## 📁 Contents

### Core Analysis Scripts

#### `Run-WorkingAnalysis.ps1` ⭐ **Recommended**
**Purpose**: Simplified, reliable security analysis script  
**Features**:
- Scans all PowerShell files (.ps1, .psm1, .psd1)
- Applies key security rules (Invoke-Expression, hardcoded credentials, HTTP usage, weak crypto)
- Generates executive summary and detailed module reports
- Robust error handling and clear output

**Usage**:
```powershell
.\Run-WorkingAnalysis.ps1 -SourcePath ".\source" -OutputPath ".\Report"
```

#### `Start-SecurityAnalysis.ps1`
**Purpose**: Master security analysis script with full feature set  
**Features**:
- Comprehensive security rule application
- PSScriptAnalyzer integration
- Pester testing framework integration
- Prerequisites checking
- Advanced reporting

**Usage**:
```powershell
.\Start-SecurityAnalysis.ps1 -SourcePath ".\source" -IncludePSScriptAnalyzer -RunPesterTests
```

### Specialized Analysis Tools

#### `Invoke-SecurityScan.ps1`
**Purpose**: Advanced security scanner with AST parsing  
**Features**:
- Abstract Syntax Tree (AST) analysis
- Complex pattern matching
- Detailed rule processing
- CVSS scoring

#### `Invoke-PesterSecurityTests.ps1`
**Purpose**: Pester-based security compliance testing  
**Features**:
- Automated security test execution
- Pass/fail criteria for security compliance
- Integration with CI/CD pipelines
- Detailed test reporting

#### `Test-BasicSecurity.ps1`
**Purpose**: Quick security check for basic vulnerabilities  
**Features**:
- Fast execution
- Essential security checks only
- Minimal dependencies
- Simple reporting

## 🔧 Script Parameters

### Common Parameters
- `SourcePath`: Path to PowerShell modules to analyze (default: ".\source")
- `OutputPath`: Directory for generated reports (default: ".\Report")
- `MinimumSeverity`: Filter findings by severity level
- `IncludePSScriptAnalyzer`: Enable PSScriptAnalyzer integration
- `RunPesterTests`: Execute Pester security tests

### Example Usage Patterns

#### Basic Security Scan
```powershell
# Quick scan with minimal setup
.\Test-BasicSecurity.ps1 -SourcePath "C:\MyPowerShellModule"
```

#### Comprehensive Analysis
```powershell
# Full analysis with all features
.\Run-WorkingAnalysis.ps1 -SourcePath ".\source" -OutputPath ".\SecurityReports"
```

#### CI/CD Integration
```powershell
# Automated pipeline usage
.\Invoke-PesterSecurityTests.ps1 -SourcePath $env:BUILD_SOURCESDIRECTORY -OutputPath $env:BUILD_ARTIFACTSTAGINGDIRECTORY
```

## 📊 Output and Reporting

### Generated Reports
- **Executive Summary**: High-level security overview
- **Module Reports**: Detailed findings per PowerShell module
- **Pester Results**: Test execution results in XML format
- **Analysis Summary**: Overall project metrics and recommendations

### Report Formats
- **Markdown**: Human-readable reports with formatting
- **XML**: Machine-readable test results for CI/CD integration
- **Console Output**: Real-time progress and summary information

## 🔍 Security Rules Applied

The scripts implement 26 comprehensive security rules covering:

| Category | Rules | Examples |
|----------|--------|----------|
| Code Execution | PS001-PS004 | Invoke-Expression, Script injection, Dynamic code generation |
| Credential Security | PS005-PS007 | Hardcoded credentials, Credential logging, Insecure storage |
| Input Validation | PS008-PS010 | SQL injection, Command injection, Path traversal |
| Network Security | PS016-PS018 | Insecure protocols, Remote execution, Hostname validation |
| Cryptography | PS019-PS020 | Weak algorithms, Insecure random generation |
| Data Exposure | PS011-PS012 | Sensitive data logging, Debug information disclosure |

*[View complete rules documentation](../Rules/PowerShell-Security-Rules.md)*

## ⚙️ Prerequisites and Dependencies

### Required
- **PowerShell 5.1+**: Core scripting environment
- **Windows PowerShell ISE/VS Code**: Recommended development environment

### Optional
- **PSScriptAnalyzer**: Microsoft's static analysis tool
  ```powershell
  Install-Module -Name PSScriptAnalyzer -Force
  ```
- **Pester 5.0+**: Testing framework for security validation
  ```powershell
  Install-Module -Name Pester -Force -SkipPublisherCheck
  ```

## 🔧 Customization and Extension

### Adding Custom Rules
1. Edit `../Rules/PowerShell-Security-Rules.md`
2. Add new rule definitions following the established format
3. Update scripts to implement new rule logic

### Modifying Output Formats
- Customize report templates in the script files
- Add new export formats (JSON, CSV, etc.)
- Integrate with external reporting systems

### CI/CD Integration
```yaml
# Example Azure DevOps pipeline step
- task: PowerShell@2
  displayName: 'Run Security Analysis'
  inputs:
    targetType: 'filePath'
    filePath: 'Scripts/Run-WorkingAnalysis.ps1'
    arguments: '-SourcePath $(Build.SourcesDirectory) -OutputPath $(Build.ArtifactStagingDirectory)'
```

## 🐛 Troubleshooting

### Common Issues

#### Execution Policy Errors
```powershell
# Solution: Bypass execution policy for analysis
powershell.exe -ExecutionPolicy Bypass -File "Scripts\Run-WorkingAnalysis.ps1"
```

#### Module Not Found Errors
```powershell
# Solution: Install required modules
Install-Module -Name PSScriptAnalyzer, Pester -Force
```

#### Path Resolution Issues
```powershell
# Solution: Use absolute paths
.\Run-WorkingAnalysis.ps1 -SourcePath "C:\Full\Path\To\Source"
```

## 📈 Performance Considerations

### Script Performance
- **Test-BasicSecurity.ps1**: Fastest execution, minimal features
- **Run-WorkingAnalysis.ps1**: Balanced performance and features
- **Invoke-SecurityScan.ps1**: Most comprehensive, slower execution

### Optimization Tips
- Use `-MinimumSeverity` to filter results
- Exclude unnecessary file types
- Run analysis on specific modules rather than entire codebases

## 🔗 Related Documentation

- [Main Project README](../README.md)
- [Security Rules Documentation](../Rules/PowerShell-Security-Rules.md)
- [Analysis Reports](../Report/README.md)
- [Project Overview](../.work/project-overview.md)

---

**Last Updated**: October 17, 2025  
**Script Version**: 1.0  
**Compatibility**: PowerShell 5.1+