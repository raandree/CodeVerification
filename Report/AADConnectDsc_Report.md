# Security Analysis Report: AADConnectDsc

**Date**: 2025-10-DD
**Module**: AADConnectDsc
**Total Findings**: 830

## Summary

- **Critical**: 4
- **High**: 2
- **Medium**: 743
- **Low**: 81

## Detailed Findings

### Category: AntiAnalysis

#### PS604 - Hostname or Domain Checks

**Severity**: Medium

**Description**: Detects environment fingerprinting which may indicate targeted attacks

**Remediation**: Document why environment detection is required

**CVSS Score**: 4

**Occurrences**: 6

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 2452
  ```powershell
  Returns the computer name cross-plattform. The variable `$env:COMPUTERNAME`
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 2475
  ```powershell
  $computerName = hostname
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 2480
  ```powershell
  We could run 'hostname' on Windows too, but $env:COMPUTERNAME
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 2480
  ```powershell
  We could run 'hostname' on Windows too, but $env:COMPUTERNAME
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 2483
  ```powershell
  $computerName = $env:COMPUTERNAME
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\AADConnectDsc.psd1`

- **Line**: 39
  ```powershell
  # PowerShellHostName = ''
  ```

---

### Category: CodeExecution

#### PS005 - Script Block Injection

**Severity**: High

**Description**: Detects creation of scriptblocks from strings which may contain malicious code

**Remediation**: Use pre-defined scriptblocks or validate input thoroughly before creating scriptblocks dynamically

**CVSS Score**: 7

**Occurrences**: 1

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 2287
  ```powershell
  Where-Object -FilterScript ([ScriptBlock]::Create($certFilterScript))
  ```

---

### Category: CredentialExposure

#### PS203 - Credential Logging

**Severity**: Critical

**Description**: Detects logging or writing of credential objects which may expose passwords

**Remediation**: Never log credentials. Sanitize log output to remove sensitive data

**CVSS Score**: 8.9

**Occurrences**: 4

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1287
  ```powershell
  Write-Verbose -Message ($script:localizedData.MatchPsCredentialUsernameMessage -f $currentValue.UserName, $desiredValue.UserName)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1292
  ```powershell
  Write-Verbose -Message ($script:localizedData.NoMatchPsCredentialUsernameMessage -f $currentValue.UserName, $desiredValue.UserName)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1299
  ```powershell
  Write-Verbose -Message ($script:localizedData.MatchPsCredentialUsernameMessage -f $currentValue, $desiredValue.UserName)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1304
  ```powershell
  Write-Verbose -Message ($script:localizedData.NoMatchPsCredentialUsernameMessage -f $currentValue, $desiredValue.UserName)
  ```

---

### Category: Cryptography

#### PS1001 - Weak Cryptography

**Severity**: Medium

**Description**: Detects usage of weak or deprecated cryptographic algorithms

**Remediation**: Use strong cryptography: AES-256, SHA-256 or higher

**CVSS Score**: 5.9

**Occurrences**: 444

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 10
  ```powershell
  InvalidDesiredValuesError = Property 'DesiredValues' in Test-DscParameterState must be either a Hashtable, CimInstance, CimInstance[], or System.Collections.Specialized.OrderedDictionary. Type detected was '{0}'. (DRC0014)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 10
  ```powershell
  InvalidDesiredValuesError = Property 'DesiredValues' in Test-DscParameterState must be either a Hashtable, CimInstance, CimInstance[], or System.Collections.Specialized.OrderedDictionary. Type detected was '{0}'. (DRC0014)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 12
  ```powershell
  InvalidPropertiesError = If 'DesiredValues' is a CimInstance then property 'Properties' must contain a value. (DRC0016)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 13
  ```powershell
  MatchPsCredentialUsernameMessage = MATCH: PSCredential username match. Current state is '{0}' and desired state is '{1}'. (DRC0017)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 14
  ```powershell
  NoMatchPsCredentialUsernameMessage = NOTMATCH: PSCredential username mismatch. Current state is '{0}' and desired state is '{1}'. (DRC0018)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 15
  ```powershell
  NoMatchTypeMismatchMessage = NOTMATCH: Type mismatch for property '{0}' Current state type is '{1}' and desired type is '{2}'. (DRC0019)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 16
  ```powershell
  MatchValueMessage = MATCH: Value (type '{0}') for property '{1}' does match. Current state is '{2}' and desired state is '{3}'. (DRC0020)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 17
  ```powershell
  NoMatchValueMessage = NOTMATCH: Value (type '{0}') for property '{1}' does not match. Current state is '{2}' and desired state is '{3}'. (DRC0021)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 18
  ```powershell
  NoMatchValueDifferentCountMessage = NOTMATCH: Value (type '{0}') for property '{1}' does have a different count. Current state count is '{2}' and desired state count is '{3}'. (DRC0022)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 19
  ```powershell
  NoMatchElementTypeMismatchMessage = NOTMATCH: Type mismatch for property '{0}' Current state type of element [{1}] is '{2}' and desired type is '{3}'. (DRC0023)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 20
  ```powershell
  NoMatchElementValueMismatchMessage = NOTMATCH: Value [{0}] (type '{1}') for property '{2}' does match. Current state is '{3}' and desired state is '{4}'. (DRC0024)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 21
  ```powershell
  MatchElementValueMessage = MATCH: Value [{0}] (type '{1}') for property '{2}' does match. Current state is '{3}' and desired state is '{4}'. (DRC0025)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 22
  ```powershell
  PropertyInDesiredStateMessage = Property '{0}' is in desired state. (DRC0026)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 22
  ```powershell
  PropertyInDesiredStateMessage = Property '{0}' is in desired state. (DRC0026)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 31
  ```powershell
  ArrayDoesNotMatch = One or more values in an array does not match the desired state. Details of the changes are below. (DRC0035)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 35
  ```powershell
  PropertyInDesiredState = The parameter '{0}' is in desired state. (DRC0039)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 35
  ```powershell
  PropertyInDesiredState = The parameter '{0}' is in desired state. (DRC0039)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 36
  ```powershell
  PropertyNotInDesiredState = The parameter '{0}' is not in desired state. (DRC0040)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 36
  ```powershell
  PropertyNotInDesiredState = The parameter '{0}' is not in desired state. (DRC0040)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\en-US\DscResource.Common.strings.psd1`

- **Line**: 37
  ```powershell
  PropertyNotInDesiredStateMessage = Property '{0}' is not in desired state. (DRC0041)
  ```

(424 more occurrences not shown)

---

### Category: Obfuscation

#### PS402 - Character Substitution Obfuscation

**Severity**: Medium

**Description**: Detects character substitution techniques used to evade detection

**Remediation**: Use clear, readable code without obfuscation

**CVSS Score**: 5.8

**Occurrences**: 291

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psd1`

- **Line**: 59
  ```powershell
  - `Format-Path`
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psd1`

- **Line**: 59
  ```powershell
  - `Format-Path`
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psd1`

- **Line**: 60
  ```powershell
  - Added parameter `ExpandEnvironmentVariable` fixes [#147](https://github.com/dsccommunity/DscResource.Common/issues/147).
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psd1`

- **Line**: 60
  ```powershell
  - Added parameter `ExpandEnvironmentVariable` fixes [#147](https://github.com/dsccommunity/DscResource.Common/issues/147).
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psd1`

- **Line**: 61
  ```powershell
  - Added support to `Compare-DscParameterState` for comparing large hashtables
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psd1`

- **Line**: 61
  ```powershell
  - Added support to `Compare-DscParameterState` for comparing large hashtables
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 116
  ```powershell
  $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSetWhenParameterExist -f ($RequiredParameter -join ''', '''), ($IfParameterPresent -join ''', ''')
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 116
  ```powershell
  $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSetWhenParameterExist -f ($RequiredParameter -join ''', '''), ($IfParameterPresent -join ''', ''')
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 116
  ```powershell
  $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSetWhenParameterExist -f ($RequiredParameter -join ''', '''), ($IfParameterPresent -join ''', ''')
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 120
  ```powershell
  $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSet -f ($RequiredParameter -join ''', ''')
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 120
  ```powershell
  $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSet -f ($RequiredParameter -join ''', ''')
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 148
  ```powershell
  $script:localizedData.RequiredCommandParameter_SpecificParametersAtLeastOneMustBeSetWhenParameterExist -f ($RequiredParameter -join ''', '''), ($IfParameterPresent -join ''', ''')
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 148
  ```powershell
  $script:localizedData.RequiredCommandParameter_SpecificParametersAtLeastOneMustBeSetWhenParameterExist -f ($RequiredParameter -join ''', '''), ($IfParameterPresent -join ''', ''')
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 148
  ```powershell
  $script:localizedData.RequiredCommandParameter_SpecificParametersAtLeastOneMustBeSetWhenParameterExist -f ($RequiredParameter -join ''', '''), ($IfParameterPresent -join ''', ''')
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 152
  ```powershell
  $script:localizedData.RequiredCommandParameter_SpecificParametersAtLeastOneMustBeSet -f ($RequiredParameter -join ''', ''')
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 152
  ```powershell
  $script:localizedData.RequiredCommandParameter_SpecificParametersAtLeastOneMustBeSet -f ($RequiredParameter -join ''', ''')
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 373
  ```powershell
  $Values.DesiredValue -is [Microsoft.Management.Infrastructure.CimInstance[]] `
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 422
  ```powershell
  $keyPropertyValues = $keyCimInstanceProperties.ForEach({'{0}="{1}"' -f $_.Name, ($_.Value -join ',')})
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 427
  ```powershell
  ($keyPropertyValues -join ';')
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 442
  ```powershell
  $keyPropertyValues = $keyCimInstanceProperties.ForEach({'{0}="{1}"' -f $_.Name, ($_.Value -join ',')})
  ```

(271 more occurrences not shown)

---

#### PS405 - Variable Name Obfuscation

**Severity**: Low

**Description**: Detects suspicious variable names that may indicate obfuscation

**Remediation**: Use descriptive variable names following naming conventions

**CVSS Score**: 3.5

**Occurrences**: 81

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 187
  ```powershell
  Clear-ZeroedEnumPropertyValue -InputObject $ht
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1388
  ```powershell
  for ($i = 0; $i -lt $desiredArrayValues.Count; $i++)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1388
  ```powershell
  for ($i = 0; $i -lt $desiredArrayValues.Count; $i++)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1388
  ```powershell
  for ($i = 0; $i -lt $desiredArrayValues.Count; $i++)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1390
  ```powershell
  if ($desiredArrayValues[$i])
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1392
  ```powershell
  $desiredType = $desiredArrayValues[$i].GetType()
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1401
  ```powershell
  if ($currentArrayValues[$i])
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1403
  ```powershell
  $currentType = $currentArrayValues[$i].GetType()
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1417
  ```powershell
  Write-Verbose -Message ($script:localizedData.NoMatchElementTypeMismatchMessage -f $key, $i, $currentType.FullName, $desiredType.FullName)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1431
  ```powershell
  if ($currentArrayValues[$i] -is [scriptblock])
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1433
  ```powershell
  $currentArrayValues[$i] = if ($desiredArrayValues[$i] -is [string])
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1433
  ```powershell
  $currentArrayValues[$i] = if ($desiredArrayValues[$i] -is [string])
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1435
  ```powershell
  $currentArrayValues[$i] = $currentArrayValues[$i].Invoke()
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1435
  ```powershell
  $currentArrayValues[$i] = $currentArrayValues[$i].Invoke()
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1439
  ```powershell
  $currentArrayValues[$i].ToString()
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1444
  ```powershell
  if ($desiredArrayValues[$i] -is [scriptblock])
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1446
  ```powershell
  $desiredArrayValues[$i] = if ($currentArrayValues[$i] -is [string] -and -not $wasCurrentArrayValuesConverted)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1446
  ```powershell
  $desiredArrayValues[$i] = if ($currentArrayValues[$i] -is [string] -and -not $wasCurrentArrayValuesConverted)
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1448
  ```powershell
  $desiredArrayValues[$i].Invoke()
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 1452
  ```powershell
  $desiredArrayValues[$i].ToString()
  ```

(61 more occurrences not shown)

---

### Category: ParseError

#### PARSE_ERROR

**Severity**: High

**Description**: File contains PowerShell syntax errors: 2 errors found

**Remediation**: Fix syntax errors before security analysis

**CVSS Score**: 0

**Occurrences**: 1

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\AADConnectDsc.psm1`

- **Line**: 0
  ```powershell
  Unable to find type [Microsoft.IdentityManagement.PowerShell.ObjectModel.ScopeCondition].
  ```

---

### Category: PrivilegeEscalation

#### PS301 - Administrator Privilege Check

**Severity**: Medium

**Description**: Detects checks for administrative privileges which may indicate privilege escalation attempts

**Remediation**: Document why administrative privileges are required, implement least privilege principle

**CVSS Score**: 5.3

**Occurrences**: 2

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 768
  ```powershell
  [Security.Principal.WindowsPrincipal] $user = [Security.Principal.WindowsIdentity]::GetCurrent()
  ```

**File**: `C:\CodeVerification\source\AADConnectDsc\0.4.1\Modules\DscResource.Common\0.24.0\DscResource.Common.psm1`

- **Line**: 770
  ```powershell
  $isElevated = $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
  ```

---


