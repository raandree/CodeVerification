# Full Code Review

## Medium and Critical Findings

### Datum.ProtectedData

#### Invoke-ProtectedDatumAction

- **File**: `source/Datum.ProtectedData/0.0.1/Datum.ProtectedData.psm1`
- **Security**: Potential risk with plain text passwords for testing.

#### Protect-Datum

- **File**: `source/Datum.ProtectedData/0.0.1/Datum.ProtectedData.psm1`
- **Security**: Potential risk with plain text passwords for testing.

#### Unprotect-Datum

- **File**: `source/Datum.ProtectedData/0.0.1/Datum.ProtectedData.psm1`
- **Security**: Potential risk with plain text passwords for testing.

### Datum.InvokeCommand

#### Invoke-InvokeCommandActionInternal

- **File**: `source/Datum.InvokeCommand/0.3.0/Datum.InvokeCommand.psm1`
- **Security**: Potential risk with executing script blocks using `&`.

#### Invoke-InvokeCommandAction

- **File**: `source/Datum.InvokeCommand/0.3.0/Datum.InvokeCommand.psm1`
- **Security**: Potential risk with executing script blocks using `&`.

### datum

#### Resolve-NodeProperty

- **File**: `source/datum/0.40.1/ScriptsToProcess/Resolve-NodeProperty.ps1`
- **Security**: Potential risk with `$ExecutionContext.InvokeCommand.InvokeScript`.

#### Invoke-Tool

- **File**: `source/datum/0.40.1/functions.ps1`
- **Security**: Potential risk with `Invoke-Command` and handling sensitive operations like dumping credentials and certificates.
- **Malicious Code**: Contains code to dump credentials and certificates, and manipulate memory and execute shellcode.
