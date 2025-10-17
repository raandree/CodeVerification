# CodeVerification Setup and Execution Guide

## Overview

This guide provides comprehensive instructions for setting up a machine to perform automated PowerShell security code verification and then executing the verification workflow using GitHub Copilot.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Machine Preparation](#machine-preparation)
  - [Installing Chocolatey](#installing-chocolatey)
  - [Installing Required Software](#installing-required-software)
  - [Configuring Windows Defender](#configuring-windows-defender)
  - [Post-Installation Verification](#post-installation-verification)
- [Copilot Execution Workflow](#copilot-execution-workflow)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)
- [Security Considerations](#security-considerations)

---

## Prerequisites

Before starting, ensure you have:

- **Windows 10/11** or **Windows Server 2016+**
- **Administrator privileges** on the machine
- **Internet connectivity** for downloading packages
- **GitHub Copilot** subscription and VS Code configured with Copilot
- **Sufficient disk space** (minimum 10GB free recommended)

---

## Machine Preparation

### Installing Chocolatey

Chocolatey is a package manager for Windows that simplifies software installation.

1. Open **PowerShell** as **Administrator**
2. Execute the following script:

```powershell
# Set execution policy for this process
Set-ExecutionPolicy Bypass -Scope Process -Force

# Configure TLS 1.2 support
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# Download and install Chocolatey
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

1. **Verify installation:**

```powershell
choco --version
```

Expected output: Version number (e.g., `2.3.0`)

### Installing Required Software

Install the necessary tools for PowerShell development and analysis:

```powershell
# Install PowerShell Core (latest version)
choco install powershell-core -y

# Install Git for version control
choco install git.install -y

# Install Visual Studio Code (if not already installed)
choco install vscode -y

# Note: Uncomment the line below only if you need to reinstall VS Code
# choco uninstall vscode -y
```

**Additional recommended installations:**

```powershell
# Install PSScriptAnalyzer for code analysis
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -AllowClobber

# Install Pester for testing framework
Install-Module -Name Pester -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
```

### Configuring Windows Defender

**⚠️ WARNING:** Disabling Windows Defender reduces system security. Only do this on isolated test/development machines, never on production systems.

**Recommended approach - Add exclusions instead:**

```powershell
# Add folder exclusion for the project directory
Add-MpPreference -ExclusionPath "D:\Git\CodeVerification"

# Add process exclusion for PowerShell and VS Code
Add-MpPreference -ExclusionProcess "pwsh.exe", "powershell.exe", "Code.exe"
```

**Alternative - Full disable (NOT RECOMMENDED for production):**

```powershell
# Disable Windows Defender real-time protection (requires admin)
Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -DisableBehaviorMonitoring $true
Set-MpPreference -DisableBlockAtFirstSeen $true
Set-MpPreference -DisableIOAVProtection $true
Set-MpPreference -DisablePrivacyMode $true
Set-MpPreference -SignatureDisableUpdateOnStartupWithoutEngine $true

# Verify status
Get-MpPreference | Select-Object -Property Disable*
```

**Re-enable Windows Defender when done:**

```powershell
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -DisableBehaviorMonitoring $false
Set-MpPreference -DisableBlockAtFirstSeen $false
Set-MpPreference -DisableIOAVProtection $false
Set-MpPreference -DisablePrivacyMode $false
Set-MpPreference -SignatureDisableUpdateOnStartupWithoutEngine $false
```

### Post-Installation Verification

Verify all components are installed correctly:

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Check Git installation
git --version

# Check VS Code installation
code --version

# Check required PowerShell modules
Get-Module -Name PSScriptAnalyzer -ListAvailable
Get-Module -Name Pester -ListAvailable

# Verify Chocolatey packages
choco list --local-only
```

---

## Copilot Execution Workflow

### Starting the Automated Code Review

1. **Open VS Code** in the project directory:

```powershell
cd D:\Git\CodeVerification
code .
```

1. **Open GitHub Copilot Chat** in VS Code

1. **Execute the following prompt:**

```text
Please scan the file ./.work/prompts.md and execute the prompts in that file one by one until all the work described in the prompts is done.

IMPORTANT: Finish all the prompts even if you think that 'all primary objectives' have been completed.
```

### Workflow Steps

The automated workflow will execute the following phases:

1. **Prompt 1** - Initial setup: Create memory bank and project documentation
2. **Prompt 2.1** - Define detection rules based on security guidelines
3. **Prompt 2.2** - Realign rules for PowerShell-specific context
4. **Prompt 2.3** - Generate security scanning scripts
5. **Prompt 3** - Execute comprehensive code review and generate reports
6. **Prompt 4** - Review and complete pending tasks
7. **Prompt 5** - Create comprehensive README files
8. **Prompt 6** - Execute optional tasks

### Expected Outputs

After completion, you should have:

- **Memory Bank** - Project context and progress tracking
- **Detection Rules** - Security rule definitions
- **Scanning Scripts** - Automated security analysis tools
- **Reports/**
  - Executive summary covering all modules
  - Detailed reports per PowerShell module
- **README files** - Documentation throughout the project structure

---

## Troubleshooting

### Common Issues

#### Issue: Chocolatey installation fails

- Solution: Ensure you're running PowerShell as Administrator
- Check internet connectivity
- Verify TLS 1.2 is enabled

#### Issue: Module installation fails

- Solution: Update PowerShellGet first:

```powershell
Install-Module -Name PowerShellGet -Force -AllowClobber
```

#### Issue: Execution policy prevents script execution

- Solution: Set execution policy for current user:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Issue: Git command not found after installation

- Solution: Close and reopen PowerShell to refresh PATH
- Or manually add to PATH: `C:\Program Files\Git\cmd`

#### Issue: Copilot doesn't complete all prompts

- Solution: Manually verify progress through prompts.md
- Re-prompt for incomplete sections
- Check memory bank for task status

### Verification Commands

```powershell
# Check if all required tools are in PATH
Get-Command choco, git, code, pwsh -ErrorAction SilentlyContinue

# Verify PowerShell modules
Get-InstalledModule | Where-Object { $_.Name -in @('PSScriptAnalyzer', 'Pester') }

# Check Windows Defender status
Get-MpComputerStatus
```

---

## Resources

### Official Documentation

- [Chocolatey Official Site](https://chocolatey.org/)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
- [Pester Testing Framework](https://pester.dev/)
- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)

### Security Resources

- [PowerShell Security Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/security/securing-powershell)
- [DSC Community Security Guidelines](https://github.com/dsccommunity)
- [Nishang PowerShell Framework](https://github.com/samratashok/nishang/releases)
- [CVSS Scoring System](https://www.first.org/cvss/)

### Project-Specific Resources

- [Prompts Definition](./.work/prompts.md) - Detailed workflow prompts
- [Memory Bank](../memory-bank/) - Project context and progress (created during execution)
- [Reports](../Reports/) - Generated security analysis reports (created during execution)

---

## Security Considerations

### Important Notes

1. **Isolated Environment**: Perform security analysis in an isolated development/test environment
2. **Defender Configuration**: Use folder/process exclusions instead of full disable when possible
3. **Credential Management**: Never commit real credentials to the repository
4. **Code Review**: Always review generated scripts before execution in production
5. **Backup**: Maintain backups before making system-level changes
6. **Re-enable Protection**: Remember to re-enable Windows Defender after analysis

### Audit Trail

Document all changes made during setup:

```powershell
# Create audit log
$AuditLog = @{
    Timestamp = Get-Date
    User = $env:USERNAME
    Machine = $env:COMPUTERNAME
    Changes = @()
}

# Add to audit log as you make changes
$AuditLog.Changes += "Installed Chocolatey"
$AuditLog.Changes += "Configured Windows Defender exclusions"

# Save audit log
$AuditLog | ConvertTo-Json | Out-File "D:\Git\CodeVerification\.work\setup-audit.json"
```

---

## Maintenance

### Keeping Tools Updated

```powershell
# Update Chocolatey packages
choco upgrade all -y

# Update PowerShell modules
Update-Module -Name PSScriptAnalyzer, Pester

# Update Git
git update-git-for-windows
```

### Cleanup

When the project is complete:

```powershell
# Remove Windows Defender exclusions
Remove-MpPreference -ExclusionPath "D:\Git\CodeVerification"
Remove-MpPreference -ExclusionProcess "pwsh.exe", "powershell.exe", "Code.exe"

# Re-enable Windows Defender (if disabled)
Set-MpPreference -DisableRealtimeMonitoring $false
```
