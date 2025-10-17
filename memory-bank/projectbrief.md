# Project Brief: PowerShell Security Code Review System

## Project Overview
A comprehensive security analysis system for PowerShell modules that identifies malicious code, security vulnerabilities, and coding standard violations.

## Primary Objectives
1. Scan PowerShell modules in the `source/` directory for security issues and malicious code
2. Implement detection rules based on industry security standards and PSScriptAnalyzer
3. Generate automated security scanning scripts using PSScriptAnalyzer and Pester
4. Create comprehensive security reports (executive summary + detailed per-module reports)
5. Document the entire project structure and processes

## Scope
- **In Scope**: 
  - Security analysis of all PowerShell modules in `source/` folder
  - Detection of malicious patterns, vulnerable code, and security risks
  - Automated scanning infrastructure
  - Comprehensive reporting
  - Full project documentation
  
- **Out of Scope**:
  - Code remediation (recommendations only)
  - Runtime behavior analysis
  - Network-based detection

## Success Criteria
1. All PowerShell modules scanned and analyzed
2. Detection rules defined and documented
3. Automated scanning scripts operational
4. Executive summary report generated
5. Detailed per-module reports created
6. Complete project documentation in place

## Key Stakeholders
- Security team: Needs actionable vulnerability reports
- Development team: Needs remediation guidance
- Management: Needs executive summary with risk assessment

## Timeline
Execute all prompts sequentially until completion

## Constraints
- Focus on static code analysis
- Balance false positives with security coverage
- PowerShell-specific context (credentials handling is common)
- High entropy strings are normal in PowerShell
