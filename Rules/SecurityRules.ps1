# PowerShell Security Detection Rules
# Version: 1.0
# Last Updated: 2025-10-17

# This file defines security detection rules for PowerShell code analysis.
# Each rule follows the standard format with ID, Name, Severity, Category, Description, Pattern, Remediation, and CVSS score.

$SecurityRules = @(
    # ============================================================
    # CODE EXECUTION RULES
    # ============================================================
    
    @{
        Id = 'PS001'
        Name = 'Invoke-Expression Usage'
        Severity = 'High'
        Category = 'CodeExecution'
        Description = 'Detects use of Invoke-Expression which can execute arbitrary code from strings. This is a common vector for code injection attacks.'
        ASTPattern = 'CommandAst'
        CommandName = 'Invoke-Expression'
        Aliases = @('iex')
        Remediation = 'Replace Invoke-Expression with safer alternatives like & operator for known commands, dot-sourcing for scripts, or use [scriptblock]::Create() with proper validation'
        CVSS = 7.3
    }
    
    @{
        Id = 'PS002'
        Name = 'Invoke-Command with Unvalidated Input'
        Severity = 'High'
        Category = 'CodeExecution'
        Description = 'Detects Invoke-Command with -ScriptBlock parameter that may execute dynamic code'
        ASTPattern = 'CommandAst'
        CommandName = 'Invoke-Command'
        Remediation = 'Validate and sanitize all input before passing to Invoke-Command. Use parameterized scriptblocks where possible'
        CVSS = 6.8
    }
    
    @{
        Id = 'PS003'
        Name = 'Start-Process with User Input'
        Severity = 'High'
        Category = 'CodeExecution'
        Description = 'Detects Start-Process which can launch arbitrary executables, potentially leading to command injection'
        ASTPattern = 'CommandAst'
        CommandName = 'Start-Process'
        Aliases = @('start', 'saps')
        Remediation = 'Validate executable paths against allowlist, use full paths, avoid passing unvalidated arguments'
        CVSS = 7.5
    }
    
    @{
        Id = 'PS004'
        Name = 'Dynamic Code Compilation'
        Severity = 'Critical'
        Category = 'CodeExecution'
        Description = 'Detects Add-Type which can compile and execute C# or other .NET code dynamically'
        ASTPattern = 'CommandAst'
        CommandName = 'Add-Type'
        Remediation = 'Avoid dynamic compilation. If necessary, validate source code thoroughly and use Code Access Security'
        CVSS = 8.1
    }
    
    @{
        Id = 'PS005'
        Name = 'Script Block Injection'
        Severity = 'High'
        Category = 'CodeExecution'
        Description = 'Detects creation of scriptblocks from strings which may contain malicious code'
        Pattern = '\[scriptblock\]::Create|::CreateDelayedScript'
        Remediation = 'Use pre-defined scriptblocks or validate input thoroughly before creating scriptblocks dynamically'
        CVSS = 7.0
    }
    
    @{
        Id = 'PS006'
        Name = 'Dot-Sourcing with Variables'
        Severity = 'Medium'
        Category = 'CodeExecution'
        Description = 'Detects dot-sourcing (.) with variable paths which could load malicious scripts'
        Pattern = '^\s*\.\s+\$'
        Remediation = 'Use explicit paths or validate variable contents before dot-sourcing'
        CVSS = 5.9
    }
    
    # ============================================================
    # DATA EXFILTRATION RULES
    # ============================================================
    
    @{
        Id = 'PS101'
        Name = 'Network Data Transfer'
        Severity = 'High'
        Category = 'DataExfiltration'
        Description = 'Detects Invoke-WebRequest or Invoke-RestMethod which can exfiltrate data to external servers'
        ASTPattern = 'CommandAst'
        CommandName = 'Invoke-WebRequest|Invoke-RestMethod'
        Aliases = @('iwrequest', 'curl', 'wget', 'irm')
        Remediation = 'Log all network operations, validate URLs against allowlist, implement egress filtering'
        CVSS = 7.2
    }
    
    @{
        Id = 'PS102'
        Name = 'WebClient Usage'
        Severity = 'High'
        Category = 'DataExfiltration'
        Description = 'Detects System.Net.WebClient which can download or upload files from the internet'
        Pattern = 'System\.Net\.WebClient|New-Object.*WebClient'
        Remediation = 'Use modern cmdlets with logging, implement network monitoring, validate all URLs'
        CVSS = 6.9
    }
    
    @{
        Id = 'PS103'
        Name = 'DNS Query for Data Exfiltration'
        Severity = 'Medium'
        Category = 'DataExfiltration'
        Description = 'Detects DNS queries which can be used for data exfiltration via DNS tunneling'
        ASTPattern = 'CommandAst'
        CommandName = 'Resolve-DnsName'
        Pattern = 'nslookup|Resolve-DnsName'
        Remediation = 'Monitor DNS queries for suspicious patterns, implement DNS filtering'
        CVSS = 5.5
    }
    
    @{
        Id = 'PS104'
        Name = 'Email Data Transmission'
        Severity = 'High'
        Category = 'DataExfiltration'
        Description = 'Detects Send-MailMessage which can exfiltrate data via email'
        ASTPattern = 'CommandAst'
        CommandName = 'Send-MailMessage'
        Remediation = 'Monitor email operations, validate recipients, implement DLP policies'
        CVSS = 6.8
    }
    
    @{
        Id = 'PS105'
        Name = 'File Upload Operations'
        Severity = 'High'
        Category = 'DataExfiltration'
        Description = 'Detects file upload methods that could exfiltrate sensitive files'
        Pattern = 'UploadFile|UploadData|UploadString'
        Remediation = 'Monitor file upload operations, validate destinations, implement egress controls'
        CVSS = 7.0
    }
    
    @{
        Id = 'PS106'
        Name = 'FTP Operations'
        Severity = 'High'
        Category = 'DataExfiltration'
        Description = 'Detects FTP operations which can transfer files to external servers'
        Pattern = 'ftp://|System\.Net\.FtpWebRequest'
        Remediation = 'Block FTP at network level, use secure alternatives like SFTP with logging'
        CVSS = 6.7
    }
    
    # ============================================================
    # CREDENTIAL EXPOSURE RULES
    # ============================================================
    
    @{
        Id = 'PS201'
        Name = 'Hardcoded Plaintext Passwords'
        Severity = 'Critical'
        Category = 'CredentialExposure'
        Description = 'Detects plaintext passwords hardcoded in scripts'
        Pattern = '-Password\s+[''"](?![\$\*])[^''"]{8,}[''"]|password\s*=\s*[''"][^''"]{8,}[''"]'
        Remediation = 'Never store passwords in plaintext. Use SecureString, PSCredential, or secure credential storage systems'
        CVSS = 9.8
    }
    
    @{
        Id = 'PS202'
        Name = 'ConvertFrom-SecureString Without Key'
        Severity = 'High'
        Category = 'CredentialExposure'
        Description = 'Detects conversion of SecureString to plaintext without proper encryption key'
        ASTPattern = 'CommandAst'
        CommandName = 'ConvertFrom-SecureString'
        Remediation = 'Use secure key management, avoid storing or transmitting plaintext credentials'
        CVSS = 7.5
    }
    
    @{
        Id = 'PS203'
        Name = 'Credential Logging'
        Severity = 'Critical'
        Category = 'CredentialExposure'
        Description = 'Detects logging or writing of credential objects which may expose passwords'
        Pattern = 'Write-.*\$.*credential|Out-File.*password|Write-.*GetNetworkCredential'
        Remediation = 'Never log credentials. Sanitize log output to remove sensitive data'
        CVSS = 8.9
    }
    
    @{
        Id = 'PS204'
        Name = 'GetNetworkCredential Usage'
        Severity = 'High'
        Category = 'CredentialExposure'
        Description = 'Detects GetNetworkCredential() which exposes plaintext password'
        Pattern = '\.GetNetworkCredential\(\)'
        Remediation = 'Avoid converting credentials to plaintext. Use secure APIs that accept PSCredential directly'
        CVSS = 7.8
    }
    
    @{
        Id = 'PS205'
        Name = 'API Keys or Tokens in Code'
        Severity = 'Critical'
        Category = 'CredentialExposure'
        Description = 'Detects hardcoded API keys, access tokens, or similar secrets'
        Pattern = '(api[_-]?key|access[_-]?token|secret[_-]?key|auth[_-]?token)\s*=\s*[''"][a-zA-Z0-9_\-]{20,}[''"]'
        Remediation = 'Use secure secret management systems like Azure Key Vault, never hardcode secrets'
        CVSS = 9.1
    }
    
    # ============================================================
    # PRIVILEGE ESCALATION RULES
    # ============================================================
    
    @{
        Id = 'PS301'
        Name = 'Administrator Privilege Check'
        Severity = 'Medium'
        Category = 'PrivilegeEscalation'
        Description = 'Detects checks for administrative privileges which may indicate privilege escalation attempts'
        Pattern = 'IsInRole.*Administrator|Principal.*WindowsIdentity'
        Remediation = 'Document why administrative privileges are required, implement least privilege principle'
        CVSS = 5.3
    }
    
    @{
        Id = 'PS302'
        Name = 'UAC Bypass Attempts'
        Severity = 'Critical'
        Category = 'PrivilegeEscalation'
        Description = 'Detects common UAC bypass techniques'
        Pattern = 'eventvwr\.exe|fodhelper\.exe|sdclt\.exe|computerdefaults\.exe|\\mscfile\\shell\\open\\command'
        Remediation = 'Remove UAC bypass code, use proper elevation requests'
        CVSS = 8.8
    }
    
    @{
        Id = 'PS303'
        Name = 'Token Manipulation'
        Severity = 'Critical'
        Category = 'PrivilegeEscalation'
        Description = 'Detects attempts to manipulate access tokens for privilege escalation'
        Pattern = 'AdjustTokenPrivileges|DuplicateToken|SetThreadToken'
        Remediation = 'Remove token manipulation code, use standard Windows security APIs'
        CVSS = 9.0
    }
    
    @{
        Id = 'PS304'
        Name = 'Service Manipulation'
        Severity = 'High'
        Category = 'PrivilegeEscalation'
        Description = 'Detects service creation or modification which can be used for privilege escalation'
        ASTPattern = 'CommandAst'
        CommandName = 'New-Service|Set-Service'
        Pattern = 'sc\.exe\s+create|sc\.exe\s+config'
        Remediation = 'Validate service operations, implement proper access controls'
        CVSS = 7.8
    }
    
    # ============================================================
    # OBFUSCATION RULES
    # ============================================================
    
    @{
        Id = 'PS401'
        Name = 'Base64 Encoded Commands'
        Severity = 'High'
        Category = 'Obfuscation'
        Description = 'Detects Base64 encoded PowerShell commands which may hide malicious intent'
        Pattern = '-enc(odedcommand)?\s+[A-Za-z0-9+/=]{50,}|FromBase64String'
        Remediation = 'Decode and review encoded content, avoid obfuscation unless necessary for compatibility'
        CVSS = 6.5
    }
    
    @{
        Id = 'PS402'
        Name = 'Character Substitution Obfuscation'
        Severity = 'Medium'
        Category = 'Obfuscation'
        Description = 'Detects character substitution techniques used to evade detection'
        Pattern = '\[char\]\d+|`|-join|-replace|-f\s+\('
        Remediation = 'Use clear, readable code without obfuscation'
        CVSS = 5.8
    }
    
    @{
        Id = 'PS403'
        Name = 'String Concatenation Obfuscation'
        Severity = 'Medium'
        Category = 'Obfuscation'
        Description = 'Detects excessive string concatenation which may hide malicious strings'
        Pattern = '(\+\s*[''"][^''"]*[''"]){5,}'
        Remediation = 'Use clear string literals, avoid unnecessary concatenation'
        CVSS = 5.5
    }
    
    @{
        Id = 'PS404'
        Name = 'Compression and Decompression'
        Severity = 'Medium'
        Category = 'Obfuscation'
        Description = 'Detects compression/decompression which can hide malicious payloads'
        Pattern = 'IO\.Compression|GZipStream|DeflateStream'
        Remediation = 'Document why compression is used, validate decompressed content'
        CVSS = 5.7
    }
    
    @{
        Id = 'PS405'
        Name = 'Variable Name Obfuscation'
        Severity = 'Low'
        Category = 'Obfuscation'
        Description = 'Detects suspicious variable names that may indicate obfuscation'
        Pattern = '\$[a-z]{1,2}\b|\$_\d+|\$[IO]{2,}'
        Remediation = 'Use descriptive variable names following naming conventions'
        CVSS = 3.5
    }
    
    # ============================================================
    # PERSISTENCE RULES
    # ============================================================
    
    @{
        Id = 'PS501'
        Name = 'Registry Persistence'
        Severity = 'High'
        Category = 'Persistence'
        Description = 'Detects registry modifications for persistence mechanisms'
        Pattern = 'HKCU.*\\Run|HKLM.*\\Run|CurrentVersion\\Run|New-ItemProperty.*Run'
        Remediation = 'Document legitimate startup requirements, avoid unauthorized persistence'
        CVSS = 7.3
    }
    
    @{
        Id = 'PS502'
        Name = 'Scheduled Task Creation'
        Severity = 'High'
        Category = 'Persistence'
        Description = 'Detects creation of scheduled tasks which can provide persistence'
        ASTPattern = 'CommandAst'
        CommandName = 'New-ScheduledTask|Register-ScheduledTask'
        Pattern = 'schtasks\.exe.*\/create'
        Remediation = 'Document task purpose, implement task monitoring, use proper access controls'
        CVSS = 7.0
    }
    
    @{
        Id = 'PS503'
        Name = 'WMI Event Subscription'
        Severity = 'High'
        Category = 'Persistence'
        Description = 'Detects WMI event subscriptions which can provide fileless persistence'
        Pattern = 'Register-WmiEvent|__EventFilter|__EventConsumer|__FilterToConsumerBinding'
        Remediation = 'Remove unauthorized WMI subscriptions, monitor WMI events'
        CVSS = 7.5
    }
    
    @{
        Id = 'PS504'
        Name = 'Startup Folder Modification'
        Severity = 'Medium'
        Category = 'Persistence'
        Description = 'Detects file operations in startup folders'
        Pattern = 'StartUp|Start Menu\\Programs\\Startup'
        Remediation = 'Validate startup programs, implement application control'
        CVSS = 6.2
    }
    
    # ============================================================
    # ANTI-ANALYSIS RULES
    # ============================================================
    
    @{
        Id = 'PS601'
        Name = 'Virtual Machine Detection'
        Severity = 'Medium'
        Category = 'AntiAnalysis'
        Description = 'Detects checks for virtual machines which may indicate evasion techniques'
        Pattern = 'VMware|VirtualBox|Win32_ComputerSystem|Get-WmiObject.*Manufacturer'
        Remediation = 'Remove VM detection logic unless required for legitimate licensing'
        CVSS = 4.3
    }
    
    @{
        Id = 'PS602'
        Name = 'Debugger Detection'
        Severity = 'Medium'
        Category = 'AntiAnalysis'
        Description = 'Detects checks for debuggers which may indicate anti-analysis techniques'
        Pattern = 'CheckRemoteDebuggerPresent|IsDebuggerPresent'
        Remediation = 'Remove debugger detection code'
        CVSS = 4.5
    }
    
    @{
        Id = 'PS603'
        Name = 'Sleep or Delay for Evasion'
        Severity = 'Low'
        Category = 'AntiAnalysis'
        Description = 'Detects long sleep periods which may evade sandbox analysis'
        ASTPattern = 'CommandAst'
        CommandName = 'Start-Sleep'
        Pattern = 'Start-Sleep.*-Seconds\s+[3-9]\d{2,}|timeout\s+/t\s+[3-9]\d{2,}'
        Remediation = 'Remove unnecessary delays, use appropriate timeout values'
        CVSS = 3.1
    }
    
    @{
        Id = 'PS604'
        Name = 'Hostname or Domain Checks'
        Severity = 'Medium'
        Category = 'AntiAnalysis'
        Description = 'Detects environment fingerprinting which may indicate targeted attacks'
        Pattern = '\$env:COMPUTERNAME|\$env:USERDNSDOMAIN|hostname'
        Remediation = 'Document why environment detection is required'
        CVSS = 4.0
    }
    
    # ============================================================
    # LATERAL MOVEMENT RULES
    # ============================================================
    
    @{
        Id = 'PS701'
        Name = 'Remote PowerShell Execution'
        Severity = 'High'
        Category = 'LateralMovement'
        Description = 'Detects remote command execution capabilities'
        ASTPattern = 'CommandAst'
        CommandName = 'Enter-PSSession|New-PSSession'
        Remediation = 'Document remote access requirements, implement proper authentication and logging'
        CVSS = 6.8
    }
    
    @{
        Id = 'PS702'
        Name = 'PSExec or Remote Execution Tools'
        Severity = 'High'
        Category = 'LateralMovement'
        Description = 'Detects usage of remote execution tools'
        Pattern = 'psexec|paexec|wmic.*process\s+call\s+create'
        Remediation = 'Use native PowerShell remoting with proper security, avoid third-party tools'
        CVSS = 7.2
    }
    
    @{
        Id = 'PS703'
        Name = 'SMB or Network Share Access'
        Severity = 'Medium'
        Category = 'LateralMovement'
        Description = 'Detects access to network shares which can facilitate lateral movement'
        Pattern = '\\\\.*\\[A-Za-z]\$|New-PSDrive.*FileSystem'
        Remediation = 'Document network access requirements, implement network segmentation'
        CVSS = 5.5
    }
    
    # ============================================================
    # DEFENSE EVASION RULES
    # ============================================================
    
    @{
        Id = 'PS801'
        Name = 'AMSI Bypass Attempts'
        Severity = 'Critical'
        Category = 'DefenseEvasion'
        Description = 'Detects attempts to bypass Anti-Malware Scan Interface (AMSI)'
        Pattern = 'AmsiUtils|amsiInitFailed|AmsiScanBuffer|[Ref].Assembly.GetType.*Amsi'
        Remediation = 'Remove AMSI bypass code, this is a clear indicator of malicious intent'
        CVSS = 9.5
    }
    
    @{
        Id = 'PS802'
        Name = 'Execution Policy Bypass'
        Severity = 'High'
        Category = 'DefenseEvasion'
        Description = 'Detects attempts to bypass PowerShell execution policy'
        Pattern = '-ExecutionPolicy\s+Bypass|-ep\s+bypass|Set-ExecutionPolicy.*Unrestricted'
        Remediation = 'Use proper code signing and execution policies, avoid bypassing security controls'
        CVSS = 7.0
    }
    
    @{
        Id = 'PS803'
        Name = 'Script Block Logging Evasion'
        Severity = 'Critical'
        Category = 'DefenseEvasion'
        Description = 'Detects attempts to disable PowerShell logging'
        Pattern = 'ScriptBlockLogging|EnableScriptBlockLogging.*0|GroupPolicy.*PowerShell'
        Remediation = 'Remove logging evasion code, this indicates malicious intent'
        CVSS = 8.7
    }
    
    @{
        Id = 'PS804'
        Name = 'Windows Defender Manipulation'
        Severity = 'Critical'
        Category = 'DefenseEvasion'
        Description = 'Detects attempts to disable or modify Windows Defender'
        Pattern = 'Set-MpPreference.*DisableRealtimeMonitoring|Add-MpPreference.*ExclusionPath'
        Remediation = 'Remove anti-virus manipulation code, this is malicious behavior'
        CVSS = 9.0
    }
    
    @{
        Id = 'PS805'
        Name = 'Event Log Clearing'
        Severity = 'High'
        Category = 'DefenseEvasion'
        Description = 'Detects clearing of event logs to hide malicious activity'
        ASTPattern = 'CommandAst'
        CommandName = 'Clear-EventLog'
        Pattern = 'wevtutil.*cl|Clear-EventLog'
        Remediation = 'Remove log clearing code, implement proper log retention policies'
        CVSS = 7.8
    }
    
    # ============================================================
    # FILE AND REGISTRY OPERATIONS
    # ============================================================
    
    @{
        Id = 'PS901'
        Name = 'Suspicious File Operations'
        Severity = 'Medium'
        Category = 'FileOperation'
        Description = 'Detects file operations in sensitive system directories'
        Pattern = 'System32|SysWOW64|Windows\\Temp|ProgramData'
        Remediation = 'Validate file operations in system directories, implement proper access controls'
        CVSS = 5.5
    }
    
    @{
        Id = 'PS902'
        Name = 'Alternate Data Streams'
        Severity = 'High'
        Category = 'FileOperation'
        Description = 'Detects usage of NTFS Alternate Data Streams which can hide data'
        Pattern = 'Set-Content.*-Stream|Get-Item.*-Stream|::\$DATA'
        Remediation = 'Document ADS usage, monitor for unauthorized streams'
        CVSS = 6.5
    }
    
    @{
        Id = 'PS903'
        Name = 'File Deletion or Wiping'
        Severity = 'Medium'
        Category = 'FileOperation'
        Description = 'Detects file deletion operations which may destroy evidence'
        ASTPattern = 'CommandAst'
        CommandName = 'Remove-Item'
        Pattern = 'Remove-Item.*-Force|del.*\/f|rm.*-rf'
        Remediation = 'Implement file retention policies, log deletion operations'
        CVSS = 5.3
    }
    
    # ============================================================
    # CRYPTOGRAPHY AND ENCRYPTION
    # ============================================================
    
    @{
        Id = 'PS1001'
        Name = 'Weak Cryptography'
        Severity = 'Medium'
        Category = 'Cryptography'
        Description = 'Detects usage of weak or deprecated cryptographic algorithms'
        Pattern = 'DES|RC2|MD5|SHA1(?!Managed)'
        Remediation = 'Use strong cryptography: AES-256, SHA-256 or higher'
        CVSS = 5.9
    }
    
    @{
        Id = 'PS1002'
        Name = 'Ransomware Indicators'
        Severity = 'Critical'
        Category = 'Cryptography'
        Description = 'Detects encryption patterns consistent with ransomware'
        Pattern = 'RijndaelManaged|CryptoStream.*Encrypt|Get-ChildItem.*-Recurse.*\|.*Encrypt'
        Remediation = 'Review encryption usage, implement anti-ransomware controls'
        CVSS = 9.2
    }
    
    # ============================================================
    # PROCESS MANIPULATION
    # ============================================================
    
    @{
        Id = 'PS1101'
        Name = 'Process Injection'
        Severity = 'Critical'
        Category = 'ProcessManipulation'
        Description = 'Detects process injection techniques'
        Pattern = 'VirtualAllocEx|WriteProcessMemory|CreateRemoteThread|QueueUserAPC'
        Remediation = 'Remove process injection code, this is a malware technique'
        CVSS = 9.3
    }
    
    @{
        Id = 'PS1102'
        Name = 'Process Hollowing'
        Severity = 'Critical'
        Category = 'ProcessManipulation'
        Description = 'Detects process hollowing techniques'
        Pattern = 'NtUnmapViewOfSection|ZwUnmapViewOfSection|CreateProcess.*Suspended'
        Remediation = 'Remove process hollowing code, this is advanced malware technique'
        CVSS = 9.4
    }
    
    @{
        Id = 'PS1103'
        Name = 'Reflective Loading'
        Severity = 'Critical'
        Category = 'ProcessManipulation'
        Description = 'Detects reflective DLL loading techniques'
        Pattern = 'Assembly.*Load\s*\(.*\[byte|Reflection\.Assembly::Load'
        Remediation = 'Use standard module loading, avoid reflective techniques'
        CVSS = 8.5
    }
    
    # ============================================================
    # DOWNLOAD AND EXECUTION
    # ============================================================
    
    @{
        Id = 'PS1201'
        Name = 'Download and Execute Pattern'
        Severity = 'Critical'
        Category = 'DownloadExecute'
        Description = 'Detects download-and-execute pattern common in malware'
        Pattern = '(DownloadFile|DownloadString).*\|.*iex|WebClient.*\)\..*\|.*Invoke'
        Remediation = 'Remove download-execute chains, validate and scan downloaded content'
        CVSS = 9.1
    }
    
    @{
        Id = 'PS1202'
        Name = 'PowerShell Download Cradle'
        Severity = 'Critical'
        Category = 'DownloadExecute'
        Description = 'Detects PowerShell download cradles that fetch and execute remote code'
        Pattern = 'IEX.*New-Object.*DownloadString|IEX.*\(.*WebClient|iex.*iwr'
        Remediation = 'Remove download cradles, use package managers with signature verification'
        CVSS = 9.0
    }
    
    # ============================================================
    # BEST PRACTICE VIOLATIONS
    # ============================================================
    
    @{
        Id = 'PS1301'
        Name = 'Using Write-Host'
        Severity = 'Low'
        Category = 'BestPractice'
        Description = 'Write-Host is not recommended, use Write-Output or Write-Information instead'
        ASTPattern = 'CommandAst'
        CommandName = 'Write-Host'
        Remediation = 'Use Write-Output for pipeline output or Write-Information for informational messages'
        CVSS = 2.0
    }
    
    @{
        Id = 'PS1302'
        Name = 'Missing Error Handling'
        Severity = 'Low'
        Category = 'BestPractice'
        Description = 'Functions without try-catch blocks may not handle errors properly'
        Pattern = 'function\s+\w+.*\{(?!.*try).*\}'
        Remediation = 'Implement try-catch-finally blocks for robust error handling'
        CVSS = 2.5
    }
    
    @{
        Id = 'PS1303'
        Name = 'Positional Parameters'
        Severity = 'Low'
        Category = 'BestPractice'
        Description = 'Using positional parameters reduces code readability'
        Remediation = 'Use named parameters for better code clarity'
        CVSS = 1.5
    }
)

# Export rules
$SecurityRules | Export-Clixml -Path "$PSScriptRoot\SecurityRules.xml"
$SecurityRules
