# Product Context: PowerShell Security Code Review System

## Why This Project Exists
Organizations need to verify the security of PowerShell modules before deployment. PowerShell scripts can:
- Execute arbitrary code
- Access sensitive systems
- Exfiltrate data
- Create backdoors
- Escalate privileges

Without proper security review, malicious or vulnerable code can compromise entire environments.

## Problems It Solves
1. **Manual Review Inefficiency**: Manual code review of PowerShell modules is time-consuming and error-prone
2. **Unknown Risks**: Organizations often deploy third-party modules without security analysis
3. **Malicious Code Detection**: Need to identify intentional backdoors, malware, and exploits
4. **Vulnerability Identification**: Detect common security weaknesses and coding anti-patterns
5. **Compliance**: Meet security audit requirements for code review

## How It Should Work

### Input
- PowerShell modules from `source/` directory
- Security detection rules
- Industry best practices and standards

### Process
1. Load detection rules from knowledge base
2. Parse PowerShell code using AST (Abstract Syntax Tree)
3. Apply PSScriptAnalyzer rules
4. Match patterns against security detection rules
5. Classify findings by severity (Critical, High, Medium, Low)
6. Generate reports with actionable remediation guidance

### Output
- **Executive Summary**: High-level overview of security posture across all modules
- **Detailed Reports**: Per-module analysis with specific findings, locations, and remediation steps
- **Actionable Data**: CVSS scores, severity ratings, and prioritized recommendations

## User Experience Goals

### For Security Teams
- Clear visibility into security risks
- Prioritized findings by severity
- Evidence-based reports with code locations
- CVSS scoring for risk quantification

### For Development Teams
- Specific remediation guidance
- Understanding of security context
- Reduced false positives
- Clear explanations of security issues

### For Management
- Executive-level risk summary
- Compliance documentation
- Risk prioritization
- Resource allocation guidance

## Key Principles
1. **Accuracy**: Minimize false positives while maintaining security coverage
2. **Context-Aware**: Understand PowerShell-specific patterns (e.g., credential handling)
3. **Actionable**: Every finding includes remediation guidance
4. **Comprehensive**: Cover code execution, data exfiltration, privilege escalation, and more
5. **Automated**: Repeatable process that can be run consistently
