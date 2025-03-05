# Code Review for datum

## Functions Analyzed

### Resolve-NodeProperty

- **File**: `source/datum/0.40.1/ScriptsToProcess/Resolve-NodeProperty.ps1`
- **Security**: Potential risk with `$ExecutionContext.InvokeCommand.InvokeScript`.
- **Malicious Code**: No signs of malicious code.
- **Best Practices**: Generally follows best practices, with good parameter definitions and logging.

### Invoke-Tool

- **File**: `source/datum/0.40.1/functions.ps1`
- **Security**: Potential risk with `Invoke-Command` and handling sensitive operations like dumping credentials and certificates.
- **Malicious Code**: Contains code to dump credentials and certificates, and manipulate memory and execute shellcode.
- **Best Practices**: Generally follows best practices, with good parameter definitions, strict mode, and logging.
