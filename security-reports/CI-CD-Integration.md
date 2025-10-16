# CI/CD Integration Guide

## Overview
This guide explains how to integrate the CodeVerification security scanner into your CI/CD pipeline for automated PowerShell module security scanning.

## Quick Start

### GitHub Actions

Create `.github/workflows/security-scan.yml`:

```yaml
name: Security Scan

on:
  push:
    paths:
      - ''source/**''
  pull_request:
    paths:
      - ''source/**''

jobs:
  security-scan:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Security Scan
        shell: pwsh
        run: |
          cd scripts
          $findings = .\Invoke-SecurityScan.ps1
          
      - name: Check Results
        shell: pwsh
        run: |
          $json = Get-Content security-reports/security-scan-results.json | ConvertFrom-Json
          if ($json.verdict.genuineVulnerabilities -gt 0) {
            Write-Error "Security vulnerabilities detected!"
            exit 1
          }
          
      - name: Upload Reports
        uses: actions/upload-artifact@v3
        with:
          name: security-reports
          path: security-reports/
```

### Azure DevOps

Add to `azure-pipelines.yml`:

```yaml
stages:
- stage: SecurityScan
  jobs:
  - job: ScanModules
    pool:
      vmImage: ''windows-latest''
    steps:
    - pwsh: |
        cd scripts
        .\Invoke-SecurityScan.ps1
      displayName: ''Run Security Scan''
      
    - pwsh: |
        $json = Get-Content security-reports/security-scan-results.json | ConvertFrom-Json
        if ($json.verdict.genuineVulnerabilities -gt 0) {
          Write-Host "##vso[task.logissue type=error]Security vulnerabilities detected"
          exit 1
        }
      displayName: ''Validate Results''
      
    - publish: security-reports
      artifact: SecurityReports
```

## Exit Codes

- `0` - No genuine security issues (safe to deploy)
- `1` - Security vulnerabilities detected (block deployment)
- `2` - Scan failed (investigate error)

## JSON Output Format

```json
{
  "metadata": {
    "generatedAt": "2025-10-16T14:50:00Z",
    "scanner": "CodeVerification",
    "version": "1.1.0"
  },
  "summary": {
    "totalFindings": 32,
    "critical": 2,
    "high": 28,
    "medium": 2,
    "low": 0
  },
  "verdict": {
    "approved": true,
    "risk": "LOW",
    "genuineVulnerabilities": 0
  }
}
```

## Integration Tips

1. **Cache Baseline**: Store `security-baseline.json` to track changes over time
2. **Parallel Execution**: Scan multiple modules concurrently
3. **Custom Thresholds**: Adjust detection rules for your environment
4. **Report Archiving**: Keep historical reports for audit trails
5. **Notifications**: Alert security teams on critical findings

## Advanced Configuration

### Custom Detection Rules

Edit `scripts/detection-rules.psd1` to add organization-specific patterns:

```powershell
@{
    Id = ''CUSTOM001''
    Name = ''Internal API Usage''
    Severity = ''Medium''
    RegexPattern = ''internal-api\.company\.com''
    Remediation = ''Verify internal API usage is authorized''
}
```

### Automated Remediation

Create a remediation workflow that automatically creates issues or PRs for findings.

### Compliance Reporting

Generate compliance reports mapping findings to frameworks (CIS, NIST, etc.).

## Support

For issues or questions, see the project documentation in `memory-bank/`.
