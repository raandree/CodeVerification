# Detection Rules Configuration
# Defines security patterns and vulnerabilities to detect in PowerShell code

@{
    Rules = @(
        @{
            Id = 'PS001'
            Name = 'Invoke-Expression Usage'
            Severity = 'Medium'
            Category = 'CodeExecution'
            Description = 'Detects use of Invoke-Expression which can execute arbitrary code from strings'
            ASTPattern = 'CommandAst'
            CommandName = 'Invoke-Expression'
            Remediation = 'Replace Invoke-Expression with safer alternatives like & operator or dot-sourcing'
            CVSS = 5.3
        },
        @{
            Id = 'PS002'
            Name = 'Base64 Encoded Command'
            Severity = 'High'
            Category = 'Obfuscation'
            Description = 'Detects base64-encoded commands often used to hide malicious intent'
            RegexPattern = '(-enc|-encodedcommand)\s+[A-Za-z0-9+/=]{20,}'
            Remediation = 'Decode and review the command contents for legitimacy'
            CVSS = 7.5
        },
        @{
            Id = 'PS003'
            Name = 'Hardcoded Credentials'
            Severity = 'Critical'
            Category = 'CredentialExposure'
            Description = 'Detects hardcoded passwords or credentials in plaintext'
            RegexPattern = '(password|pwd|credential|secret|apikey|token)\s*=\s*[''"](?!.*\$.*)[^''"]{8,}[''"]'
            Remediation = 'Use secure credential storage like Azure Key Vault or SecureString'
            CVSS = 9.8
        }
        @{
            Id = 'PS015'
            Name = 'AMSI Bypass Attempt'
            Severity = 'Critical'
            Category = 'SecurityBypass'
            Description = 'Detects attempts to bypass Windows Antimalware Scan Interface'
            RegexPattern = 'amsi|AmsiUtils|amsiInitFailed'
            Remediation = 'Remove AMSI bypass code - this is highly suspicious'
            CVSS = 9.5
        }
    )
}
