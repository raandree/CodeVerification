# PowerShell Security Detection Rules
# Version: 1.0
# Purpose: Comprehensive security analysis rules for PowerShell scripts and modules
# Based on: PowerShell security best practices, PSScriptAnalyzer, and MITRE ATT&CK Framework

## Code Execution Vulnerabilities

### PS001 - Invoke-Expression Usage
Id = 'PS001'
Name = 'Invoke-Expression Usage'
Severity = 'High'
Category = 'CodeExecution'
Description = 'Detects use of Invoke-Expression which can execute arbitrary code from strings'
ASTPattern = 'CommandAst'
CommandName = 'Invoke-Expression'
Aliases = 'iex'
Remediation = 'Replace Invoke-Expression with safer alternatives like & operator or dot-sourcing'
CVSS = 7.5

### PS002 - Script Block Injection
Id = 'PS002'
Name = 'Script Block Injection'
Severity = 'Medium'
Category = 'CodeExecution'
Description = 'Detects potential script block injection vulnerabilities. Note: Many PowerShell cmdlets like Where-Object and ForEach-Object legitimately require script blocks.'
ASTPattern = 'CommandAst|ScriptBlockExpressionAst'
CommandName = 'Invoke-Command'
Pattern = '\$.*\+.*\{|\{.*\$.*\}'
Exclusions = 'Where-Object|ForEach-Object|%|\?'
Remediation = 'Validate and sanitize inputs before passing to script blocks. Context analysis required for legitimate script block usage.'
CVSS = 6.8

### PS003 - Dynamic Code Generation
Id = 'PS003'
Name = 'Dynamic Code Generation'
Severity = 'Medium'
Category = 'CodeExecution'
Description = 'Detects dynamic code generation patterns that may be exploitable'
ASTPattern = 'InvokeMemberExpressionAst'
CommandName = 'Add-Type|Invoke-Expression'
Remediation = 'Use static code paths and avoid dynamic compilation when possible'
CVSS = 5.8

### PS004 - PowerShell Execution Policy Bypass
Id = 'PS004'
Name = 'Execution Policy Bypass'
Severity = 'High'
Category = 'CodeExecution'
Description = 'Detects attempts to bypass PowerShell execution policy'
ASTPattern = 'CommandAst'
CommandName = 'Set-ExecutionPolicy'
Parameters = '-ExecutionPolicy Bypass|-ExecutionPolicy Unrestricted'
Remediation = 'Enforce proper execution policies and avoid bypassing security controls'
CVSS = 6.8

## Credential Security Issues

### PS005 - Hardcoded Credentials
Id = 'PS005'
Name = 'Hardcoded Credentials'
Severity = 'Critical'
Category = 'CredentialSecurity'
Description = 'Detects actual hardcoded passwords, API keys, or other credentials in scripts. Excludes placeholder values and example patterns.'
ASTPattern = 'StringConstantExpressionAst|VariableExpressionAst'
Pattern = 'password\s*[:=]\s*["\'][^"\'\*]{6,}["\']|apikey\s*[:=]\s*["\'][^"\'\*]{10,}["\']|secret\s*[:=]\s*["\'][^"\'\*]{8,}["\']'
Exclusions = 'password\s*[:=]\s*["\'](\*+|example|placeholder|changeme|password)["\']'
Remediation = 'Use secure credential storage mechanisms like Windows Credential Manager or Azure Key Vault'
CVSS = 9.8

### PS006 - Credential Logging
Id = 'PS006'
Name = 'Credential Logging'
Severity = 'High'
Category = 'CredentialSecurity'
Description = 'Detects actual logging of credential objects or plaintext passwords. Note: Logging usernames without passwords is acceptable for debugging.'
ASTPattern = 'CommandAst'
CommandName = 'Write-Host|Write-Output|Write-Verbose|Write-Debug|Out-File|Add-Content'
Pattern = '\$credential|\$cred|\.GetNetworkCredential\(\)|\.Password|ConvertFrom-SecureString'
Remediation = 'Never log credential objects or plaintext passwords. Log usernames only if needed for debugging.'
CVSS = 8.5

### PS007 - Insecure Credential Storage
Id = 'PS007'
Name = 'Insecure Credential Storage'
Severity = 'High'
Category = 'CredentialSecurity'
Description = 'Detects insecure credential storage practices'
ASTPattern = 'CommandAst'
CommandName = 'ConvertTo-SecureString'
Parameters = '-AsPlainText'
Remediation = 'Use secure credential storage and avoid converting plain text to SecureString'
CVSS = 7.3

## Input Validation Issues

### PS008 - SQL Injection Risk
Id = 'PS008'
Name = 'SQL Injection Risk'
Severity = 'High'
Category = 'InputValidation'
Description = 'Detects potential SQL injection vulnerabilities in database queries'
ASTPattern = 'StringConstantExpressionAst'
Pattern = 'SELECT.*\$|INSERT.*\$|UPDATE.*\$|DELETE.*\$'
Remediation = 'Use parameterized queries and input validation'
CVSS = 8.2

### PS009 - Command Injection Risk
Id = 'PS009'
Name = 'Command Injection Risk'
Severity = 'High'
Category = 'InputValidation'
Description = 'Detects potential command injection vulnerabilities'
ASTPattern = 'CommandAst'
CommandName = 'Start-Process|Invoke-Item|cmd.exe|powershell.exe'
Pattern = '\$.*\+.*\$'
Remediation = 'Validate and sanitize all user inputs before using in commands'
CVSS = 8.0

### PS010 - Path Traversal Risk
Id = 'PS010'
Name = 'Path Traversal Risk'
Severity = 'Medium'
Category = 'InputValidation'
Description = 'Detects potential path traversal vulnerabilities'
ASTPattern = 'StringConstantExpressionAst'
Pattern = '\.\./|\.\.\\'
Remediation = 'Validate file paths and use absolute paths where possible'
CVSS = 6.5

## Data Exposure Issues

### PS011 - Sensitive Data in Logs
Id = 'PS011'
Name = 'Sensitive Data in Logs'
Severity = 'Critical'
Category = 'DataExposure'
Description = 'Detects exposure of plaintext passwords, security keys, or tokens in log files. Note: Logging usernames or IDs is acceptable for debugging purposes.'
ASTPattern = 'CommandAst'
CommandName = 'Write-Host|Write-Output|Write-EventLog|Out-File'
Pattern = 'password\s*[:=]\s*["\'][^"\']*[^*]["\']|secret\s*[:=]\s*["\'][^"\']*[^*]["\']|token\s*[:=]\s*["\'][^"\']*[^*]["\']|key\s*[:=]\s*["\'][^"\']*[^*]["\']'
Remediation = 'Never log plaintext passwords, security keys, or tokens. Use placeholder values or masking.'
CVSS = 9.2

### PS012 - Debug Information Exposure
Id = 'PS012'
Name = 'Debug Information Exposure'
Severity = 'Low'
Category = 'DataExposure'
Description = 'Detects debug information that may expose sensitive details'
ASTPattern = 'CommandAst'
CommandName = 'Write-Debug|Write-Verbose'
Remediation = 'Remove debug statements from production code'
CVSS = 3.2

## Obfuscation and Evasion

### PS013 - Character Substitution Obfuscation
Id = 'PS013'
Name = 'Character Substitution Obfuscation'
Severity = 'Low'
Category = 'Obfuscation'
Description = 'Detects character substitution obfuscation techniques. Note: PowerShell often requires character escaping for string handling, which is not necessarily malicious.'
ASTPattern = 'StringConstantExpressionAst'
Pattern = '\\u[0-9a-fA-F]{4}|\\x[0-9a-fA-F]{2}'
Context = 'Requires manual analysis - character escaping is common in PowerShell for legitimate string manipulation'
Remediation = 'Review context and intent of character escaping before flagging as security issue'
CVSS = 3.0

### PS014 - Base64 Encoding
Id = 'PS014'
Name = 'Base64 Encoding'
Severity = 'Medium'
Category = 'Obfuscation'
Description = 'Detects use of Base64 encoding which may indicate obfuscation'
ASTPattern = 'CommandAst'
CommandName = 'FromBase64String|ToBase64String'
Remediation = 'Review Base64 encoded content for legitimate use'
CVSS = 4.8

### PS015 - High Entropy Strings
Id = 'PS015'
Name = 'High Entropy Strings'
Severity = 'Informational'
Category = 'Obfuscation'
Description = 'Detects strings with high entropy that may indicate encoding or encryption. Note: PowerShell naturally uses descriptive strings with higher entropy. Requires manual analysis to determine security relevance.'
ASTPattern = 'StringConstantExpressionAst'
Pattern = '[A-Za-z0-9+/]{40,}={0,2}'
Remediation = 'Analyze context of high entropy strings. Not inherently malicious in PowerShell.'
CVSS = 2.0

## Network Security Issues

### PS016 - Insecure Network Protocols
Id = 'PS016'
Name = 'Insecure Network Protocols'
Severity = 'Medium'
Category = 'NetworkSecurity'
Description = 'Detects use of insecure network protocols'
ASTPattern = 'StringConstantExpressionAst'
Pattern = 'http://|ftp://|telnet://'
Remediation = 'Use secure protocols like HTTPS, SFTP, and SSH'
CVSS = 5.2

### PS017 - Remote Code Execution
Id = 'PS017'
Name = 'Remote Code Execution'
Severity = 'High'
Category = 'NetworkSecurity'
Description = 'Detects potential remote code execution capabilities'
ASTPattern = 'CommandAst'
CommandName = 'Invoke-Command|Enter-PSSession|New-PSSession'
Remediation = 'Ensure proper authentication and authorization for remote execution'
CVSS = 7.8

### PS018 - Hostname or Domain Checks
Id = 'PS018'
Name = 'Hostname or Domain Checks'
Severity = 'Informational'
Category = 'NetworkSecurity'
Description = 'Detects hostname or domain validation. Note: These checks are expected and necessary in configuration management and infrastructure code.'
ASTPattern = 'CommandAst'
CommandName = 'Test-Connection|Resolve-DnsName|Get-WmiObject|Get-ComputerInfo'
Pattern = 'Win32_ComputerSystem|hostname|domain|computername'
Context = 'Normal in configuration management and infrastructure automation scripts'
Remediation = 'Review context - hostname/domain checks are typically legitimate in infrastructure code'
CVSS = 1.5

## Cryptography Issues

### PS019 - Weak Cryptographic Algorithms
Id = 'PS019'
Name = 'Weak Cryptographic Algorithms'
Severity = 'Medium'
Category = 'Cryptography'
Description = 'Detects use of weak or deprecated cryptographic algorithms'
ASTPattern = 'StringConstantExpressionAst'
Pattern = 'MD5|SHA1|DES|RC4'
Remediation = 'Use strong cryptographic algorithms like AES and SHA-256'
CVSS = 5.5

### PS020 - Insecure Random Number Generation
Id = 'PS020'
Name = 'Insecure Random Number Generation'
Severity = 'Medium'
Category = 'Cryptography'
Description = 'Detects use of weak random number generation'
ASTPattern = 'CommandAst'
CommandName = 'Get-Random'
Remediation = 'Use cryptographically secure random number generators for security-sensitive operations'
CVSS = 4.5

## Registry and System Modification

### PS021 - Registry Modification
Id = 'PS021'
Name = 'Registry Modification'
Severity = 'Medium'
Category = 'SystemModification'
Description = 'Detects registry modifications that may affect security'
ASTPattern = 'CommandAst'
CommandName = 'Set-ItemProperty|New-ItemProperty|Remove-ItemProperty'
Remediation = 'Review registry modifications for security implications'
CVSS = 5.8

### PS022 - Service Manipulation
Id = 'PS022'
Name = 'Service Manipulation'
Severity = 'High'
Category = 'SystemModification'
Description = 'Detects service creation, modification, or deletion'
ASTPattern = 'CommandAst'
CommandName = 'New-Service|Set-Service|Remove-Service|Stop-Service|Start-Service'
Remediation = 'Ensure service operations are authorized and necessary'
CVSS = 7.0

## File System Operations

### PS023 - Suspicious File Operations
Id = 'PS023'
Name = 'Suspicious File Operations'
Severity = 'Medium'
Category = 'FileSystem'
Description = 'Detects potentially suspicious file system operations'
ASTPattern = 'CommandAst'
CommandName = 'Remove-Item|Move-Item|Copy-Item'
Pattern = '-Force|-Recurse'
Remediation = 'Review file operations for legitimate business purpose'
CVSS = 5.0

### PS024 - Temporary File Usage
Id = 'PS024'
Name = 'Temporary File Usage'
Severity = 'Low'
Category = 'FileSystem'
Description = 'Detects use of temporary files that may pose security risks'
ASTPattern = 'StringConstantExpressionAst'
Pattern = '\$env:TEMP|\$env:TMP|\\Temp\\|\\tmp\\'
Remediation = 'Ensure temporary files are properly secured and cleaned up'
CVSS = 3.8

## Error Handling and Information Disclosure

### PS025 - Insufficient Error Handling
Id = 'PS025'
Name = 'Insufficient Error Handling'
Severity = 'Low'
Category = 'ErrorHandling'
Description = 'Detects missing or insufficient error handling'
ASTPattern = 'TryStatementAst|CatchClauseAst'
Remediation = 'Implement comprehensive error handling to prevent information disclosure'
CVSS = 3.5

### PS026 - Information Disclosure in Errors
Id = 'PS026'
Name = 'Information Disclosure in Errors'
Severity = 'Medium'
Category = 'ErrorHandling'
Description = 'Detects error handling that may disclose sensitive information'
ASTPattern = 'CommandAst'
CommandName = 'Write-Error|throw'
Remediation = 'Sanitize error messages to prevent information disclosure'
CVSS = 4.8