# Basic Security Analysis Report
Generated: 2025-10-17 16:49:22

## Summary
- **Files Scanned**: 71
- **Issues Found**: 5
- **Critical**: 0
- **High**: 0
- **Medium**: 5

## Findings

### PS016 - Insecure HTTP protocol detected
**Category**: NetworkSecurity  
**Severity**: Medium  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xRemoteFile\DSC_xRemoteFile.psm1  
**Line**: 151  

**Code**:
```
(e.g 'http://10.20.30.1').
```

**Remediation**: Use HTTPS instead

---

### PS016 - Insecure HTTP protocol detected
**Category**: NetworkSecurity  
**Severity**: Medium  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xRemoteFile\DSC_xRemoteFile.psm1  
**Line**: 420  

**Code**:
```
(e.g 'http://10.20.30.1').
```

**Remediation**: Use HTTPS instead

---

### PS016 - Insecure HTTP protocol detected
**Category**: NetworkSecurity  
**Severity**: Medium  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1  
**Line**: 335  

**Code**:
```
http://msdn.microsoft.com/en-us/library/0w4h05yb(v=vs.110).aspx
```

**Remediation**: Use HTTPS instead

---

### PS016 - Insecure HTTP protocol detected
**Category**: NetworkSecurity  
**Severity**: Medium  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\DSCResources\DSC_xWindowsProcess\DSC_xWindowsProcess.psm1  
**Line**: 337  

**Code**:
```
Details http://msdn.microsoft.com/en-us/library/windows/desktop/ms682431(v=vs.85).aspx
```

**Remediation**: Use HTTPS instead

---

### PS016 - Insecure HTTP protocol detected
**Category**: NetworkSecurity  
**Severity**: Medium  
**File**: C:\CodeVerification\source\xPSDesiredStateConfiguration\9.2.1\Modules\xPSDesiredStateConfiguration.PSWSIIS\xPSDesiredStateConfiguration.PSWSIIS.psm1  
**Line**: 638  

**Code**:
```
New PSWS Endpoint [@ http://Server:39689/PSWS_Win32Process] by
```

**Remediation**: Use HTTPS instead

---

