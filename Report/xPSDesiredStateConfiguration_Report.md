# Security Analysis Report: xPSDesiredStateConfiguration

**Date**: 2025-10-DD
**Module**: xPSDesiredStateConfiguration
**Total Findings**: 2566

## Summary

- **Critical**: 38
- **High**: 50
- **Medium**: 2392
- **Low**: 86

## Detailed Findings

### Category: AntiAnalysis

#### PS601 - Virtual Machine Detection

**Severity**: Medium

**Description**: Detects checks for virtual machines which may indicate evasion techniques

**Remediation**: Remove VM detection logic unless required for legitimate licensing

**CVSS Score**: 4.3

**Occurrences**: 1

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\xPSDesiredStateConfiguration.PSWSIIS\xPSDesiredStateConfiguration.PSWSIIS.psm1`

- **Line**: 782
  ```powershell
  $cimInstance = Get-CimInstance -ClassName Win32_ComputerSystem -Verbose:$false
  ```

---

#### PS603 - Sleep or Delay for Evasion

**Severity**: Low

**Description**: Detects long sleep periods which may evade sandbox analysis

**Remediation**: Remove unnecessary delays, use appropriate timeout values

**CVSS Score**: 3.1

**Occurrences**: 3

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xRemoteFile\DSC_xRemoteFile.psm1`

- **Line**: 329
  ```powershell
  Start-Sleep -Seconds 5
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xServiceResource\DSC_xServiceResource.psm1`

- **Line**: 1749
  ```powershell
  Start-Sleep -Seconds 1
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\xPSDesiredStateConfiguration.PSWSIIS\xPSDesiredStateConfiguration.PSWSIIS.psm1`

- **Line**: 282
  ```powershell
  Start-Sleep -Milliseconds 1000
  ```

---

#### PS604 - Hostname or Domain Checks

**Severity**: Medium

**Description**: Detects environment fingerprinting which may indicate targeted attacks

**Remediation**: Document why environment detection is required

**CVSS Score**: 4

**Occurrences**: 23

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 167
  ```powershell
  $fqdn = '{0}.{1}' -f $ipProperties.HostName, $ipProperties.DomainName
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 171
  ```powershell
  $fqdn = $ipProperties.HostName
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xGroupResource\DSC_xGroupResource.psm1`

- **Line**: 377
  ```powershell
  -Scope $env:COMPUTERNAME
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xGroupResource\DSC_xGroupResource.psm1`

- **Line**: 566
  ```powershell
  -Scope $env:computerName
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xGroupResource\DSC_xGroupResource.psm1`

- **Line**: 592
  ```powershell
  -Disposables $disposables -Scope $env:COMPUTERNAME
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xGroupResource\DSC_xGroupResource.psm1`

- **Line**: 1162
  ```powershell
  -Scope $env:computerName
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xGroupResource\DSC_xGroupResource.psm1`

- **Line**: 2134
  ```powershell
  if ($PrincipalContextCache.ContainsKey($env:computerName))
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xGroupResource\DSC_xGroupResource.psm1`

- **Line**: 2136
  ```powershell
  $principalContext = $PrincipalContextCache[$env:computerName]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xGroupResource\DSC_xGroupResource.psm1`

- **Line**: 2145
  ```powershell
  $null = $PrincipalContextCache.Add($env:computerName, $principalContext)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xGroupResource\DSC_xGroupResource.psm1`

- **Line**: 2208
  ```powershell
  $localMachineScopes = @( '.', $env:computerName, 'localhost', '127.0.0.1', 'NT Authority', 'NT Service', 'BuiltIn', 'IIS APPPOOL', 'NT Virtual Machine' )
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xGroupResource\DSC_xGroupResource.psm1`

- **Line**: 2356
  ```powershell
  $scope = $env:computerName
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xGroupResource\DSC_xGroupResource.psm1`

- **Line**: 2495
  ```powershell
  -Scope $env:COMPUTERNAME
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xServiceResource\DSC_xServiceResource.psm1`

- **Line**: 802
  ```powershell
  elseif ($Username.StartsWith("$env:computerName\"))
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xServiceResource\DSC_xServiceResource.psm1`

- **Line**: 804
  ```powershell
  $startName = $Username.Replace($env:computerName, '.')
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1`

- **Line**: 730
  ```powershell
  return ($env:computerName + '\' + $owner.User)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1`

- **Line**: 1092
  ```powershell
  $domain = $env:computerName
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscPullServerSetup\DscPullServerSetupTest\DscPullServerSetupTest.ps1`

- **Line**: 23
  ```powershell
  $DscHostFQDN = [System.Net.Dns]::GetHostEntry([System.String] $env:computername).HostName
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscPullServerSetup\DscPullServerSetupTest\DscPullServerSetupTest.ps1`

- **Line**: 23
  ```powershell
  $DscHostFQDN = [System.Net.Dns]::GetHostEntry([System.String] $env:computername).HostName
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscResource.Common\0.19.0\DscResource.Common.psm1`

- **Line**: 2144
  ```powershell
  Returns the computer name cross-plattform. The variable `$env:COMPUTERNAME`
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscResource.Common\0.19.0\DscResource.Common.psm1`

- **Line**: 2167
  ```powershell
  $computerName = hostname
  ```

(3 more occurrences not shown)

---

### Category: CodeExecution

#### PS002 - Invoke-Command with Unvalidated Input

**Severity**: High

**Description**: Detects Invoke-Command with -ScriptBlock parameter that may execute dynamic code

**Remediation**: Validate and sanitize all input before passing to Invoke-Command. Use parameterized scriptblocks where possible

**CVSS Score**: 6.8

**Occurrences**: 28

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xScriptResource\DSC_xScriptResource.psm1`

- **Line**: 291
  ```powershell
  Invoke-Command -ScriptBlock $ScriptBlock -Credential $Credential -ComputerName .
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsFeature\DSC_xWindowsFeature.psm1`

- **Line**: 61
  ```powershell
  Invoke-Command -ScriptBlock { Get-WindowsFeature -Name $Name } `
                                  -ComputerName . `
                                  -Credential $Credential
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsFeature\DSC_xWindowsFeature.psm1`

- **Line**: 98
  ```powershell
  Invoke-Command -ScriptBlock { Get-WindowsFeature -Name $currentSubFeatureName } `
                                             -ComputerName . `
                                             -Credential $Credential
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsFeature\DSC_xWindowsFeature.psm1`

- **Line**: 220
  ```powershell
  Invoke-Command -ScriptBlock { Add-WindowsFeature @addWindowsFeatureParameters } `
                                      -ComputerName . `
                                      -Credential $Credential
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsFeature\DSC_xWindowsFeature.psm1`

- **Line**: 271
  ```powershell
  Invoke-Command -ScriptBlock { Remove-WindowsFeature @removeWindowsFeatureParameters } `
                                      -ComputerName . `
                                      -Credential $Credential
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsFeature\DSC_xWindowsFeature.psm1`

- **Line**: 388
  ```powershell
  Invoke-Command -ScriptBlock { Get-WindowsFeature -Name $Name } `
                                  -ComputerName . `
                                  -Credential $Credential
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsFeature\DSC_xWindowsFeature.psm1`

- **Line**: 419
  ```powershell
  Invoke-Command -ScriptBlock { Get-WindowsFeature -Name $currentSubFeatureName } `
                                                 -ComputerName . `
                                                 -Credential $Credential
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 77
  ```powershell
  Invoke-Command `
            -ScriptBlock $getEncryptedPassword `
            -ArgumentList $Credential, $CertificateThumbprint
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 99
  ```powershell
  Invoke-Command `
                        -ScriptBlock $using:throwTerminatingError `
                        -ArgumentList 'CertificateThumbprintIsRequired', $errorMessage, 'InvalidData'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 107
  ```powershell
  Invoke-Command `
                    -ScriptBlock $using:getDecryptedPassword `
                    -ArgumentList $using:password, $using:CertificateThumbprint
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 122
  ```powershell
  Invoke-Command `
                    -ScriptBlock $using:throwTerminatingError `
                    -ArgumentList 'DestinationPathIsNotUNCFailure', $errorMessage, 'InvalidData'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 131
  ```powershell
  Invoke-Command `
                    -ScriptBlock $using:throwTerminatingError `
                    -ArgumentList 'SourcePathIsNotLocalFailure', $errorMessage, 'InvalidData'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 142
  ```powershell
  Invoke-Command `
                    -ScriptBlock $using:throwTerminatingError `
                    -ArgumentList 'SourcePathDoesNotExistFailure', $errorMessage, 'InvalidData'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 193
  ```powershell
  Invoke-Command `
                            -ScriptBlock $using:throwTerminatingError `
                            -ArgumentList 'DestinationPathNotAccessibleFailure', $errorMessage, 'InvalidData'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 221
  ```powershell
  Invoke-Command `
                                -ScriptBlock $using:throwTerminatingError `
                                -ArgumentList 'DestinationPathCannotBeFileFailure', $errorMessage, 'InvalidData'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 246
  ```powershell
  Invoke-Command `
                        -ScriptBlock $using:throwTerminatingError `
                        -ArgumentList 'CopyDirectoryOverFileFailure', $errorMessage, 'InvalidData'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 255
  ```powershell
  Invoke-Command `
                        -ScriptBlock $using:throwTerminatingError `
                        -ArgumentList 'DestinationPathNotCreatedFailure', $errorMessage, 'InvalidData'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 302
  ```powershell
  Invoke-Command `
                        -ScriptBlock $using:throwTerminatingError `
                        -ArgumentList 'CertificateThumbprintIsRequired', $errorMessage, 'InvalidData'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 310
  ```powershell
  Invoke-Command `
                    -ScriptBlock $using:getDecryptedPassword `
                    -ArgumentList $using:password, $using:CertificateThumbprint
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 329
  ```powershell
  Invoke-Command `
                    -ScriptBlock $using:throwTerminatingError `
                    -ArgumentList 'DestinationPathIsNotUNCFailure', $errorMessage, 'InvalidData'
  ```

(8 more occurrences not shown)

---

#### PS003 - Start-Process with User Input

**Severity**: High

**Description**: Detects Start-Process which can launch arbitrary executables, potentially leading to command injection

**Remediation**: Validate executable paths against allowlist, use full paths, avoid passing unvalidated arguments

**CVSS Score**: 7.5

**Occurrences**: 1

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1`

- **Line**: 372
  ```powershell
  Start-Process @startProcessArguments
  ```

---

#### PS004 - Dynamic Code Compilation

**Severity**: Critical

**Description**: Detects Add-Type which can compile and execute C# or other .NET code dynamically

**Remediation**: Avoid dynamic compilation. If necessary, validate source code thoroughly and use Code Access Security

**CVSS Score**: 8.1

**Occurrences**: 11

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 16
  ```powershell
  Add-Type -AssemblyName 'System.IO.Compression'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 21
  ```powershell
  Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xGroupResource\DSC_xGroupResource.psm1`

- **Line**: 80
  ```powershell
  Add-Type -AssemblyName 'System.DirectoryServices.AccountManagement'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1388
  ```powershell
  Add-Type `
            -Namespace 'Microsoft.Windows.DesiredStateConfiguration.xPackageResource' `
            -Name 'MsiTools' `
            -Using 'System.Text' `
            -MemberDefinition $msiToolsCodeDefinition `
            -PassThru
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1695
  ```powershell
  Add-Type -TypeDefinition $programSource -ReferencedAssemblies 'System.ServiceProcess'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 1713
  ```powershell
  Add-Type `
            -Namespace 'Microsoft.Windows.DesiredStateConfiguration.xPackageResource' `
            -Name 'MsiTools' `
            -Using 'System.Text' `
            -MemberDefinition $msiToolsCodeDefinition `
            -PassThru
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 2224
  ```powershell
  Add-Type -TypeDefinition $programSource -ReferencedAssemblies 'System.ServiceProcess'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xServiceResource\DSC_xServiceResource.psm1`

- **Line**: 1333
  ```powershell
  Add-Type $logOnAsServiceText -PassThru
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xUserResource\DSC_xUserResource.psm1`

- **Line**: 23
  ```powershell
  Add-Type -AssemblyName 'System.DirectoryServices.AccountManagement'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xUserResource\DSC_xUserResource.psm1`

- **Line**: 1399
  ```powershell
  Add-Type -PassThru -Namespace Microsoft.Windows.DesiredStateConfiguration.NanoServer.UserResource `
        -Name CredentialsValidationTool -MemberDefinition $source -Using System.Security -ReferencedAssemblies System.Security.SecureString.dll
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1`

- **Line**: 1528
  ```powershell
  Add-Type -TypeDefinition $dscNativeMethodsSource -ReferencedAssemblies 'System.ServiceProcess'
  ```

---

#### PS005 - Script Block Injection

**Severity**: High

**Description**: Detects creation of scriptblocks from strings which may contain malicious code

**Remediation**: Use pre-defined scriptblocks or validate input thoroughly before creating scriptblocks dynamically

**CVSS Score**: 7

**Occurrences**: 1

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscResource.Common\0.19.0\DscResource.Common.psm1`

- **Line**: 2126
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

**Occurrences**: 9

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 560
  ```powershell
  Write-Verbose -Message ($script:localizedData.CreatingPSDrive -f $pathToPSDriveRoot, $Credential.UserName)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 811
  ```powershell
  Write-Verbose -Message ($script:localizedData.SettingDefaultCredential)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 500
  ```powershell
  Write-Verbose -Message ($script:localizedData.SettingDefaultCredential)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xServiceResource\DSC_xServiceResource.psm1`

- **Line**: 605
  ```powershell
  Write-Verbose -Message ($script:localizedData.GroupManagedServiceCredentialDoesNotMatch -f $Name, $GroupManagedServiceAccount, $serviceResource.BuiltInAccount)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xServiceResource\DSC_xServiceResource.psm1`

- **Line**: 615
  ```powershell
  Write-Verbose -Message ($script:localizedData.ServiceCredentialDoesNotMatch -f $Name, $Credential.UserName, $serviceResource.BuiltInAccount)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscResource.Common\0.19.0\DscResource.Common.psm1`

- **Line**: 1126
  ```powershell
  Write-Verbose -Message ($script:localizedData.MatchPsCredentialUsernameMessage -f $currentValue.UserName, $desiredValue.UserName)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscResource.Common\0.19.0\DscResource.Common.psm1`

- **Line**: 1131
  ```powershell
  Write-Verbose -Message ($script:localizedData.NoMatchPsCredentialUsernameMessage -f $currentValue.UserName, $desiredValue.UserName)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscResource.Common\0.19.0\DscResource.Common.psm1`

- **Line**: 1138
  ```powershell
  Write-Verbose -Message ($script:localizedData.MatchPsCredentialUsernameMessage -f $currentValue, $desiredValue.UserName)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscResource.Common\0.19.0\DscResource.Common.psm1`

- **Line**: 1143
  ```powershell
  Write-Verbose -Message ($script:localizedData.NoMatchPsCredentialUsernameMessage -f $currentValue, $desiredValue.UserName)
  ```

---

#### PS204 - GetNetworkCredential Usage

**Severity**: High

**Description**: Detects GetNetworkCredential() which exposes plaintext password

**Remediation**: Avoid converting credentials to plaintext. Use secure APIs that accept PSCredential directly

**CVSS Score**: 7.8

**Occurrences**: 13

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xGroupResource\DSC_xGroupResource.psm1`

- **Line**: 2156
  ```powershell
  $credentialDomain = $Credential.GetNetworkCredential().Domain
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xGroupResource\DSC_xGroupResource.psm1`

- **Line**: 2157
  ```powershell
  $credentialUserName = $Credential.GetNetworkCredential().UserName
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xGroupResource\DSC_xGroupResource.psm1`

- **Line**: 2169
  ```powershell
  $principalContextName, $Credential.GetNetworkCredential().Password )
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1266
  ```powershell
  $RunAsCredential.GetNetworkCredential().Domain, `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1267
  ```powershell
  $RunAsCredential.GetNetworkCredential().UserName, `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1268
  ```powershell
  $RunAsCredential.GetNetworkCredential().Password, `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 1754
  ```powershell
  $Credential.GetNetworkCredential().Domain, `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 1755
  ```powershell
  $Credential.GetNetworkCredential().UserName, `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 1756
  ```powershell
  $Credential.GetNetworkCredential().Password, `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xServiceResource\DSC_xServiceResource.psm1`

- **Line**: 1445
  ```powershell
  $changeServiceArguments['StartPassword'] = $Credential.GetNetworkCredential().Password
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xUserResource\DSC_xUserResource.psm1`

- **Line**: 485
  ```powershell
  $user.SetPassword($Password.GetNetworkCredential().Password)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xUserResource\DSC_xUserResource.psm1`

- **Line**: 710
  ```powershell
  if (-not $principalContext.ValidateCredentials($UserName, $Password.GetNetworkCredential().Password))
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 517
  ```powershell
  $value = $Credential.GetNetworkCredential().Password
  ```

---

### Category: Cryptography

#### PS1001 - Weak Cryptography

**Severity**: Medium

**Description**: Detects usage of weak or deprecated cryptographic algorithms

**Remediation**: Use strong cryptography: AES-256, SHA-256 or higher

**CVSS Score**: 5.9

**Occurrences**: 1471

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 4
  ```powershell
  RetrievingArchiveState = Retrieving the state of the archive with path "{0}" and destination "{1}"...
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 5
  ```powershell
  SettingArchiveState = Setting the state of the archive with path "{0}" and destination "{1}"...
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 6
  ```powershell
  ArchiveStateSet = The state of the archive with path "{0}" and destination "{1}" has been set.
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 7
  ```powershell
  TestingArchiveState = Testing whether or not the state of the archive with path "{0}" and destination "{1}" matches the desired state...
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 7
  ```powershell
  TestingArchiveState = Testing whether or not the state of the archive with path "{0}" and destination "{1}" matches the desired state...
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 13
  ```powershell
  DestinationExists = A directory already exists at the destination path "{0}".
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 13
  ```powershell
  DestinationExists = A directory already exists at the destination path "{0}".
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 14
  ```powershell
  DestinationDoesNotExist = A directory does not exist at the destination path "{0}".
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 14
  ```powershell
  DestinationDoesNotExist = A directory does not exist at the destination path "{0}".
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 15
  ```powershell
  CreatingDirectoryAtDestination = Creating the root directory at the destination path "{0}"...
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 15
  ```powershell
  CreatingDirectoryAtDestination = Creating the root directory at the destination path "{0}"...
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 17
  ```powershell
  TestingIfArchiveExistsAtDestination = Testing if the archive at the destination path "{0}" exists...
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 17
  ```powershell
  TestingIfArchiveExistsAtDestination = Testing if the archive at the destination path "{0}" exists...
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 18
  ```powershell
  ArchiveExistsAtDestination = The archive at path "{0}" exists at the destination "{1}".
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 18
  ```powershell
  ArchiveExistsAtDestination = The archive at path "{0}" exists at the destination "{1}".
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 19
  ```powershell
  ArchiveDoesNotExistAtDestination = The archive at path "{0}" does not exist at the destination "{1}".
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 19
  ```powershell
  ArchiveDoesNotExistAtDestination = The archive at path "{0}" does not exist at the destination "{1}".
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 26
  ```powershell
  ItemWithArchiveEntryNameExists = An item with the same name as the archive entry exists at the destination path "{0}".
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 27
  ```powershell
  ItemWithArchiveEntryNameDoesNotExist = An item with the same name as the archive entry does not exist at the destination path "{0}".
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\en-US\DSC_xArchive.strings.psd1`

- **Line**: 28
  ```powershell
  ItemWithArchiveEntryNameIsNotDirectory = The item at the destination path "{0}" has the same name as a directory archive entry but is not a directory.
  ```

(1451 more occurrences not shown)

---

### Category: DataExfiltration

#### PS101 - Network Data Transfer

**Severity**: High

**Description**: Detects Invoke-WebRequest or Invoke-RestMethod which can exfiltrate data to external servers

**Remediation**: Log all network operations, validate URLs against allowlist, implement egress filtering

**CVSS Score**: 7.2

**Occurrences**: 2

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xRemoteFile\DSC_xRemoteFile.psm1`

- **Line**: 313
  ```powershell
  Invoke-WebRequest `
                    @PSBoundParameters `
                    -Headers $headersHashtable `
                    -OutFile $DestinationPath
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscPullServerSetup\DscPullServerSetupTest\DscPullServerSetupTest.ps1`

- **Line**: 74
  ```powershell
  Invoke-WebRequest -Uri $script:dscPullServerURL -UseBasicParsing
  ```

---

### Category: DefenseEvasion

#### PS805 - Event Log Clearing

**Severity**: High

**Description**: Detects clearing of event logs to hide malicious activity

**Remediation**: Remove log clearing code, implement proper log retention policies

**CVSS Score**: 7.8

**Occurrences**: 1

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\xPSDesiredStateConfiguration.PSWSIIS\xPSDesiredStateConfiguration.PSWSIIS.psm1`

- **Line**: 620
  ```powershell
  $null = & $script:wevtutil cl Microsoft-Windows-ManagementOdataService/Operational
  ```

---

### Category: FileOperation

#### PS901 - Suspicious File Operations

**Severity**: Medium

**Description**: Detects file operations in sensitive system directories

**Remediation**: Validate file operations in system directories, implement proper access controls

**CVSS Score**: 5.5

**Occurrences**: 14

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1464
  ```powershell
  Push-Location -Path "$env:windir\system32\inetsrv"
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1557
  ```powershell
  $sourceFilePath = Join-Path -Path "$env:windir\SysWOW64\WindowsPowerShell\v1.0\Modules\PSDesiredStateConfiguration\PullServer" `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1559
  ```powershell
  $destinationFolderPath = "$env:windir\SysWOW64\inetsrv"
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1571
  ```powershell
  $sourceFilePath = Join-Path -Path "$env:windir\System32\WindowsPowerShell\v1.0\Modules\PSDesiredStateConfiguration\PullServer" `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1573
  ```powershell
  $destinationFolderPath = "$env:windir\System32\inetsrv"
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 20
  ```powershell
  $script:packageCacheLocation = "$env:ProgramData\Microsoft\Windows\PowerShell\Configuration\BuiltinProvCache\MSFT_xMsiPackage"
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1181
  ```powershell
  $startInfo.FileName = "$env:winDir\system32\msiexec.exe"
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 19
  ```powershell
  $script:packageCacheLocation = "$env:programData\Microsoft\Windows\PowerShell\Configuration\BuiltinProvCache\DSC_xPackageResource"
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 577
  ```powershell
  $startInfo.FileName = "$env:winDir\system32\msiexec.exe"
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 642
  ```powershell
  $startInfo.FileName = "$env:winDir\system32\msiexec.exe"
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xRemoteFile\DSC_xRemoteFile.psm1`

- **Line**: 17
  ```powershell
  $script:cacheLocation = "$env:ProgramData\Microsoft\Windows\PowerShell\Configuration\BuiltinProvCache\DSC_xRemoteFile"
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 70
  ```powershell
  $cacheLocation = "$env:ProgramData\Microsoft\Windows\PowerShell\configuration\BuiltinProvCache\DSC_xFileUpload"
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\xPSDesiredStateConfiguration.Firewall\xPSDesiredStateConfiguration.Firewall.psm1`

- **Line**: 14
  ```powershell
  New-Variable -Name netsh -Value "$env:windir\system32\netsh.exe" -Option ReadOnly -Scope Script -Force
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\xPSDesiredStateConfiguration.PSWSIIS\xPSDesiredStateConfiguration.PSWSIIS.psm1`

- **Line**: 771
  ```powershell
  $script:wevtutil = "$env:windir\system32\Wevtutil.exe"
  ```

---

#### PS903 - File Deletion or Wiping

**Severity**: Medium

**Description**: Detects file deletion operations which may destroy evidence

**Remediation**: Implement file retention policies, log deletion operations

**CVSS Score**: 5.3

**Occurrences**: 18

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 1500
  ```powershell
  Remove-Item -LiteralPath $archiveEntryPathAtDestination
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 1560
  ```powershell
  Remove-Item -LiteralPath $directoryPathAtDestination
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 1657
  ```powershell
  Remove-Item -LiteralPath $archiveEntryPathAtDestination
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 334
  ```powershell
  Remove-Item -Path $downloadedFileName
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 768
  ```powershell
  Remove-Item -Path $LogPath
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 426
  ```powershell
  Remove-Item -Path $LogPath
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 747
  ```powershell
  Remove-Item -Path $downloadedFileName
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscPullServerSetup\DscPullServerSetup.psm1`

- **Line**: 86
  ```powershell
  Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscPullServerSetup\DscPullServerSetup.psm1`

- **Line**: 142
  ```powershell
  $null = Remove-Item -Path $newName -Recurse -Force
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscPullServerSetup\DscPullServerSetup.psm1`

- **Line**: 86
  ```powershell
  Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscPullServerSetup\DscPullServerSetup.psm1`

- **Line**: 142
  ```powershell
  Remove-Item -Path $newName -Recurse -Force
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\xPSDesiredStateConfiguration.PSWSIIS\xPSDesiredStateConfiguration.PSWSIIS.psm1`

- **Line**: 147
  ```powershell
  Remove-Item -Path $path -Recurse -Force
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\xPSDesiredStateConfiguration.PSWSIIS\xPSDesiredStateConfiguration.PSWSIIS.psm1`

- **Line**: 851
  ```powershell
  Get-ChildItem -Path $filePath -Recurse | Remove-Item -Recurse -Force
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\xPSDesiredStateConfiguration.PSWSIIS\xPSDesiredStateConfiguration.PSWSIIS.psm1`

- **Line**: 852
  ```powershell
  Remove-Item -Path $filePath -Force
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\xPSDesiredStateConfiguration.PSWSIIS\xPSDesiredStateConfiguration.PSWSIIS.psm1`

- **Line**: 147
  ```powershell
  Remove-Item -Path $path -Recurse -Force
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\xPSDesiredStateConfiguration.PSWSIIS\xPSDesiredStateConfiguration.PSWSIIS.psm1`

- **Line**: 598
  ```powershell
  Remove-Item IIS:\SSLBindings\0.0.0.0!$port -ErrorAction Ignore
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\xPSDesiredStateConfiguration.PSWSIIS\xPSDesiredStateConfiguration.PSWSIIS.psm1`

- **Line**: 851
  ```powershell
  Remove-Item -Recurse -Force
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\xPSDesiredStateConfiguration.PSWSIIS\xPSDesiredStateConfiguration.PSWSIIS.psm1`

- **Line**: 852
  ```powershell
  Remove-Item -Path $filePath -Force
  ```

---

### Category: Obfuscation

#### PS401 - Base64 Encoded Commands

**Severity**: High

**Description**: Detects Base64 encoded PowerShell commands which may hide malicious intent

**Remediation**: Decode and review encoded content, avoid obfuscation unless necessary for compatibility

**CVSS Score**: 6.5

**Occurrences**: 1

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\xFileUpload\xFileUpload.schema.psm1`

- **Line**: 662
  ```powershell
  $encBytes = [Convert]::FromBase64String($value)
  ```

---

#### PS402 - Character Substitution Obfuscation

**Severity**: Medium

**Description**: Detects character substitution techniques used to evade detection

**Remediation**: Use clear, readable code without obfuscation

**CVSS Score**: 5.8

**Occurrences**: 708

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 7
  ```powershell
  Import-Module -Name (Join-Path -Path $modulePath `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 8
  ```powershell
  -ChildPath (Join-Path -Path 'xPSDesiredStateConfiguration.Common' `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 4
  ```powershell
  Import-Module -Name (Join-Path -Path $modulePath `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 5
  ```powershell
  -ChildPath (Join-Path -Path 'xPSDesiredStateConfiguration.Common' `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 7
  ```powershell
  Import-Module -Name (Join-Path -Path $modulePath `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 8
  ```powershell
  -ChildPath (Join-Path -Path 'xPSDesiredStateConfiguration.PSWSIIS' `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 10
  ```powershell
  Import-Module -Name (Join-Path -Path $modulePath `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 11
  ```powershell
  -ChildPath (Join-Path -Path 'xPSDesiredStateConfiguration.Firewall' `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 13
  ```powershell
  Import-Module -Name (Join-Path -Path $modulePath `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 14
  ```powershell
  -ChildPath (Join-Path -Path 'xPSDesiredStateConfiguration.Security' `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 139
  ```powershell
  $databasePath = Get-WebConfigAppSetting `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 140
  ```powershell
  -WebConfigFullPath $webConfigFullPath `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 147
  ```powershell
  $connectionString = Get-WebConfigAppSetting `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 148
  ```powershell
  -WebConfigFullPath $webConfigFullPath `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 448
  ```powershell
  if ('Present' -eq $Ensure `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 449
  ```powershell
  -and $ApplicationPoolName -ne $DscWebServiceDefaultAppPoolName `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 507
  ```powershell
  New-PSWSEndpoint `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 508
  ```powershell
  -site $EndpointName `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 509
  ```powershell
  -Path $PhysicalPath `
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 510
  ```powershell
  -cfgfile $webConfigFileName `
  ```

(688 more occurrences not shown)

---

#### PS404 - Compression and Decompression

**Severity**: Medium

**Description**: Detects compression/decompression which can hide malicious payloads

**Remediation**: Document why compression is used, validate decompressed content

**CVSS Score**: 5.7

**Occurrences**: 13

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 16
  ```powershell
  Add-Type -AssemblyName 'System.IO.Compression'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 21
  ```powershell
  Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 642
  ```powershell
  [OutputType([System.IO.Compression.ZipArchive])]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 656
  ```powershell
  $archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 682
  ```powershell
  [System.IO.Compression.ZipArchive]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 700
  ```powershell
  [OutputType([System.IO.Compression.ZipArchiveEntry[]])]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 706
  ```powershell
  [System.IO.Compression.ZipArchive]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 729
  ```powershell
  [System.IO.Compression.ZipArchiveEntry]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 752
  ```powershell
  [System.IO.Compression.ZipArchiveEntry]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 855
  ```powershell
  [System.IO.Compression.ZipArchiveEntry]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 1061
  ```powershell
  [System.IO.Compression.ZipArchiveEntry]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 1096
  ```powershell
  [System.IO.Compression.ZipArchiveEntry]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xArchive\DSC_xArchive.psm1`

- **Line**: 1335
  ```powershell
  [System.IO.Compression.ZipArchiveEntry]
  ```

---

#### PS405 - Variable Name Obfuscation

**Severity**: Low

**Description**: Detects suspicious variable names that may indicate obfuscation

**Remediation**: Use descriptive variable names following naming conventions

**CVSS Score**: 3.5

**Occurrences**: 83

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 174
  ```powershell
  $iisPort = $website.bindings.Collection[0].bindingInformation.Split(':')[1]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 176
  ```powershell
  $serverUrl = $urlPrefix + $fqdn + ':' + $iisPort + '/' + $svcFileName
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 184
  ```powershell
  $ConfigureFirewall = Test-PullServerFirewallConfiguration -Port $iisPort
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 198
  ```powershell
  Port                         = $iisPort
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1101
  ```powershell
  $os = Get-OsVersion
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1103
  ```powershell
  return ($os.Major -eq 6 -and $os.Minor -eq 3)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1103
  ```powershell
  return ($os.Major -eq 6 -and $os.Minor -eq 3)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1117
  ```powershell
  $os = Get-OsVersion
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1119
  ```powershell
  return ($os.Major -eq 6 -and $os.Minor -lt 3)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1119
  ```powershell
  return ($os.Major -eq 6 -and $os.Minor -lt 3)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1221
  ```powershell
  $iisInstallPath = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\INetStp' -Name InstallPath).InstallPath
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1223
  ```powershell
  if (-not $iisInstallPath)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1228
  ```powershell
  $assyPath = Join-Path -Path $iisInstallPath -ChildPath 'Microsoft.Web.Administration.dll' -Resolve -ErrorAction:SilentlyContinue
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1533
  ```powershell
  ('' -ne ((& (Get-IISAppCmd) list config -section:system.webServer/globalModules) -like "*$iisSelfSignedModuleName*"))
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1555
  ```powershell
  Write-Verbose -Message ($script:localizedData.InstallIisSelfSignedModule32BitProcess -f $iisSelfSignedModuleAssemblyName)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1558
  ```powershell
  -ChildPath $iisSelfSignedModuleAssemblyName
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1566
  ```powershell
  Write-Verbose -Message ($script:localizedData.IisSelfSignedModuleAlreadyInstalled -f $iisSelfSignedModuleName)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1570
  ```powershell
  Write-Verbose -Message ($script:localizedData.InstallIisSelfSignedModule -f $iisSelfSignedModuleName)
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1572
  ```powershell
  -ChildPath $iisSelfSignedModuleAssemblyName
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1`

- **Line**: 1575
  ```powershell
  -ChildPath $iisSelfSignedModuleAssemblyName
  ```

(63 more occurrences not shown)

---

### Category: ParseError

#### PARSE_ERROR

**Severity**: High

**Description**: File contains PowerShell syntax errors: 1 errors found

**Remediation**: Fix syntax errors before security analysis

**CVSS Score**: 0

**Occurrences**: 1

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscPullServerSetup\DscPullServerSetupTest\DscPullServerSetupTest.ps1`

- **Line**: 0
  ```powershell
  Could not find the module 'PSDesiredStateConfiguration'.
  ```

---

### Category: Persistence

#### PS504 - Startup Folder Modification

**Severity**: Medium

**Description**: Detects file operations in startup folders

**Remediation**: Validate startup programs, implement application control

**CVSS Score**: 6.2

**Occurrences**: 139

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1425
  ```powershell
  public struct STARTUPINFO
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1521
  ```powershell
  ref STARTUPINFO lpStartupInfo,
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1521
  ```powershell
  ref STARTUPINFO lpStartupInfo,
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1645
  ```powershell
  var si = new STARTUPINFO();
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 1933
  ```powershell
  public struct STARTUPINFO
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 2038
  ```powershell
  ref STARTUPINFO lpStartupInfo,
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 2038
  ```powershell
  ref STARTUPINFO lpStartupInfo,
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 2172
  ```powershell
  var si = new STARTUPINFO();
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPSSessionConfiguration\en-US\DSC_xPSSessionConfiguration.strings.psd1`

- **Line**: 13
  ```powershell
  StartupPathNotFoundMessage = Startup path {0} not found
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPSSessionConfiguration\en-US\DSC_xPSSessionConfiguration.strings.psd1`

- **Line**: 13
  ```powershell
  StartupPathNotFoundMessage = Startup path {0} not found
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPSSessionConfiguration\en-US\DSC_xPSSessionConfiguration.strings.psd1`

- **Line**: 15
  ```powershell
  WrongStartupScriptExtensionMessage = The startup script should have a 'ps1' extension, and not '{0}'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPSSessionConfiguration\en-US\DSC_xPSSessionConfiguration.strings.psd1`

- **Line**: 15
  ```powershell
  WrongStartupScriptExtensionMessage = The startup script should have a 'ps1' extension, and not '{0}'
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPSSessionConfiguration\DSC_xPSSessionConfiguration.psm1`

- **Line**: 75
  ```powershell
  StartupScript          = $endpoint.StartupScript
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPSSessionConfiguration\DSC_xPSSessionConfiguration.psm1`

- **Line**: 75
  ```powershell
  StartupScript          = $endpoint.StartupScript
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPSSessionConfiguration\DSC_xPSSessionConfiguration.psm1`

- **Line**: 90
  ```powershell
  .PARAMETER StartupScript
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPSSessionConfiguration\DSC_xPSSessionConfiguration.psm1`

- **Line**: 91
  ```powershell
  Specifies the startup script for the configuration.
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPSSessionConfiguration\DSC_xPSSessionConfiguration.psm1`

- **Line**: 124
  ```powershell
  $StartupScript,
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPSSessionConfiguration\DSC_xPSSessionConfiguration.psm1`

- **Line**: 337
  ```powershell
  .PARAMETER StartupScript
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPSSessionConfiguration\DSC_xPSSessionConfiguration.psm1`

- **Line**: 338
  ```powershell
  Specifies the startup script for the configuration.
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPSSessionConfiguration\DSC_xPSSessionConfiguration.psm1`

- **Line**: 372
  ```powershell
  $StartupScript,
  ```

(119 more occurrences not shown)

---

### Category: PrivilegeEscalation

#### PS301 - Administrator Privilege Check

**Severity**: Medium

**Description**: Detects checks for administrative privileges which may indicate privilege escalation attempts

**Remediation**: Document why administrative privileges are required, implement least privilege principle

**CVSS Score**: 5.3

**Occurrences**: 5

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsOptionalFeature\DSC_xWindowsOptionalFeature.psm1`

- **Line**: 400
  ```powershell
  $windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsOptionalFeature\DSC_xWindowsOptionalFeature.psm1`

- **Line**: 401
  ```powershell
  $windowsPrincipal = New-Object -TypeName 'System.Security.Principal.WindowsPrincipal' -ArgumentList @( $windowsIdentity )
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1`

- **Line**: 974
  ```powershell
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscResource.Common\0.19.0\DscResource.Common.psm1`

- **Line**: 626
  ```powershell
  [Security.Principal.WindowsPrincipal] $user = [Security.Principal.WindowsIdentity]::GetCurrent()
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\DscResource.Common\0.19.0\DscResource.Common.psm1`

- **Line**: 628
  ```powershell
  $isElevated = $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
  ```

---

#### PS303 - Token Manipulation

**Severity**: Critical

**Description**: Detects attempts to manipulate access tokens for privilege escalation

**Remediation**: Remove token manipulation code, use standard Windows security APIs

**CVSS Score**: 9

**Occurrences**: 18

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1524
  ```powershell
  [DllImport("advapi32.dll", EntryPoint = "DuplicateTokenEx")]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1525
  ```powershell
  public static extern bool DuplicateTokenEx(
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1543
  ```powershell
  internal static extern bool AdjustTokenPrivileges(
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1621
  ```powershell
  bResult = AdjustTokenPrivileges(
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1`

- **Line**: 1633
  ```powershell
  bResult = DuplicateTokenEx(
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 2042
  ```powershell
  [DllImport("advapi32.dll", EntryPoint = "DuplicateTokenEx")]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 2043
  ```powershell
  public static extern bool DuplicateTokenEx(
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 2063
  ```powershell
  internal static extern bool AdjustTokenPrivileges(
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 2147
  ```powershell
  bResult = AdjustTokenPrivileges(
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1`

- **Line**: 2160
  ```powershell
  bResult = DuplicateTokenEx(
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\en-US\DSC_xWindowsProcess.strings.psd1`

- **Line**: 5
  ```powershell
  DuplicateTokenError = Duplicate token. Error code:
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1`

- **Line**: 1288
  ```powershell
  [DllImport("api-ms-win-security-base-l1-1-0.dll", EntryPoint = "DuplicateTokenEx")]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1`

- **Line**: 1290
  ```powershell
  [DllImport("advapi32.dll", EntryPoint = "DuplicateTokenEx")]
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1`

- **Line**: 1292
  ```powershell
  public static extern bool DuplicateTokenEx(
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1`

- **Line**: 1320
  ```powershell
  internal static extern bool AdjustTokenPrivileges(
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1`

- **Line**: 1448
  ```powershell
  bResult = AdjustTokenPrivileges(
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1`

- **Line**: 1461
  ```powershell
  bResult = DuplicateTokenEx(
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1`

- **Line**: 1471
  ```powershell
  ThrowException("$($script:localizedData.DuplicateTokenError)" + Marshal.GetLastWin32Error().ToString());
  ```

---

#### PS304 - Service Manipulation

**Severity**: High

**Description**: Detects service creation or modification which can be used for privilege escalation

**Remediation**: Validate service operations, implement proper access controls

**CVSS Score**: 7.8

**Occurrences**: 2

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xServiceResource\DSC_xServiceResource.psm1`

- **Line**: 308
  ```powershell
  New-Service -Name $Name -BinaryPathName $Path
  ```

**File**: `C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xServiceResource\DSC_xServiceResource.psm1`

- **Line**: 1643
  ```powershell
  Set-Service -Name $ServiceName @setServiceParameters
  ```

---


