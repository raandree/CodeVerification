# Security Review: datum.psm1

## File Location

`source/datum/0.40.1/datum.psm1`

## Critical Findings

1. **Malicious Code Present**: The module contains a suspicious `Invoke-Tool` function that appears to be credential harvesting tool:
   - Has DumpCreds parameter to dump login passwords
   - Has DumpCerts parameter to export certificates
   - Contains shellcode injection capabilities
   - Located at the end of the file

2. **Unsafe Memory Manipulation**:
   - Functions present for direct memory access and modification
   - Can be used for injecting malicious code
   - Examples: `Write-BytesToMemory`, `Update-MemoryAddresses`

3. **Unsafe DLL Loading**:
   - `Import-DllImports` and `Invoke-MemoryLoadLibrary` allow loading arbitrary DLLs
   - No validation of DLL source or signature

4. **Process Manipulation**:
   - Contains functions to manipulate other processes
   - Can modify memory in remote processes
   - Examples: `Invoke-CreateRemoteThread`, `OpenProcess`

## Medium Level Findings

1. **Limited Input Validation**:
   - Memory addresses and sizes not properly validated
   - Could lead to buffer overflows

2. **Lack of Error Handling**:
   - Many functions don't properly handle errors
   - Could lead to unstable behavior

3. **No Code Signing**:
   - Module not digitally signed
   - No integrity checks on loaded code

## Recommendation

**This module should be considered malicious and removed immediately.**

The presence of credential harvesting capabilities combined with memory manipulation and process injection indicates this is likely a malicious module masked as a legitimate configuration management tool.

## Original Functions vs Malicious Addition

The original module appears to be a legitimate configuration management tool with functions for:

- Managing configuration data
- Handling YAML/JSON/PSD1 files
- Merging configuration data

The malicious code was added at the end of the file, likely to hide it among legitimate functionality.
