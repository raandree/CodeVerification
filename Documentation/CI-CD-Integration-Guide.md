# CI/CD Integration Guide for PowerShell Security Analysis

This document provides comprehensive guidance for integrating the PowerShell security analysis framework into continuous integration and deployment pipelines.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Azure DevOps Integration](#azure-devops-integration)
3. [GitHub Actions Integration](#github-actions-integration)
4. [Jenkins Integration](#jenkins-integration)
5. [Configuration Best Practices](#configuration-best-practices)
6. [Security Considerations](#security-considerations)
7. [Troubleshooting](#troubleshooting)

## 🎯 Overview

### Integration Benefits
- **Automated Security Testing**: Continuous security validation with every code change
- **Early Detection**: Identify security issues before production deployment
- **Compliance**: Maintain audit trails and security documentation
- **Quality Gates**: Enforce security standards as part of the build process

### Available Tools
| Tool | Purpose | CI/CD Ready | Output Format |
|------|---------|-------------|---------------|
| `Run-WorkingAnalysis.ps1` | Basic security analysis | ✅ Yes | Markdown, Console |
| `Invoke-EnhancedPSScriptAnalyzer.ps1` | PSScriptAnalyzer integration | ✅ Yes | Markdown, CSV, XML |
| `Invoke-EnhancedPesterTests.ps1` | Pester security testing | ✅ Yes | NUnitXml, Markdown |
| `Start-SecurityAnalysis.ps1` | Comprehensive analysis | ✅ Yes | Multiple formats |

## 🔵 Azure DevOps Integration

### Basic Pipeline Configuration

#### YAML Pipeline (azure-pipelines.yml)
```yaml
trigger:
  branches:
    include:
    - main
    - develop
  paths:
    include:
    - source/**
    - Scripts/**

pool:
  vmImage: 'windows-latest'

variables:
  buildConfiguration: 'Release'
  sourceDirectory: '$(Build.SourcesDirectory)'
  reportDirectory: '$(Build.ArtifactStagingDirectory)/SecurityReports'

stages:
- stage: SecurityAnalysis
  displayName: 'Security Analysis'
  jobs:
  - job: PowerShellSecurityScan
    displayName: 'PowerShell Security Scan'
    steps:
    
    # Prerequisites
    - task: PowerShell@2
      displayName: 'Install Required Modules'
      inputs:
        targetType: 'inline'
        script: |
          Write-Host "Installing PSScriptAnalyzer and Pester..."
          Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
          Install-Module -Name Pester -Force -Scope CurrentUser -SkipPublisherCheck
        failOnStderr: false
    
    # Basic Security Analysis
    - task: PowerShell@2
      displayName: 'Run Basic Security Analysis'
      inputs:
        targetType: 'filePath'
        filePath: 'Scripts/Run-WorkingAnalysis.ps1'
        arguments: '-SourcePath "$(sourceDirectory)/source" -OutputPath "$(reportDirectory)"'
        failOnStderr: false
      continueOnError: true
    
    # Enhanced PSScriptAnalyzer
    - task: PowerShell@2
      displayName: 'Run Enhanced PSScriptAnalyzer'
      inputs:
        targetType: 'filePath'
        filePath: 'Scripts/Invoke-EnhancedPSScriptAnalyzer.ps1'
        arguments: '-SourcePath "$(sourceDirectory)/source" -OutputPath "$(reportDirectory)" -GenerateReport'
        failOnStderr: false
      continueOnError: true
    
    # Pester Security Tests
    - task: PowerShell@2
      displayName: 'Run Pester Security Tests'
      inputs:
        targetType: 'filePath'
        filePath: 'Scripts/Invoke-EnhancedPesterTests.ps1'
        arguments: '-SourcePath "$(sourceDirectory)/source" -OutputPath "$(reportDirectory)" -TestResultsFile "PesterResults.xml"'
        failOnStderr: false
    
    # Publish Test Results
    - task: PublishTestResults@2
      displayName: 'Publish Pester Test Results'
      inputs:
        testResultsFormat: 'NUnit'
        testResultsFiles: '$(reportDirectory)/PesterResults.xml'
        mergeTestResults: true
        testRunTitle: 'PowerShell Security Tests'
      condition: always()
    
    # Publish Security Reports
    - task: PublishBuildArtifacts@1
      displayName: 'Publish Security Reports'
      inputs:
        pathToPublish: '$(reportDirectory)'
        artifactName: 'SecurityAnalysisReports'
        publishLocation: 'Container'
      condition: always()
    
    # Create Work Items for High/Critical Issues
    - task: PowerShell@2
      displayName: 'Create Work Items for Security Issues'
      inputs:
        targetType: 'inline'
        script: |
          # Check for critical/high severity issues and create work items
          $reportPath = "$(reportDirectory)/Executive-Summary.md"
          if (Test-Path $reportPath) {
            $content = Get-Content $reportPath -Raw
            if ($content -match "Critical|High") {
              Write-Host "##vso[task.logissue type=warning]Security issues found - review required"
              # Additional logic to create work items can be added here
            }
          }
      condition: always()

# Release Pipeline Integration
- stage: SecurityGate
  displayName: 'Security Gate'
  dependsOn: SecurityAnalysis
  condition: succeeded()
  jobs:
  - job: SecurityApproval
    displayName: 'Security Review Gate'
    pool: server
    steps:
    - task: ManualValidation@0
      displayName: 'Security Team Review'
      inputs:
        notifyUsers: |
          security-team@company.com
        instructions: |
          Please review the security analysis results before approving deployment.
          
          Reports available in build artifacts:
          - Executive Summary
          - Detailed Analysis Reports
          - PSScriptAnalyzer Results
          - Pester Test Results
      timeoutInMinutes: 1440 # 24 hours
```

### Advanced Pipeline Features

#### Multi-Stage Security Pipeline
```yaml
# Extended pipeline with multiple security stages
stages:
- stage: StaticAnalysis
  displayName: 'Static Security Analysis'
  jobs:
  - template: templates/security-analysis.yml
    parameters:
      sourceDirectory: '$(Build.SourcesDirectory)'
      reportDirectory: '$(Build.ArtifactStagingDirectory)'

- stage: DynamicTesting
  displayName: 'Dynamic Security Testing'
  dependsOn: StaticAnalysis
  jobs:
  - template: templates/pester-testing.yml
    parameters:
      testSuite: 'Security'
      
- stage: ComplianceCheck
  displayName: 'Compliance Validation'
  dependsOn: DynamicTesting
  jobs:
  - template: templates/compliance-check.yml
```

#### Template: security-analysis.yml
```yaml
# Template for reusable security analysis
parameters:
- name: sourceDirectory
  type: string
- name: reportDirectory
  type: string
- name: minimumSeverity
  type: string
  default: 'Medium'

jobs:
- job: SecurityAnalysis
  displayName: 'Security Analysis'
  steps:
  - task: PowerShell@2
    displayName: 'Security Scan'
    inputs:
      targetType: 'filePath'
      filePath: 'Scripts/Start-SecurityAnalysis.ps1'
      arguments: >
        -SourcePath "${{ parameters.sourceDirectory }}/source"
        -OutputPath "${{ parameters.reportDirectory }}"
        -MinimumSeverity "${{ parameters.minimumSeverity }}"
        -IncludePSScriptAnalyzer
        -RunPesterTests
```

## 🐙 GitHub Actions Integration

### Workflow Configuration

#### .github/workflows/security-analysis.yml
```yaml
name: PowerShell Security Analysis

on:
  push:
    branches: [ main, develop ]
    paths:
    - 'source/**'
    - 'Scripts/**'
  pull_request:
    branches: [ main ]
    paths:
    - 'source/**'
    - 'Scripts/**'
  schedule:
    # Run weekly security scan
    - cron: '0 2 * * 1'

jobs:
  security-analysis:
    runs-on: windows-latest
    
    permissions:
      contents: read
      security-events: write
      pull-requests: write
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Setup PowerShell
      uses: microsoft/setup-msbuild@v1.3.1
    
    - name: Install Prerequisites
      shell: pwsh
      run: |
        Write-Host "Installing required PowerShell modules..."
        Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
        Install-Module -Name Pester -Force -Scope CurrentUser -SkipPublisherCheck
        Write-Host "Modules installed successfully"
    
    - name: Create Reports Directory
      shell: pwsh
      run: |
        New-Item -Path "./reports" -ItemType Directory -Force
    
    - name: Run Security Analysis
      shell: pwsh
      run: |
        ./Scripts/Run-WorkingAnalysis.ps1 -SourcePath "./source" -OutputPath "./reports"
      continue-on-error: true
    
    - name: Run Enhanced PSScriptAnalyzer
      shell: pwsh
      run: |
        ./Scripts/Invoke-EnhancedPSScriptAnalyzer.ps1 -SourcePath "./source" -OutputPath "./reports" -GenerateReport
      continue-on-error: true
    
    - name: Run Pester Security Tests
      shell: pwsh
      run: |
        $exitCode = ./Scripts/Invoke-EnhancedPesterTests.ps1 -SourcePath "./source" -OutputPath "./reports" -TestResultsFile "pester-results.xml"
        Write-Host "Pester exit code: $exitCode"
      continue-on-error: true
    
    - name: Upload Test Results
      uses: dorny/test-reporter@v1
      if: always()
      with:
        name: Pester Security Tests
        path: './reports/pester-results.xml'
        reporter: java-junit
    
    - name: Upload Security Reports
      uses: actions/upload-artifact@v4
      if: always()
      with:
        name: security-analysis-reports
        path: './reports/'
        retention-days: 30
    
    - name: Comment PR with Results
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v7
      with:
        script: |
          const fs = require('fs');
          const path = './reports/Executive-Summary.md';
          
          if (fs.existsSync(path)) {
            const summary = fs.readFileSync(path, 'utf8');
            const comment = `## Security Analysis Results\n\n${summary}`;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });
          }
    
    - name: Security Gate Check
      shell: pwsh
      run: |
        $summaryPath = "./reports/Executive-Summary.md"
        if (Test-Path $summaryPath) {
          $content = Get-Content $summaryPath -Raw
          if ($content -match "Critical.*[1-9]|High.*[1-9]") {
            Write-Host "##[error]Critical or High severity security issues found!"
            Write-Host "Please review the security analysis results before merging."
            exit 1
          } else {
            Write-Host "##[section]Security analysis passed - no critical issues found"
          }
        }

  dependency-check:
    runs-on: windows-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Run Dependency Check
      shell: pwsh
      run: |
        # Check for known vulnerable PowerShell modules
        $modules = Get-ChildItem -Path "./source" -Recurse -Include "*.psd1"
        foreach ($module in $modules) {
          Write-Host "Checking dependencies in $($module.Name)"
          # Add dependency vulnerability checks here
        }
```

### Security-Focused Workflow

#### .github/workflows/security-gate.yml
```yaml
name: Security Gate

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  security-gate:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Security Analysis
      shell: pwsh
      run: |
        # Run comprehensive security check
        ./Scripts/Start-SecurityAnalysis.ps1 -SourcePath "./source" -OutputPath "./security-reports" -FailOnFindings
    
    - name: Block PR on Security Issues
      shell: pwsh
      run: |
        $criticalIssues = Get-Content "./security-reports/Executive-Summary.md" | Select-String "Critical.*[1-9]|High.*[1-9]"
        if ($criticalIssues) {
          Write-Host "##[error]Security issues must be resolved before merging"
          exit 1
        }
```

## 🔧 Jenkins Integration

### Jenkinsfile Configuration

#### Declarative Pipeline
```groovy
pipeline {
    agent {
        label 'windows'
    }
    
    parameters {
        choice(
            name: 'SECURITY_LEVEL',
            choices: ['Basic', 'Enhanced', 'Comprehensive'],
            description: 'Level of security analysis to perform'
        )
        booleanParam(
            name: 'FAIL_ON_SECURITY_ISSUES',
            defaultValue: true,
            description: 'Fail build if security issues are found'
        )
    }
    
    environment {
        REPORTS_DIR = "${WORKSPACE}/SecurityReports"
        SOURCE_DIR = "${WORKSPACE}/source"
    }
    
    stages {
        stage('Preparation') {
            steps {
                script {
                    // Clean and create reports directory
                    powershell '''
                        if (Test-Path $env:REPORTS_DIR) { Remove-Item $env:REPORTS_DIR -Recurse -Force }
                        New-Item -Path $env:REPORTS_DIR -ItemType Directory -Force
                        
                        # Install required modules
                        Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
                        Install-Module -Name Pester -Force -Scope CurrentUser -SkipPublisherCheck
                    '''
                }
            }
        }
        
        stage('Security Analysis') {
            parallel {
                stage('Basic Analysis') {
                    when { 
                        anyOf { 
                            params.SECURITY_LEVEL == 'Basic'
                            params.SECURITY_LEVEL == 'Enhanced'
                            params.SECURITY_LEVEL == 'Comprehensive'
                        }
                    }
                    steps {
                        powershell '''
                            ./Scripts/Run-WorkingAnalysis.ps1 -SourcePath $env:SOURCE_DIR -OutputPath $env:REPORTS_DIR
                        '''
                    }
                }
                
                stage('Enhanced PSScriptAnalyzer') {
                    when { 
                        anyOf { 
                            params.SECURITY_LEVEL == 'Enhanced'
                            params.SECURITY_LEVEL == 'Comprehensive'
                        }
                    }
                    steps {
                        powershell '''
                            ./Scripts/Invoke-EnhancedPSScriptAnalyzer.ps1 -SourcePath $env:SOURCE_DIR -OutputPath $env:REPORTS_DIR -GenerateReport
                        '''
                    }
                }
                
                stage('Pester Security Tests') {
                    when { 
                        params.SECURITY_LEVEL == 'Comprehensive'
                    }
                    steps {
                        powershell '''
                            ./Scripts/Invoke-EnhancedPesterTests.ps1 -SourcePath $env:SOURCE_DIR -OutputPath $env:REPORTS_DIR -TestResultsFile "PesterResults.xml"
                        '''
                    }
                    post {
                        always {
                            publishTestResults testResultsPattern: "${REPORTS_DIR}/PesterResults.xml"
                        }
                    }
                }
            }
        }
        
        stage('Security Gate') {
            steps {
                script {
                    def securityCheck = powershell(
                        returnStdout: true,
                        script: '''
                            $summaryPath = "$env:REPORTS_DIR/Executive-Summary.md"
                            if (Test-Path $summaryPath) {
                                $content = Get-Content $summaryPath -Raw
                                if ($content -match "Critical.*[1-9]|High.*[1-9]") {
                                    Write-Output "SECURITY_ISSUES_FOUND"
                                } else {
                                    Write-Output "SECURITY_OK"
                                }
                            } else {
                                Write-Output "NO_SUMMARY"
                            }
                        '''
                    ).trim()
                    
                    if (securityCheck == "SECURITY_ISSUES_FOUND" && params.FAIL_ON_SECURITY_ISSUES) {
                        error("Critical or High severity security issues found. Build failed.")
                    } else if (securityCheck == "SECURITY_ISSUES_FOUND") {
                        unstable("Security issues found but build continues as requested.")
                    }
                }
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: "${REPORTS_DIR}/**/*", allowEmptyArchive: true
            
            // Email notification for security issues
            script {
                if (currentBuild.currentResult == 'FAILURE' || currentBuild.currentResult == 'UNSTABLE') {
                    emailext (
                        subject: "Security Analysis Alert - ${env.JOB_NAME} - Build ${env.BUILD_NUMBER}",
                        body: """
                        Security analysis has detected issues in build ${env.BUILD_NUMBER}.
                        
                        Please review the security reports in the build artifacts.
                        
                        Build URL: ${env.BUILD_URL}
                        """,
                        to: "security-team@company.com",
                        attachmentsPattern: "${REPORTS_DIR}/Executive-Summary.md"
                    )
                }
            }
        }
        success {
            echo 'Security analysis completed successfully!'
        }
        failure {
            echo 'Security analysis failed - review required!'
        }
    }
}
```

## ⚙️ Configuration Best Practices

### Environment Variables

#### Required Environment Variables
```bash
# CI/CD Environment Variables
SECURITY_SOURCE_PATH=./source              # Path to PowerShell source code
SECURITY_REPORTS_PATH=./reports           # Output directory for reports
SECURITY_MINIMUM_SEVERITY=Medium          # Minimum severity level to report
SECURITY_FAIL_ON_CRITICAL=true           # Fail build on critical issues
SECURITY_NOTIFICATION_EMAIL=security@company.com  # Email for notifications
```

#### PowerShell Profile Configuration
```powershell
# CI/CD PowerShell Profile Setup
$PSScriptAnalyzerSettings = @{
    Rules = @{
        PSAvoidUsingInvokeExpression = @{
            Severity = 'Error'
        }
        PSAvoidUsingPlainTextForPassword = @{
            Severity = 'Error'
        }
    }
}
```

### Quality Gates Configuration

#### Severity-Based Quality Gates
```yaml
# Quality gate thresholds
quality_gates:
  critical_issues: 0      # Block deployment
  high_issues: 0          # Block deployment  
  medium_issues: 10       # Warning only
  low_issues: 50          # Information only
  
  # File-based thresholds
  max_issues_per_file: 5
  max_total_issues: 100
```

### Notification Configuration

#### Slack Integration
```yaml
- name: Notify Slack on Security Issues
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    channel: '#security-alerts'
    message: |
      🚨 Security Analysis Failed
      
      Repository: ${{ github.repository }}
      Branch: ${{ github.ref }}
      Commit: ${{ github.sha }}
      
      Please review security reports in build artifacts.
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

#### Microsoft Teams Integration
```yaml
- name: Notify Teams on Security Issues
  if: failure()
  uses: skitionek/notify-microsoft-teams@master
  with:
    webhook_url: ${{ secrets.TEAMS_WEBHOOK }}
    title: "Security Analysis Alert"
    message: "Security issues detected in ${{ github.repository }}"
    theme_color: "FF0000"
```

## 🔐 Security Considerations

### Secrets Management

#### Secure Credential Handling
```yaml
# Example: Secure API key usage
- name: Security Analysis with API Integration
  env:
    SECURITY_API_KEY: ${{ secrets.SECURITY_API_KEY }}
  shell: pwsh
  run: |
    # Use secure string for API key
    $secureApiKey = ConvertTo-SecureString $env:SECURITY_API_KEY -AsPlainText -Force
    ./Scripts/Start-SecurityAnalysis.ps1 -ApiKey $secureApiKey
```

### Access Control

#### Required Permissions
- **Read**: Source code repository access
- **Write**: Artifact publication, test results
- **Execute**: PowerShell script execution
- **Notify**: Team notification permissions

#### Branch Protection Rules
```yaml
# GitHub branch protection
protection_rules:
  required_status_checks:
    - "PowerShell Security Analysis"
    - "Pester Security Tests"
  enforce_admins: true
  required_pull_request_reviews:
    required_approving_review_count: 2
    dismiss_stale_reviews: true
```

### Compliance Integration

#### SOX Compliance Example
```powershell
# SOX compliance reporting
function New-SOXComplianceReport {
    param($SecurityFindings, $OutputPath)
    
    $complianceReport = @{
        AuditDate = Get-Date
        SecurityFindings = $SecurityFindings
        ComplianceStatus = if($SecurityFindings.Count -eq 0) { "COMPLIANT" } else { "NON_COMPLIANT" }
        ReviewedBy = $env:BUILD_REQUESTEDFOR
        ApprovedBy = $null
    }
    
    $complianceReport | ConvertTo-Json | Out-File "$OutputPath/SOX-Compliance-Report.json"
}
```

## 🔧 Troubleshooting

### Common Issues

#### PowerShell Execution Policy
```yaml
# Solution: Set execution policy in pipeline
- name: Set PowerShell Execution Policy
  shell: pwsh
  run: |
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

#### Module Installation Issues
```yaml
# Solution: Use specific module versions
- name: Install Specific Module Versions
  shell: pwsh
  run: |
    Install-Module -Name PSScriptAnalyzer -RequiredVersion 1.21.0 -Force -Scope CurrentUser
    Install-Module -Name Pester -RequiredVersion 5.4.0 -Force -Scope CurrentUser -SkipPublisherCheck
```

#### Path Resolution Problems
```yaml
# Solution: Use absolute paths
- name: Use Absolute Paths
  shell: pwsh
  run: |
    $sourcePath = Resolve-Path "./source"
    $reportPath = Resolve-Path "./reports"
    ./Scripts/Run-WorkingAnalysis.ps1 -SourcePath $sourcePath -OutputPath $reportPath
```

### Performance Optimization

#### Parallel Execution
```yaml
# Run multiple security tools in parallel
- name: Parallel Security Analysis
  shell: pwsh
  run: |
    $jobs = @()
    $jobs += Start-Job { ./Scripts/Run-WorkingAnalysis.ps1 -SourcePath $args[0] -OutputPath $args[1] } -ArgumentList $sourcePath, $reportPath
    $jobs += Start-Job { ./Scripts/Invoke-EnhancedPSScriptAnalyzer.ps1 -SourcePath $args[0] -OutputPath $args[1] } -ArgumentList $sourcePath, $reportPath
    
    $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
```

#### Incremental Analysis
```powershell
# Analyze only changed files
function Get-ChangedPowerShellFiles {
    param($BaseBranch = "origin/main")
    
    $changedFiles = git diff --name-only $BaseBranch..HEAD
    return $changedFiles | Where-Object { $_ -match '\.(ps1|psm1|psd1)$' }
}
```

### Debugging Pipeline Issues

#### Verbose Logging
```yaml
- name: Enable Verbose Security Analysis
  shell: pwsh
  run: |
    $VerbosePreference = "Continue"
    ./Scripts/Run-WorkingAnalysis.ps1 -SourcePath "./source" -OutputPath "./reports" -Verbose
```

#### Artifact Collection
```yaml
- name: Collect Debug Information
  if: failure()
  shell: pwsh
  run: |
    # Collect environment information
    $env:PSVersionTable | Out-File "./debug-info.txt"
    Get-Module -ListAvailable | Out-File "./debug-info.txt" -Append
    
- name: Upload Debug Artifacts
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: debug-information
    path: ./debug-info.txt
```

## 📚 Additional Resources

### Documentation Links
- [Azure DevOps PowerShell Task](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/utility/powershell)
- [GitHub Actions PowerShell](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstepsshell)
- [Jenkins PowerShell Plugin](https://plugins.jenkins.io/powershell/)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer/tree/master/Rules)
- [Pester Documentation](https://pester.dev/)

### Example Repositories
- [PowerShell CI/CD Examples](https://github.com/PowerShell/PowerShell/tree/master/.vsts-ci)
- [Security Pipeline Templates](https://github.com/microsoft/azure-pipelines-yaml)

---

**Last Updated**: October 17, 2025  
**Version**: 1.0  
**Compatibility**: Azure DevOps, GitHub Actions, Jenkins  
**PowerShell Version**: 5.1+