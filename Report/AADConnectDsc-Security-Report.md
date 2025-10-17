# Security Analysis Report - AADConnectDsc
Generated: 2025-10-17 16:52:19

## Module Summary
- **Module Name**: AADConnectDsc
- **Total Issues Found**: 2
- **Critical Issues**: 0
- **High Issues**: 0
- **Medium Issues**: 2
- **Low Issues**: 0

## Detailed Findings

### Rule: PS019
**Category**: Cryptography  
**File**: C:\CodeVerification\source\AADConnectDsc\0.4.1\AADConnectDsc.psm1  
- **Line**: 758  
  **Code**: $hash = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($InputString))  

**Description**: Use of weak cryptographic algorithm  
**Remediation**: Use stronger algorithms like SHA-256  
**CVSS Score**: 5.5

---

### Rule: PS019
**Category**: Cryptography  
**File**: C:\CodeVerification\source\AADConnectDsc\0.4.1\AADConnectDsc.psm1  
- **Line**: 756  
  **Code**: $md5 = [System.Security.Cryptography.MD5]::Create()  

**Description**: Use of weak cryptographic algorithm  
**Remediation**: Use stronger algorithms like SHA-256  
**CVSS Score**: 5.5

---

