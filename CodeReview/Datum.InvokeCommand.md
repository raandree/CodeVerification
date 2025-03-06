# Security Review: Datum.InvokeCommand Module

## Module Location
- File: source/Datum.InvokeCommand/0.3.0/Datum.InvokeCommand.psm1

## Module Overview
The Datum.InvokeCommand module provides functionality for executing PowerShell commands and scriptblocks within Datum configurations.

## Functions Analysis

### Public Functions

1. `Invoke-InvokeCommandAction`
   - Location: Public/Invoke-InvokeCommandAction.ps1
   - Purpose: Command execution handler for Datum
   - Security Concerns:
     - ⚠️ CRITICAL: Executes arbitrary scriptblocks from configuration data
     - ⚠️ CRITICAL: Uses InvokeCommand.ExpandString for string expansion
     - ⚠️ Global variable usage for state management
   - Best Practices:
     - ✅ Implements error handling
     - ✅ Uses parameter validation
     - ❌ Lacks privilege checks
     - ❌ Missing input sanitization

2. `Test-InvokeCommandFilter`
   - Location: Public/Test-InvokeCommandFilter.ps1
   - Purpose: Validates if content matches command execution pattern
   - Security Assessment:
     - ⚠️ Uses global regex pattern
     - ✅ Input validation present
     - ✅ Type checking implemented

### Private Functions

1. `Get-DatumCurrentNode`
   - Security Concerns:
     - ⚠️ Uses ConvertFrom-Yaml without validation
     - ⚠️ Direct file content reading
   - Best Practices:
     - ❌ Missing error handling
     - ❌ No input validation

2. `Get-ValueKind`
   - Purpose: Parses and identifies PowerShell code types
   - Security Considerations:
     - ⚠️ Uses PowerShell parser on untrusted input
     - ✅ Good input validation
     - ✅ Proper error handling

3. `Invoke-InvokeCommandActionInternal`
   - Security Concerns:
     - ⚠️ CRITICAL: Creates and executes dynamic scriptblocks
     - ⚠️ CRITICAL: Uses global variables
     - ⚠️ CRITICAL: Allows recursive command execution
   - Best Practices:
     - ✅ Implements basic error handling
     - ❌ No execution scope limitations
     - ❌ Missing privilege checks

## Critical Security Findings

1. Remote Code Execution Risks:
   ```powershell
   $command = [scriptblock]::Create($DatumType.Value)
   & (& $command)
   ```
   - Allows execution of arbitrary PowerShell code
   - No validation of scriptblock content
   - Double execution pattern increases risk

2. Unsafe String Expansion:
   ```powershell
   $ExecutionContext.InvokeCommand.ExpandString($result)
   ```
   - Could lead to unintended code execution
   - No sanitization of expanded strings

3. Global State Usage:
   ```powershell
   $global:CurrentDatumNode = $Node
   $global:CurrentDatumFile = $file
   ```
   - Global variables could be tampered with
   - State manipulation risks

4. Unsafe YAML Processing:
   ```powershell
   $fileNode = $File | Get-Content | ConvertFrom-Yaml
   ```
   - No validation of YAML content
   - Potential deserialization attacks

## Recommendations

1. Code Execution Safety:
   - Implement a strict allowlist for permitted commands
   - Add scriptblock signing requirements
   - Create an isolated runspace for command execution
   - Add privilege level checks before execution

2. Input Validation:
   - Validate all YAML content before processing
   - Implement strict input sanitization
   - Add content validation for scriptblocks

3. State Management:
   - Remove global variable usage
   - Implement state isolation
   - Use secure parameter passing

4. Error Handling:
   - Add comprehensive try-catch blocks
   - Implement secure error logging
   - Add execution timeout limits

5. Security Boundaries:
   - Implement command execution scopes
   - Add execution policy enforcement
   - Implement command blacklisting

## Best Practice Implementation Recommendations

1. Add Verbose Logging:
   ```powershell
   Write-Verbose "Executing command with ID: $callId"
   Write-Verbose "Command context: $context"
   ```

2. Input Validation:
   ```powershell
   [ValidateScript({Test-ScriptBlockSafety -ScriptBlock $_})]
   [ScriptBlock]$ScriptBlock
   ```

3. Error Handling:
   ```powershell
   try {
       [System.Management.Automation.PSSerializer]::Deserialize($serialData)
   }
   catch {
       Write-Error "Failed to deserialize: $_"
   }
   ```

## Overall Assessment
This module presents significant security risks due to its ability to execute arbitrary code. While it implements some security measures, the core functionality is inherently dangerous and should be used with extreme caution. Consider reimplementing with stricter security boundaries and command restrictions.

### Risk Level: HIGH
- Remote code execution possible
- Insufficient input validation
- Unsafe global state management
- Lack of execution boundaries
