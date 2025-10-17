# Security Detection Rules

This directory contains the security detection rules used for analyzing PowerShell code.

## Files

### SecurityRules.ps1
The main rules file containing 55 comprehensive security detection rules organized into categories:

- **Code Execution**: Rules for detecting dangerous command execution patterns
- **Data Exfiltration**: Rules for detecting network-based data exfiltration
- **Credential Exposure**: Rules for detecting hardcoded passwords and exposed credentials
- **Privilege Escalation**: Rules for detecting elevation attempts
- **Obfuscation**: Rules for detecting code obfuscation techniques
- **Persistence**: Rules for detecting persistence mechanisms
- **Anti-Analysis**: Rules for detecting evasion techniques
- **Lateral Movement**: Rules for detecting remote execution
- **Defense Evasion**: Rules for detecting security control bypasses
- **File Operations**: Rules for detecting suspicious file operations
- **Cryptography**: Rules for detecting weak crypto or ransomware patterns
- **Process Manipulation**: Rules for detecting process injection
- **Download & Execute**: Rules for detecting download-execute chains
- **Best Practices**: Rules for code quality violations

Each rule includes:
- **Id**: Unique identifier (e.g., PS001)
- **Name**: Descriptive name
- **Severity**: Critical, High, Medium, or Low
- **Category**: Security category
- **Description**: What the rule detects
- **ASTPattern**: AST node type for detection (if applicable)
- **CommandName**: PowerShell command to detect (if applicable)
- **Pattern**: Regex pattern for detection (if applicable)
- **Remediation**: How to fix the issue
- **CVSS**: Common Vulnerability Scoring System score (0-10)

### RuleContextGuidelines.md
Comprehensive documentation for applying rules in a PowerShell-specific context:

- Explains PowerShell idioms that may trigger rules but are acceptable
- Provides context for credential handling (username logging vs password logging)
- Clarifies when high entropy strings are normal
- Documents how to handle security tools vs actual malware
- Includes severity adjustment matrix for context-aware assessment

## Usage

The rules are loaded automatically by `Invoke-SecurityScan.ps1`:

```powershell
# Rules are loaded into the $SecurityRules variable
. ".\Rules\SecurityRules.ps1"
$rules = $SecurityRules
```

## Adding New Rules

To add a new rule, follow this format:

```powershell
@{
    Id = 'PSXXX'  # Use next available number
    Name = 'Rule Name'
    Severity = 'Critical|High|Medium|Low'
    Category = 'Category'
    Description = 'What this detects'
    ASTPattern = 'CommandAst'  # Optional: AST node type
    CommandName = 'Command-Name'  # Optional: Command to detect
    Pattern = 'regex pattern'  # Optional: Regex pattern
    Remediation = 'How to fix it'
    CVSS = 5.0  # CVSS score 0-10
}
```

Add the new rule to the `$SecurityRules` array in `SecurityRules.ps1`.

## Rule Categories

Rules are organized by security category to help classify findings:

- **CodeExecution**: Dynamic code execution risks
- **DataExfiltration**: Data leakage via network
- **CredentialExposure**: Passwords, keys, tokens in code
- **PrivilegeEscalation**: Elevation and UAC bypass
- **Obfuscation**: Hidden or obfuscated code
- **Persistence**: Auto-start mechanisms
- **AntiAnalysis**: VM detection, debugger detection
- **LateralMovement**: Remote execution capabilities
- **DefenseEvasion**: Security control bypasses
- **FileOperation**: Suspicious file operations
- **Cryptography**: Weak crypto or encryption patterns
- **ProcessManipulation**: Process injection techniques
- **DownloadExecute**: Malware download-execute patterns
- **BestPractice**: Code quality issues

## Context-Aware Analysis

When applying rules, always consider:

1. **Module Purpose**: Security tools will trigger many rules intentionally
2. **PowerShell Idioms**: Long cmdlet names and verbose syntax are normal
3. **Credential Patterns**: PSCredential and SecureString are secure patterns
4. **False Positives**: Review findings in context before reporting

See `RuleContextGuidelines.md` for detailed guidance.
