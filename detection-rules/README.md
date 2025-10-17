# PowerShell Security Detection Rules

## Overview

This directory contains comprehensive security detection rules for PowerShell code analysis. The rules are designed to identify security vulnerabilities, unsafe coding practices, and potential malicious code patterns while minimizing false positives in legitimate PowerShell code.

## Rule Structure

Each rule is defined as a PowerShell hashtable with the following properties:

```powershell
@{
    Id = 'PS###'                    # Unique identifier
    Name = 'Rule Name'              # Human-readable name
    Severity = 'Critical|High|Medium|Low'  # Risk level
    Category = 'Category'           # Classification
    Description = 'Detailed description'   # What it detects
    ASTPattern = 'AST Type'         # AST node type to match
    CommandName = 'Cmdlet'          # Optional: Specific command
    ParameterCheck = 'Pattern'      # Optional: Parameter pattern
    ContextCheck = 'Pattern'        # Optional: Context pattern
    PatternMatch = 'Regex'          # Optional: Regex pattern
    Remediation = 'Fix guidance'    # How to resolve
    CVSS = 0.0-10.0                 # CVSS score
    PSScriptAnalyzerRule = 'Name'   # Optional: Corresponding PSScriptAnalyzer rule
}
```

## Severity Levels

### Critical (CVSS 9.0-10.0)
Immediate security risk requiring urgent attention:
- Direct credential exposure
- Arbitrary code execution vulnerabilities
- Critical security policy violations
- Malicious code patterns

### High (CVSS 7.0-8.9)
Significant security concerns requiring prompt remediation:
- Information disclosure of sensitive data
- SQL injection vulnerabilities
- Unencrypted remote connections
- Dangerous operations without proper validation

### Medium (CVSS 4.0-6.9)
Issues that should be reviewed and addressed:
- Weak cryptography
- Missing input validation
- Persistence mechanisms
- Suspicious behaviors

### Low (CVSS 0.0-3.9)
Best practice violations and code quality issues:
- Missing documentation
- Code quality concerns
- Maintainability issues

## Rule Categories

### CodeExecution
Rules detecting arbitrary code execution risks:
- PS001: Invoke-Expression Usage
- PS005: Add-Type with Inline C# Code
- PS030: Dynamic Function Creation
- PS032: Reflective Loading

### CredentialExposure
Rules detecting credential handling issues:
- PS002: ConvertTo-SecureString with PlainText
- PS003: Plaintext Password in Code
- PS011: Credential in Logs or Output
- PS027: DSC Credential in Clear Text

### NetworkSecurity
Rules detecting network-related security issues:
- PS006: DownloadString or DownloadFile Usage
- PS010: Unencrypted Remote Connection
- PS014: Disabled Certificate Validation

### InputValidation
Rules detecting insufficient input validation:
- PS008: Missing Parameter Validation
- PS009: SQL Query Concatenation

### InformationDisclosure
Rules detecting sensitive data exposure:
- PS007: Write-Host for Sensitive Data
- PS035: Sensitive Data in Logs

### Obfuscation
Rules detecting code obfuscation techniques:
- PS029: Base64 Encoded Content

### Persistence
Rules detecting persistence mechanisms:
- PS020: Scheduled Task Creation
- PS021: Service Installation or Modification

### DSC-Specific
Rules specific to Desired State Configuration:
- PS026: DSC Resource Without Test Method
- PS027: DSC Credential in Clear Text
- PS028: Missing Import-DscResource

## PSScriptAnalyzer Integration

Many rules correspond to built-in PSScriptAnalyzer rules. Rules with `PSScriptAnalyzerRule` property can be cross-validated using:

```powershell
Invoke-ScriptAnalyzer -Path $file -IncludeRule $rule.PSScriptAnalyzerRule
```

### PSScriptAnalyzer Rules Covered

| Custom Rule | PSScriptAnalyzer Rule |
|-------------|----------------------|
| PS001 | PSAvoidUsingInvokeExpression |
| PS002 | PSAvoidUsingConvertToSecureStringWithPlainText |
| PS003 | PSAvoidUsingPlainTextForPassword |
| PS007 | PSAvoidUsingWriteHost |
| PS017 | PSAvoidUsingEmptyCatchBlock |
| PS018 | PSAvoidUsingPositionalParameters |
| PS022 | PSProvideCommentHelp |
| PS023 | PSAvoidUsingCmdletAliases |
| PS025 | PSShouldProcess |

## PowerShell-Specific Considerations

### Acceptable Patterns

These patterns are **NOT** flagged as issues when used correctly:

1. **SecureString Usage**: Using `[System.Security.SecureString]` and `[PSCredential]` is the correct approach
2. **Username Logging**: Logging usernames or non-sensitive IDs for debugging is acceptable
3. **High Entropy Strings**: Descriptive PowerShell code naturally has high entropy
4. **Credential Parameters**: DSC resources and cmdlets having `[PSCredential]` parameters is expected

### False Positive Reduction

Rules are designed to minimize false positives by:

1. **Context-Aware Detection**: Checking surrounding code context, not just pattern matching
2. **PowerShell Idiom Recognition**: Understanding normal PowerShell patterns vs. suspicious ones
3. **Manual Review Flags**: Some rules flag for manual review rather than automatic failure
4. **Severity Tuning**: High entropy and other patterns marked for review, not automatic critical

## Usage Example

```powershell
# Load rules
$rules = & ".\detection-rules\SecurityRules.ps1"

# Filter by severity
$criticalRules = $rules | Where-Object { $_.Severity -eq 'Critical' }

# Filter by category
$execRules = $rules | Where-Object { $_.Category -eq 'CodeExecution' }

# Get rule by ID
$rule = $rules | Where-Object { $_.Id -eq 'PS001' }

# Check for PSScriptAnalyzer correspondence
$psaRules = $rules | Where-Object { $_.PSScriptAnalyzerRule } | 
    Select-Object Id, Name, PSScriptAnalyzerRule
```

## Rule Development Guidelines

When adding new rules:

1. **Assign Unique ID**: Use next available PS### number
2. **Accurate Severity**: Base CVSS score on actual risk
3. **Clear Description**: Explain what is detected and why it's a risk
4. **Actionable Remediation**: Provide specific steps to fix
5. **Test Coverage**: Create test cases for both positive and negative matches
6. **Document False Positives**: Note known legitimate uses
7. **PSScriptAnalyzer Mapping**: Link to PSA rules where applicable

## Community Rules

Additional PSScriptAnalyzer rules from DSC Community:

### Available Community Repositories

1. **DscResource.Common** - Common DSC helper functions
2. **ActiveDirectoryDsc** - Active Directory DSC resources
3. **SqlServerDsc** - SQL Server DSC resources  
4. **ComputerManagementDsc** - Computer management DSC resources
5. **SharePointDsc** - SharePoint DSC resources

These repositories may contain:
- Custom PSScriptAnalyzer rules in `/DscResource.AnalyzerRules/`
- Best practices specific to DSC resource development
- Additional validation patterns

### Integration

Community rules can be integrated by:

```powershell
# Download community module
Install-Module -Name DscResource.AnalyzerRules -Scope CurrentUser

# Use custom rules
$customRulesPath = (Get-Module DscResource.AnalyzerRules -ListAvailable).ModuleBase
Invoke-ScriptAnalyzer -Path $file -CustomRulePath $customRulesPath
```

## References

- [PSScriptAnalyzer GitHub](https://github.com/PowerShell/PSScriptAnalyzer)
- [PSScriptAnalyzer Rules Documentation](https://learn.microsoft.com/powershell/utility-modules/psscriptanalyzer/rules/readme)
- [DSC Community](https://github.com/dsccommunity)
- [PowerShell Security Best Practices](https://learn.microsoft.com/powershell/)
- [CVSS v3.1 Calculator](https://www.first.org/cvss/calculator/3.1)

## Change Log

### Version 1.0 - October 17, 2025
- Initial rule set with 35 security rules
- Coverage: Critical, High, Medium, and Low severity
- Categories: Code Execution, Credentials, Network, Input Validation, DSC
- PSScriptAnalyzer integration for 9 rules
- PowerShell-aware false positive reduction
