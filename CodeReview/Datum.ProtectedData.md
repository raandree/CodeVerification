# Security Review: Datum.ProtectedData Module

## Module Location
- File: source/Datum.ProtectedData/0.0.1/Datum.ProtectedData.psm1

## Module Overview
The Datum.ProtectedData module provides encryption and decryption capabilities for sensitive data within Datum configurations.

## Functions Analysis

### Public Functions

1. `Invoke-ProtectedDatumAction`
   - Purpose: Decrypts secrets when Datum handler is triggered
   - Security Concerns:
     - ⚠️ CRITICAL: Accepts plaintext passwords through parameter
     - ⚠️ Suppresses PSScriptAnalyzer security rules
     - ⚠️ Uses ConvertTo-SecureString with plaintext
   - Best Practices:
     - ✅ Parameter validation implemented
     - ✅ Certificate-based encryption supported
     - ❌ Plaintext password option should be removed

2. `Protect-Datum`
   - Purpose: Encrypts objects into secured strings
   - Security Concerns:
     - ⚠️ Uses PSSerializer for object serialization
     - ⚠️ Base64 encoding might expose patterns
   - Best Practices:
     - ✅ Supports certificate-based encryption
     - ✅ Proper parameter validation
     - ✅ SecureString usage for passwords

3. `Test-ProtectedDatumFilter`
   - Purpose: Validates encrypted data format
   - Security Assessment:
     - ✅ Simple validation function
     - ✅ Clear pattern matching
     - ❌ Could use more strict validation

4. `Unprotect-Datum`
   - Purpose: Decrypts previously encrypted objects
   - Security Concerns:
     - ⚠️ CRITICAL: PSSerializer deserialization risks
     - ⚠️ Base64 decoding without validation
   - Best Practices:
     - ✅ Supports certificate-based decryption
     - ✅ Parameter validation present
     - ❌ Missing input sanitization

## Critical Security Findings

1. Serialization Vulnerabilities:
   ```powershell
   $xml = [System.Management.Automation.PSSerializer]::Serialize($securedData, 5)
   ```
   - Potential for deserialization attacks
   - No type restrictions on serialized objects

2. Plaintext Password Support:
   ```powershell
   [Parameter(ParameterSetName = 'ByPassword')]
   [String]
   $PlainTextPassword
   ```
   - Should not support plaintext passwords
   - Security rule suppressions are concerning

3. Unsafe Deserialization:
   ```powershell
   $obj = [System.Management.Automation.PSSerializer]::Deserialize($xml)
   ```
   - No type checking before deserialization
   - Could lead to code execution

4. Weak Encoding Practices:
   ```powershell
   $bytes = [System.Convert]::FromBase64String($Base64Data)
   $xml = [System.Text.Encoding]::UTF8.GetString($bytes)
   ```
   - No validation of encoded content
   - Potential for malformed input attacks

## Recommendations

1. Remove Plaintext Password Support:
   - Remove the plaintext password parameter
   - Enforce certificate-based encryption only
   - Add strong password policy if passwords must be used

2. Improve Serialization Security:
   ```powershell
   # Add type restrictions
   [ValidateScript({
       $allowedTypes = @('PSCredential', 'SecureString')
       $_.GetType().Name -in $allowedTypes
   })]
   [Parameter(Mandatory)]
   $InputObject
   ```

3. Add Content Validation:
   ```powershell
   # Validate Base64 content
   if (-not [System.Convert]::IsBase64String($Base64Data)) {
       throw "Invalid Base64 content"
   }
   ```

4. Implement Encryption Best Practices:
   - Use strong encryption algorithms
   - Implement key rotation mechanism
   - Add encryption metadata for versioning

5. Enhanced Security Controls:
   - Add integrity checks for encrypted data
   - Implement encryption key management
   - Add audit logging for encryption/decryption operations

## Best Practice Implementation Examples

1. Certificate Validation:
   ```powershell
   function Test-Certificate {
       param([string]$Thumbprint)
       $cert = Get-Item "Cert:\LocalMachine\My\$Thumbprint" -ErrorAction Stop
       if (-not $cert.HasPrivateKey) {
           throw "Certificate must have private key"
       }
   }
   ```

2. Secure Deserialization:
   ```powershell
   function Test-SerializedContent {
       param([string]$Content)
       # Add validation logic
       if ($Content -match 'TypeName="System.Management.Automation.ScriptBlock"') {
           throw "ScriptBlock deserialization not allowed"
       }
   }
   ```

3. Improved Error Handling:
   ```powershell
   try {
       $decrypted = Unprotect-Data @UnprotectDataParams
   }
   catch {
       Write-Error "Decryption failed: $_"
       throw "Security violation in decryption process"
   }
   ```

## Overall Assessment
The module provides essential encryption functionality but has several security concerns that need addressing. The use of plaintext passwords and unsafe deserialization practices pose significant risks.

### Risk Level: MEDIUM-HIGH
- Plaintext password support
- Unsafe deserialization
- Lack of content validation
- Basic encryption patterns visible through Base64 encoding
