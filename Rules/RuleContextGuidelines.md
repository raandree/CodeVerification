# PowerShell Security Rules - Context and Application Guidelines
# Version: 1.0
# Last Updated: 2025-10-17

# IMPORTANT: PowerShell-Specific Context Considerations

## Rule Application Context

### 1. Credential Handling Rules - PowerShell Context

PowerShell has established patterns for credential handling that are considered secure within the PowerShell ecosystem:

**ACCEPTABLE in PowerShell:**
- `$credential = Get-Credential` - Interactive credential prompt
- `[PSCredential]` object usage
- `ConvertTo-SecureString` with appropriate flags
- Writing usernames or user IDs to logs for debugging
- `$credential.UserName` in log files (NOT the password)

**CRITICAL - Report These:**
- Plaintext passwords: `$password = "MyPassword123"`
- Logging password properties: `Write-Host $credential.Password`
- Using `GetNetworkCredential().Password` and logging/transmitting it
- Hardcoded API keys or tokens in code
- Security keys exposed in logs or console output

**Rule Adjustment:**
```powershell
# PS201 - Hardcoded Plaintext Passwords
# ONLY trigger on actual plaintext password assignments or parameters
# DO NOT trigger on:
#   - $username = "domain\user"
#   - Write-Log "User: $($credential.UserName)"
#   - Parameter declarations: [string]$Username

# PS203 - Credential Logging  
# CRITICAL only when password/key/token is logged
# LOW severity when only username/ID is logged (common debugging need)
```

### 2. High Entropy Strings - PowerShell Context

PowerShell naturally produces high entropy strings due to:
- Verbose cmdlet names: `Get-AzureADServicePrincipal`
- .NET type references: `[System.DirectoryServices.DirectoryEntry]`
- Long parameter names: `-EnableMailboxInactivityReporting`
- GUID usage in DSC and module manifests
- COM object progIDs: `New-Object -ComObject "Excel.Application"`

**Context-Aware Detection:**

High entropy alone is NOT a security issue in PowerShell. High entropy strings should be analyzed for:

1. **Obfuscation Intent**: Is the code deliberately hard to read?
2. **Encoded Payloads**: Base64, hex, or other encoding hiding commands
3. **Random Variable Names**: `$a, $b, $c` vs. descriptive names

**Rule Adjustments:**
```powershell
# PS405 - Variable Name Obfuscation
# Severity: LOW (not Medium)
# Context: Check if short names are used with obfuscation patterns
# Many legitimate scripts use $i, $x, $y for loops

# PS401 - Base64 Encoded Commands
# Keep as HIGH severity - but distinguish between:
#   - Encoded parameters (common in remote execution)
#   - Encoded payloads (suspicious, potential malware)

# PS402 - Character Substitution
# Severity: MEDIUM - but consider context:
#   - [char]13 + [char]10 for line breaks is legitimate
#   - Excessive character substitution across entire script is suspicious
```

**Do NOT automatically report as CRITICAL:**
- Long cmdlet names or .NET types
- Module or function names with multiple words
- DSC resource names
- Well-structured parameter names

**DO report with context:**
- Strings that appear to be encoded payloads
- Deliberately obfuscated variable names throughout a script
- Character substitution used to hide command names

### 3. Sensitive Data in Logs - Context-Aware Rules

**CRITICAL Findings:**
- Logging plaintext passwords
- Logging security tokens or API keys  
- Logging private keys or certificates
- Writing sensitive credentials to files

**ACCEPTABLE/LOW Severity:**
- Logging usernames for debugging
- Logging user IDs or SIDs
- Logging computer names or domain names
- Writing configuration metadata

**Rule Application:**
```powershell
# Adjust PS203 - Credential Logging
# Pattern refinement needed:

# CRITICAL:
Write-Host $credential.GetNetworkCredential().Password
Out-File -InputObject $apiKey
Write-Log "Token: $accessToken"

# LOW or ACCEPTABLE:
Write-Host "User: $($credential.UserName)"
Write-Log "Processing for user ID: $userId"
Write-Verbose "Computer: $env:COMPUTERNAME"
```

### 4. Dynamic Code Execution - PowerShell Context

PowerShell's power comes from dynamic execution. Not all dynamic execution is malicious:

**LEGITIMATE Use Cases:**
- Module auto-loading and discovery
- DSC resource compilation
- Configuration management
- Testing frameworks (Pester)
- Template engines

**SUSPICIOUS Patterns:**
- Invoke-Expression with user input or external data
- Download-and-execute chains
- Obfuscated scriptblocks
- Dynamically building commands from strings

**Rule Application:**
```powershell
# PS001 - Invoke-Expression
# Severity: HIGH (not always Critical)
# Context matters:
#   - IEX from trusted module path = MEDIUM
#   - IEX with (Download + Execute) = CRITICAL
#   - IEX in DSC or testing contexts = LOW

# Consider the data flow:
# HIGH RISK: iex (New-Object Net.WebClient).DownloadString($url)
# MEDIUM RISK: iex Get-Content $trustedConfigFile
# LOW RISK: & $cmdlet $params (using call operator is safer)
```

### 5. Network Operations - Context

Many enterprise PowerShell scripts legitimately:
- Query APIs for configuration data
- Download modules from trusted repositories
- Report telemetry to monitoring systems
- Integrate with cloud services

**Context-Aware Assessment:**

**SUSPICIOUS:**
- Network calls to non-standard ports
- HTTP (not HTTPS) data transfers
- Downloads to unusual locations (temp, startup folders)
- Network operations combined with obfuscation
- FTP usage (rarely legitimate in modern scripts)

**LEGITIMATE (document, but lower severity):**
- HTTPS calls to known services (Microsoft, GitHub)
- Module installation from PowerShell Gallery
- Telemetry to organization's monitoring systems
- Cloud API integrations (Azure, AWS) with proper authentication

**Rule Application:**
```powershell
# PS101 - Network Data Transfer
# Severity adjustment based on context:
#   - HTTPS to *.microsoft.com, *.github.com, *.powershellgallery.com: LOW-MEDIUM
#   - HTTP downloads: HIGH
#   - Downloads followed by execute: CRITICAL
#   - FTP operations: HIGH (rarely needed)
```

## Rule Severity Matrix - PowerShell Context

| Rule ID | Default | Context-Adjusted | Notes |
|---------|---------|------------------|-------|
| PS201 | Critical | Critical only for plaintext passwords/keys | Username logging is LOW |
| PS203 | Critical | Critical for passwords, LOW for usernames | Distinguish what is logged |
| PS405 | Low | Low | High entropy variable names only suspicious with other indicators |
| PS401 | High | High | Base64 still concerning, but check context |
| PS604 | Medium | Low | Hostname checks common in enterprise scripts |
| PS001 | High | Context: HIGH to LOW | Depends on what is being invoked |
| PS101 | High | Context: HIGH to LOW | Depends on destination and protocol |

## Detection Strategy

1. **First Pass**: Apply all rules to identify potential issues
2. **Context Analysis**: For each finding, examine:
   - Surrounding code context
   - Data flow (where does data come from/go to?)
   - Module purpose (security tool vs. enterprise management)
3. **Severity Adjustment**: Adjust severity based on context
4. **False Positive Reduction**: Document why certain patterns are acceptable in PowerShell

## Special Considerations

### Nishang Module
The nishang penetration testing framework will trigger MANY rules by design:
- It contains offensive security tools
- Code execution, network operations, obfuscation are FEATURES
- Report findings as INFORMATIONAL for security tools
- Focus on whether code is documented as a security/testing tool

### DSC Modules  
DSC (Desired State Configuration) modules:
- Legitimately check system state
- May create scheduled tasks, registry entries
- Often handle credentials (in SecureString format)
- Context: Configuration management, not malware

### Assessment Approach
1. Identify the module's stated purpose
2. Check if security findings align with legitimate purpose
3. Flag only actual vulnerabilities or anti-patterns
4. Reduce false positives by understanding PowerShell norms

## Reporting Guidelines

### Executive Summary
- Separate known security tools from potential threats
- Focus risk assessment on unintentional vulnerabilities
- Provide context-aware risk ratings

### Detailed Reports
- Include context for each finding
- Explain WHY something is a concern
- Distinguish between:
  - Intentional offensive tools (document, not necessarily fix)
  - Unintentional vulnerabilities (needs remediation)
  - PowerShell idioms (acceptable patterns)

## Conclusion

Security analysis must be context-aware. PowerShell has unique characteristics that differ from other languages. Applying generic security rules without context leads to excessive false positives and obscures genuine security issues.

Focus on:
- **Actual credential exposure** (plaintext passwords, not usernames)
- **Malicious obfuscation** (hiding intent, not just long names)
- **Genuine security risks** (download-execute chains, AMSI bypass)
- **Context matters** (security tools vs. malware vs. enterprise scripts)
