<#
.SYNOPSIS
    PowerShell Security Detection Rules

.DESCRIPTION
    Comprehensive security detection rules for PowerShell code analysis.
    Combines industry best practices, PSScriptAnalyzer rules, and DSC community standards.
    
    Rules are PowerShell-aware and tuned to minimize false positives while identifying
    real security issues.
    
    POWERSHELL-SPECIFIC CONTEXT:
    - SecureString and PSCredential usage is NORMAL and CORRECT
    - Username/ID logging is ACCEPTABLE for debugging
    - High entropy strings are COMMON in PowerShell (descriptive naming)
    - Credential parameters in DSC resources are EXPECTED
    - Focus on ACTUAL security issues, not PowerShell idioms

.NOTES
    Author: Security Review System
    Date: October 17, 2025
    Version: 1.1
    
    Version History:
    1.1 - Realigned PS029 (Base64) and PS035 (Sensitive Logging) for PowerShell context
    1.0 - Initial rule set
#>

# Detection Rules Array
$SecurityRules = @(

    # ============================================================================
    # CRITICAL SEVERITY RULES - Immediate Security Risk
    # ============================================================================

    @{
        Id = 'PS001'
        Name = 'Invoke-Expression Usage'
        Severity = 'Critical'
        Category = 'CodeExecution'
        Description = 'Detects use of Invoke-Expression which can execute arbitrary code from strings. This is extremely dangerous as it can execute malicious code if the string input is not properly validated.'
        ASTPattern = 'CommandAst'
        CommandName = 'Invoke-Expression'
        Aliases = @('iex')
        Remediation = 'Replace Invoke-Expression with safer alternatives: Use & (call operator) with validated script paths, use . (dot-source) for script files, or use [ScriptBlock]::Create() with proper validation. Never use with user input.'
        CVSS = 9.8
        PSScriptAnalyzerRule = 'PSAvoidUsingInvokeExpression'
    }

    @{
        Id = 'PS002'
        Name = 'ConvertTo-SecureString with PlainText'
        Severity = 'Critical'
        Category = 'CredentialExposure'
        Description = 'Detects conversion of plain text strings to SecureString using -AsPlainText -Force. This indicates hardcoded credentials in the source code.'
        ASTPattern = 'CommandAst'
        CommandName = 'ConvertTo-SecureString'
        ParameterCheck = '-AsPlainText'
        Remediation = 'Never hardcode credentials. Use Windows Credential Manager, Azure Key Vault, or encrypted credential files. For testing, use Get-Credential interactively or certificate-based authentication.'
        CVSS = 9.1
        PSScriptAnalyzerRule = 'PSAvoidUsingConvertToSecureStringWithPlainText'
    }

    @{
        Id = 'PS003'
        Name = 'Plaintext Password in Code'
        Severity = 'Critical'
        Category = 'CredentialExposure'
        Description = 'Detects hardcoded passwords in variable assignments or strings. Searches for common password variable names and patterns.'
        ASTPattern = 'VariableExpression'
        PatternMatch = '(password|pwd|passwd|secret|apikey|api_key|token|access_key)\s*=\s*[''"][^''"]+'
        Remediation = 'Remove hardcoded credentials from code. Use secure credential storage: Windows Credential Manager, Azure Key Vault, encrypted files with DPAPI, or certificate-based authentication.'
        CVSS = 9.8
        PSScriptAnalyzerRule = 'PSAvoidUsingPlainTextForPassword'
    }

    @{
        Id = 'PS004'
        Name = 'Unrestricted Execution Policy Set'
        Severity = 'Critical'
        Category = 'SecurityPolicy'
        Description = 'Detects setting execution policy to Unrestricted or Bypass, which allows any script to run without signature verification.'
        ASTPattern = 'CommandAst'
        CommandName = 'Set-ExecutionPolicy'
        ParameterCheck = 'Unrestricted|Bypass'
        Remediation = 'Use RemoteSigned or AllSigned execution policies. Sign trusted scripts with a code-signing certificate. Never set Unrestricted in production environments.'
        CVSS = 8.6
    }

    @{
        Id = 'PS005'
        Name = 'Add-Type with Inline C# Code'
        Severity = 'Critical'
        Category = 'CodeExecution'
        Description = 'Detects Add-Type with inline C# code which can be used to load malicious compiled code or bypass PowerShell security mechanisms.'
        ASTPattern = 'CommandAst'
        CommandName = 'Add-Type'
        ParameterCheck = '-TypeDefinition|-MemberDefinition'
        Remediation = 'Review all Add-Type usage carefully. Ensure C# code is from trusted sources only. Consider using pre-compiled assemblies with strong naming. Validate all inputs to C# code.'
        CVSS = 8.8
    }

    @{
        Id = 'PS006'
        Name = 'Downloadstring or DownloadFile Usage'
        Severity = 'Critical'
        Category = 'NetworkSecurity'
        Description = 'Detects downloading and potentially executing code from the internet using WebClient methods. Common malware technique.'
        ASTPattern = 'MemberExpression'
        MemberName = 'DownloadString|DownloadFile|DownloadData'
        Remediation = 'Validate all download sources using HTTPS only. Verify file hashes before execution. Use Invoke-WebRequest with proper error handling. Never execute downloaded content without validation.'
        CVSS = 9.3
    }

    # ============================================================================
    # HIGH SEVERITY RULES - Significant Security Concern
    # ============================================================================

    @{
        Id = 'PS007'
        Name = 'Write-Host for Sensitive Data'
        Severity = 'High'
        Category = 'InformationDisclosure'
        Description = 'Detects Write-Host which may expose sensitive information. Unlike Write-Verbose/Write-Debug, Write-Host cannot be suppressed and goes directly to console.'
        ASTPattern = 'CommandAst'
        CommandName = 'Write-Host'
        ContextCheck = 'password|credential|secret|key|token'
        Remediation = 'Use Write-Verbose, Write-Debug, or proper logging framework. Never output credentials, keys, or tokens. Use Write-Information for informational messages with proper streams.'
        CVSS = 7.5
        PSScriptAnalyzerRule = 'PSAvoidUsingWriteHost'
    }

    @{
        Id = 'PS008'
        Name = 'Missing Parameter Validation'
        Severity = 'High'
        Category = 'InputValidation'
        Description = 'Detects functions with parameters that accept user input without validation attributes like ValidateSet, ValidatePattern, ValidateScript, or ValidateRange.'
        ASTPattern = 'ParameterAst'
        ValidationCheck = 'Missing'
        Remediation = 'Add validation attributes to all parameters: [ValidateNotNullOrEmpty()], [ValidateSet()], [ValidatePattern()], [ValidateScript()], or [ValidateRange()]. Implement input sanitization.'
        CVSS = 7.3
    }

    @{
        Id = 'PS009'
        Name = 'SQL Query Concatenation'
        Severity = 'High'
        Category = 'InjectionAttack'
        Description = 'Detects SQL query string concatenation which is vulnerable to SQL injection attacks.'
        ASTPattern = 'BinaryExpression'
        ContextCheck = 'SELECT|INSERT|UPDATE|DELETE|EXEC|EXECUTE'
        Remediation = 'Use parameterized queries or stored procedures. Use Invoke-SqlCmd with -Query parameter and SQL parameters (@param). Never concatenate user input into SQL strings.'
        CVSS = 8.6
    }

    @{
        Id = 'PS010'
        Name = 'Unencrypted Remote Connection'
        Severity = 'High'
        Category = 'NetworkSecurity'
        Description = 'Detects PSSession or remote commands without -UseSSL or with -AllowUnencryptedAuthentication.'
        ASTPattern = 'CommandAst'
        CommandName = 'New-PSSession|Enter-PSSession|Invoke-Command'
        ParameterCheck = 'AllowUnencryptedAuthentication|(?!UseSSL)'
        Remediation = 'Always use -UseSSL for remote connections. Configure WinRM with HTTPS. Use certificate-based authentication. Never allow unencrypted authentication over network.'
        CVSS = 7.4
    }

    @{
        Id = 'PS011'
        Name = 'Credential in Logs or Output'
        Severity = 'High'
        Category = 'CredentialExposure'
        Description = 'Detects credential objects or secure strings being written to logs, console, or files in plaintext. Checks for ToString() on SecureString or plaintext credential properties.'
        ASTPattern = 'CommandAst'
        CommandName = 'Write-*|Out-File|Set-Content|Add-Content'
        ContextCheck = '\$.*credential.*GetNetworkCredential\(\)|\$.*password.*ToString\(\)'
        Remediation = 'Never log credential objects or their plaintext values. Use [System.Management.Automation.PSCredential] securely. Log only non-sensitive identifiers like usernames (if needed for debugging).'
        CVSS = 8.2
    }

    @{
        Id = 'PS012'
        Name = 'Cmdlet with -Force Parameter'
        Severity = 'High'
        Category = 'DangerousOperation'
        Description = 'Detects use of -Force parameter which bypasses confirmation prompts and can cause destructive operations.'
        ASTPattern = 'CommandAst'
        CommandName = 'Remove-*|Stop-*|Disable-*|Set-ExecutionPolicy'
        ParameterCheck = '-Force'
        Remediation = 'Review all -Force usage. Implement proper error handling and validation before destructive operations. Use -WhatIf and -Confirm for testing. Consider user confirmation for critical actions.'
        CVSS = 6.5
    }

    @{
        Id = 'PS013'
        Name = 'Start-Process with Hidden Window'
        Severity = 'High'
        Category = 'StealthyExecution'
        Description = 'Detects Start-Process with -WindowStyle Hidden which can hide malicious activity from users.'
        ASTPattern = 'CommandAst'
        CommandName = 'Start-Process'
        ParameterCheck = '-WindowStyle\s+Hidden'
        Remediation = 'Avoid hiding windows unless absolutely necessary. Log all hidden process executions. Validate executable paths. Consider using Jobs for background processing instead.'
        CVSS = 7.1
    }

    # ============================================================================
    # MEDIUM SEVERITY RULES - Should Be Reviewed
    # ============================================================================

    @{
        Id = 'PS014'
        Name = 'Disabled Certificate Validation'
        Severity = 'Medium'
        Category = 'NetworkSecurity'
        Description = 'Detects disabling SSL/TLS certificate validation which allows man-in-the-middle attacks.'
        ASTPattern = 'AssignmentStatement'
        PatternMatch = 'ServerCertificateValidationCallback.*{\s*\$true\s*}'
        Remediation = 'Never disable certificate validation in production. Install proper certificates. For development, use self-signed certificates properly added to trust store.'
        CVSS = 6.8
    }

    @{
        Id = 'PS015'
        Name = 'Weak Cryptographic Algorithm'
        Severity = 'Medium'
        Category = 'Cryptography'
        Description = 'Detects use of weak or deprecated cryptographic algorithms like MD5, SHA1, DES, RC2.'
        ASTPattern = 'TypeExpression'
        TypeName = 'MD5|SHA1CryptoServiceProvider|DESCryptoServiceProvider|RC2'
        Remediation = 'Use strong cryptography: SHA256 or SHA512 for hashing, AES for encryption. Use .NET Security.Cryptography classes with current best practices.'
        CVSS = 5.9
    }

    @{
        Id = 'PS016'
        Name = 'Start-Sleep with Long Duration'
        Severity = 'Medium'
        Category = 'SuspiciousBehavior'
        Description = 'Detects Start-Sleep with very long durations which may indicate evasion techniques or malicious waiting behavior.'
        ASTPattern = 'CommandAst'
        CommandName = 'Start-Sleep'
        ParameterCheck = '-Seconds\s+[6-9]\d{2,}|-Seconds\s+\d{4,}'
        Remediation = 'Review purpose of long sleep durations. Use scheduled tasks or proper wait mechanisms. Consider Jobs for long-running operations.'
        CVSS = 4.3
    }

    @{
        Id = 'PS017'
        Name = 'Empty Catch Block'
        Severity = 'Medium'
        Category = 'ErrorHandling'
        Description = 'Detects empty catch blocks which suppress errors and hide security issues or failures.'
        ASTPattern = 'CatchClause'
        BodyCheck = 'Empty'
        Remediation = 'Implement proper error handling. Log errors appropriately. Use Write-Error, throw, or proper logging. At minimum, use Write-Verbose in catch blocks.'
        CVSS = 5.3
        PSScriptAnalyzerRule = 'PSAvoidUsingEmptyCatchBlock'
    }

    @{
        Id = 'PS018'
        Name = 'Positional Parameters in Production Code'
        Severity = 'Medium'
        Category = 'CodeQuality'
        Description = 'Detects use of positional parameters without explicit parameter names, which reduces code clarity and can lead to errors.'
        ASTPattern = 'CommandAst'
        PositionalCheck = 'True'
        Remediation = 'Always use named parameters in production code for clarity and maintainability. Positional parameters acceptable only in interactive sessions.'
        CVSS = 3.1
        PSScriptAnalyzerRule = 'PSAvoidUsingPositionalParameters'
    }

    @{
        Id = 'PS019'
        Name = 'Registry Modification'
        Severity = 'Medium'
        Category = 'SystemModification'
        Description = 'Detects registry modifications which can change system behavior or security settings.'
        ASTPattern = 'CommandAst'
        CommandName = 'Set-ItemProperty|New-ItemProperty|Remove-ItemProperty|New-Item'
        PathCheck = 'HKLM:|HKCU:|Registry::'
        Remediation = 'Document all registry changes. Validate registry paths and values. Implement rollback capability. Test thoroughly in non-production environments.'
        CVSS = 6.1
    }

    @{
        Id = 'PS020'
        Name = 'Scheduled Task Creation'
        Severity = 'Medium'
        Category = 'Persistence'
        Description = 'Detects creation of scheduled tasks which can be used for persistence or privilege escalation.'
        ASTPattern = 'CommandAst'
        CommandName = 'Register-ScheduledTask|New-ScheduledTask'
        Remediation = 'Review all scheduled task creation. Validate task actions and principals. Implement least privilege. Log task registration events.'
        CVSS = 6.5
    }

    @{
        Id = 'PS021'
        Name = 'Service Installation or Modification'
        Severity = 'Medium'
        Category = 'Persistence'
        Description = 'Detects Windows service installation or modification which can be used for persistence.'
        ASTPattern = 'CommandAst'
        CommandName = 'New-Service|Set-Service|sc.exe'
        Remediation = 'Validate service binaries with digital signatures. Implement least privilege for service accounts. Log service changes. Review service configuration thoroughly.'
        CVSS = 6.8
    }

    # ============================================================================
    # LOW SEVERITY RULES - Best Practice Violations
    # ============================================================================

    @{
        Id = 'PS022'
        Name = 'Missing Function Documentation'
        Severity = 'Low'
        Category = 'CodeQuality'
        Description = 'Detects functions without comment-based help or documentation.'
        ASTPattern = 'FunctionDefinition'
        DocumentationCheck = 'Missing'
        Remediation = 'Add comment-based help to all functions with .SYNOPSIS, .DESCRIPTION, .PARAMETER, and .EXAMPLE sections.'
        CVSS = 0.0
        PSScriptAnalyzerRule = 'PSProvideCommentHelp'
    }

    @{
        Id = 'PS023'
        Name = 'Using Aliases in Scripts'
        Severity = 'Low'
        Category = 'CodeQuality'
        Description = 'Detects use of cmdlet aliases in script files which reduces readability and portability.'
        ASTPattern = 'CommandAst'
        AliasCheck = 'True'
        Remediation = 'Use full cmdlet names in scripts. Aliases acceptable only in interactive sessions. Common aliases: where (Where-Object), foreach (ForEach-Object), select (Select-Object).'
        CVSS = 0.0
        PSScriptAnalyzerRule = 'PSAvoidUsingCmdletAliases'
    }

    @{
        Id = 'PS024'
        Name = 'Missing Output Type Attribute'
        Severity = 'Low'
        Category = 'CodeQuality'
        Description = 'Detects functions without [OutputType()] attribute which helps with discoverability and pipeline usage.'
        ASTPattern = 'FunctionDefinition'
        AttributeCheck = 'OutputType'
        Remediation = 'Add [OutputType([Type])] attribute to all functions that return objects. Improves IntelliSense and pipeline behavior.'
        CVSS = 0.0
    }

    @{
        Id = 'PS025'
        Name = 'Should Process Not Implemented'
        Severity = 'Low'
        Category = 'CodeQuality'
        Description = 'Detects functions using ShouldProcess parameter but not implementing ShouldProcess pattern.'
        ASTPattern = 'FunctionDefinition'
        PatternCheck = 'ShouldProcess'
        Remediation = 'Implement ShouldProcess properly: [CmdletBinding(SupportsShouldProcess)] and if ($PSCmdlet.ShouldProcess($target)) { ... }'
        CVSS = 0.0
        PSScriptAnalyzerRule = 'PSShouldProcess'
    }

    # ============================================================================
    # DSC-SPECIFIC RULES
    # ============================================================================

    @{
        Id = 'PS026'
        Name = 'DSC Resource Without Test Method'
        Severity = 'Medium'
        Category = 'DSCQuality'
        Description = 'Detects DSC resources that may not properly implement the Test-TargetResource function.'
        ASTPattern = 'FunctionDefinition'
        FunctionName = 'Test-TargetResource'
        Remediation = 'Implement Test-TargetResource to accurately detect configuration drift. Return $true only when in desired state. Follow DSC community guidelines.'
        CVSS = 4.0
    }

    @{
        Id = 'PS027'
        Name = 'DSC Credential in Clear Text'
        Severity = 'Critical'
        Category = 'DSCCredential'
        Description = 'Detects DSC configuration data with credentials not properly encrypted or using CIM instances incorrectly.'
        ASTPattern = 'VariableExpression'
        ContextCheck = 'PsDscRunAsCredential|Credential'
        Remediation = 'Use encrypted MOF files with certificates. Implement credential encryption in DSC configuration data. Use Group Managed Service Accounts (gMSA) when possible.'
        CVSS = 9.2
    }

    @{
        Id = 'PS028'
        Name = 'Missing Import-DscResource'
        Severity = 'Low'
        Category = 'DSCQuality'
        Description = 'Detects DSC configurations that use resources without explicit Import-DscResource statement.'
        ASTPattern = 'ConfigurationDefinition'
        ImportCheck = 'Missing'
        Remediation = 'Always use Import-DscResource -ModuleName at the beginning of configuration. Specify -ModuleVersion for version pinning.'
        CVSS = 0.0
    }

    # ============================================================================
    # ADVANCED DETECTION RULES
    # ============================================================================

    @{
        Id = 'PS029'
        Name = 'Base64 Encoded Content'
        Severity = 'Medium'
        Category = 'Obfuscation'
        Description = 'Detects Base64 encoded strings which may hide malicious commands or payloads. IMPORTANT: This is flagged for MANUAL REVIEW ONLY. Many legitimate PowerShell uses exist (embedded certificates, binary data, API tokens). Only critical if context suggests obfuscation of commands.'
        ASTPattern = 'StringConstant'
        PatternMatch = '[A-Za-z0-9+/]{100,}={0,2}'
        ContextCheck = 'FromBase64String|-EncodedCommand'
        Remediation = 'MANUAL REVIEW REQUIRED: Decode and analyze Base64 content. Legitimate uses: embedded files, certificates, API tokens, binary data. Flag as critical ONLY if used for command obfuscation or malicious payload hiding. Document purpose in code comments.'
        CVSS = 5.5
        RequiresManualReview = $true
        FalsePositiveRisk = 'High'
    }

    @{
        Id = 'PS030'
        Name = 'Dynamic Function or Variable Creation'
        Severity = 'High'
        Category = 'CodeExecution'
        Description = 'Detects dynamic creation of functions or variables using Set-Item, New-Item in function: or variable: drives.'
        ASTPattern = 'CommandAst'
        CommandName = 'Set-Item|New-Item'
        PathCheck = 'function:|variable:'
        Remediation = 'Avoid dynamic function creation. Use standard function definitions. Review for code injection or malicious dynamic behavior.'
        CVSS = 7.8
    }

    @{
        Id = 'PS031'
        Name = 'Suspicious File Operations'
        Severity = 'Medium'
        Category = 'FileSystem'
        Description = 'Detects file operations on suspicious locations: startup folders, system32, temp with executable extensions.'
        ASTPattern = 'CommandAst'
        CommandName = 'Copy-Item|Move-Item|New-Item'
        PathCheck = 'system32|startup|programdata.*\.exe|\.dll|\.scr'
        Remediation = 'Validate all file operations to sensitive locations. Implement file hash validation. Use digital signatures for executables.'
        CVSS = 6.2
    }

    @{
        Id = 'PS032'
        Name = 'Reflective Loading'
        Severity = 'High'
        Category = 'CodeExecution'
        Description = 'Detects reflection-based loading of assemblies or types which can bypass security controls.'
        ASTPattern = 'MemberExpression'
        MemberName = 'Load|LoadFrom|LoadFile|GetMethod|Invoke'
        ContextCheck = '\[System\.Reflection\]|\[Reflection\.Assembly\]'
        Remediation = 'Review all reflection usage. Validate assembly sources. Use strong-named assemblies. Consider if reflection is necessary.'
        CVSS = 8.3
    }

    @{
        Id = 'PS033'
        Name = 'COM Object Creation'
        Severity = 'Medium'
        Category = 'InteropSecurity'
        Description = 'Detects COM object instantiation which can be used for lateral movement or executing system commands.'
        ASTPattern = 'CommandAst'
        CommandName = 'New-Object'
        ParameterCheck = '-ComObject'
        Remediation = 'Review COM object usage. Common suspicious objects: WScript.Shell, Shell.Application, InternetExplorer.Application. Use PowerShell native cmdlets when available.'
        CVSS = 6.0
    }

    @{
        Id = 'PS034'
        Name = 'WMI Command Execution'
        Severity = 'High'
        Category = 'CommandExecution'
        Description = 'Detects WMI/CIM usage for command execution which can bypass application whitelisting.'
        ASTPattern = 'CommandAst'
        CommandName = 'Invoke-WmiMethod|Invoke-CimMethod'
        ContextCheck = 'Win32_Process|Create'
        Remediation = 'Use Start-Process or Invoke-Command for process creation. If WMI required, validate all inputs and log executions. Consider alternative approaches.'
        CVSS = 7.8
    }

    @{
        Id = 'PS035'
        Name = 'Plaintext Password or Token in Logs'
        Severity = 'Critical'
        Category = 'InformationDisclosure'
        Description = 'Detects logging of PLAINTEXT passwords, security keys, or tokens. IMPORTANT: Logging usernames, user IDs, or non-sensitive identifiers is ACCEPTABLE and essential for debugging. Only flag plaintext passwords, secret keys, API tokens, or credential object plaintext exposure (.GetNetworkCredential().Password).'
        ASTPattern = 'CommandAst'
        CommandName = 'Write-|Out-File|Add-Content|Set-Content'
        ContextCheck = 'GetNetworkCredential|\.Password\s*\)'
        Remediation = 'Never log plaintext passwords, API keys, tokens, or secrets. ACCEPTABLE: Logging usernames, user IDs, object names, configuration settings. Use structured logging with field-level control. Sanitize credential objects before logging.'
        CVSS = 8.8
        AcceptableLogging = 'Usernames, User IDs, Account names, Non-sensitive configuration values'
        CriticalOnly = 'Plaintext passwords, API keys, tokens, secrets, .GetNetworkCredential() results'
    }

)

# Export the rules
$SecurityRules
