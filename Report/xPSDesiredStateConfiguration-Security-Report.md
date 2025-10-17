# Security Analysis Report - xPSDesiredStateConfiguration
Generated: 2025-10-17 16:52:19

## Module Summary
- **Module Name**: xPSDesiredStateConfiguration
- **Total Issues Found**: 12
- **Critical Issues**: 0
- **High Issues**: 0
- **Medium Issues**: 12
- **Low Issues**: 0

## Detailed Findings

### Rule: PS016
**Category**: NetworkSecurity  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1  
- **Line**: 337  
  **Code**: Details http://msdn.microsoft.com/en-us/library/windows/desktop/ms682431(v=vs.85).aspx  

**Description**: Use of insecure HTTP protocol  
**Remediation**: Use HTTPS instead  
**CVSS Score**: 5.2

---

### Rule: PS016
**Category**: NetworkSecurity  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1  
- **Line**: 335  
  **Code**: http://msdn.microsoft.com/en-us/library/0w4h05yb(v=vs.110).aspx  

**Description**: Use of insecure HTTP protocol  
**Remediation**: Use HTTPS instead  
**CVSS Score**: 5.2

---

### Rule: PS016
**Category**: NetworkSecurity  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\xPSDesiredStateConfiguration.PSWSIIS\xPSDesiredStateConfiguration.PSWSIIS.psm1  
- **Line**: 638  
  **Code**: New PSWS Endpoint [@ http://Server:39689/PSWS_Win32Process] by  

**Description**: Use of insecure HTTP protocol  
**Remediation**: Use HTTPS instead  
**CVSS Score**: 5.2

---

### Rule: PS019
**Category**: Cryptography  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xRemoteFile\DSC_xRemoteFile.psm1  
- **Line**: 210  
  **Code**: [ValidateSet('None', 'SHA1', 'SHA256', 'SHA384', 'SHA512', 'MACTripleDES', 'MD5', 'RIPEMD160')]  

**Description**: Use of weak cryptographic algorithm  
**Remediation**: Use stronger algorithms like SHA-256  
**CVSS Score**: 5.5

---

### Rule: PS019
**Category**: Cryptography  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xRemoteFile\DSC_xRemoteFile.psm1  
- **Line**: 480  
  **Code**: [ValidateSet('None', 'SHA1', 'SHA256', 'SHA384', 'SHA512', 'MACTripleDES', 'MD5', 'RIPEMD160')]  

**Description**: Use of weak cryptographic algorithm  
**Remediation**: Use stronger algorithms like SHA-256  
**CVSS Score**: 5.5

---

### Rule: PS019
**Category**: Cryptography  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1  
- **Line**: 1509  
  **Code**: $md5Dest = Get-FileHash -LiteralPath $destinationFilePath -Algorithm MD5  

**Description**: Use of weak cryptographic algorithm  
**Remediation**: Use stronger algorithms like SHA-256  
**CVSS Score**: 5.5

---

### Rule: PS019
**Category**: Cryptography  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xRemoteFile\DSC_xRemoteFile.psm1  
- **Line**: 53  
  **Code**: [ValidateSet('None', 'SHA1', 'SHA256', 'SHA384', 'SHA512', 'MACTripleDES', 'MD5', 'RIPEMD160')]  

**Description**: Use of weak cryptographic algorithm  
**Remediation**: Use stronger algorithms like SHA-256  
**CVSS Score**: 5.5

---

### Rule: PS019
**Category**: Cryptography  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1  
- **Line**: 166  
  **Code**: [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5', 'RIPEMD160')]  

**Description**: Use of weak cryptographic algorithm  
**Remediation**: Use stronger algorithms like SHA-256  
**CVSS Score**: 5.5

---

### Rule: PS019
**Category**: Cryptography  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xDSCWebService\DSC_xDSCWebService.psm1  
- **Line**: 1510  
  **Code**: $md5Src = Get-FileHash -LiteralPath $sourceFilePath -Algorithm MD5  

**Description**: Use of weak cryptographic algorithm  
**Remediation**: Use stronger algorithms like SHA-256  
**CVSS Score**: 5.5

---

### Rule: PS019
**Category**: Cryptography  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xMsiPackage\DSC_xMsiPackage.psm1  
- **Line**: 475  
  **Code**: [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5', 'RIPEMD160')]  

**Description**: Use of weak cryptographic algorithm  
**Remediation**: Use stronger algorithms like SHA-256  
**CVSS Score**: 5.5

---

### Rule: PS019
**Category**: Cryptography  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1  
- **Line**: 955  
  **Code**: [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5', 'RIPEMD160')]  

**Description**: Use of weak cryptographic algorithm  
**Remediation**: Use stronger algorithms like SHA-256  
**CVSS Score**: 5.5

---

### Rule: PS019
**Category**: Cryptography  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xPackageResource\DSC_xPackageResource.psm1  
- **Line**: 329  
  **Code**: [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5', 'RIPEMD160')]  

**Description**: Use of weak cryptographic algorithm  
**Remediation**: Use stronger algorithms like SHA-256  
**CVSS Score**: 5.5

---

