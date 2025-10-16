# Technical Context: Development Environment and Technologies

## Technology Stack

### Core Technologies
- **PowerShell 5.1+:** Primary implementation language
  - Reason: Native DSC support, Parser API, cross-module compatibility
  - Version: 5.1 minimum (Windows PowerShell), 7.x compatible (PowerShell Core)

- **PowerShell Parser API:** AST generation and analysis
  - Namespace: System.Management.Automation.Language
  - Key Classes: Parser, Ast, ScriptBlockAst, CommandAst

- **Pester (Testing Framework):** Unit and integration testing
  - Version: 5.x
  - Purpose: Validate detection rules, test report generation

### Supporting Technologies
- **Markdown:** Documentation and human-readable reports
- **JSON:** Machine-readable output for automation
- **Git:** Version control and collaboration
- **GitHub:** Repository hosting and CI/CD

## Development Environment

### System Requirements
- **Operating System:** Windows 10/11 or Windows Server 2016+
- **PowerShell:** Version 5.1 or higher
- **Execution Policy:** RemoteSigned or Unrestricted (for testing)
- **Permissions:** Standard user (no elevation required for analysis)

### Repository Structure
\\\
d:\Git\CodeVerification\
├── source/                          # Modules to be analyzed (input)
│   ├── AADConnectDsc/
│   │   └── 0.4.1/
│   │       ├── AADConnectDsc.psd1
│   │       ├── AADConnectDsc.psm1
│   │       └── [other module files]
│   └── xPSDesiredStateConfiguration/
│       └── 9.2.1/
│           ├── xPSDesiredStateConfiguration.psd1
│           └── [other module files]
│
├── memory-bank/                     # Project documentation (persistent state)
│   ├── projectbrief.md             # Foundation document
│   ├── productContext.md           # Purpose and goals
│   ├── systemPatterns.md           # Architecture and design
│   ├── techContext.md              # This file
│   ├── activeContext.md            # Current work state
│   └── progress.md                 # Status tracking
│
├── security-reports/                # Analysis output (to be created)
│   ├── AADConnectDsc/
│   │   ├── security-report.md
│   │   ├── security-report.json
│   │   └── findings-detail.md
│   └── xPSDesiredStateConfiguration/
│       └── [similar structure]
│
├── scripts/                         # Analysis tooling (to be created)
│   ├── Invoke-SecurityScan.ps1     # Main entry point
│   ├── modules/                     # Analysis modules
│   │   ├── Scanner/
│   │   ├── Analyzer/
│   │   ├── Detector/
│   │   └── Reporter/
│   └── tests/                       # Pester tests
│
└── .github/                         # GitHub configuration
    └── chatmodes/                   # Custom GitHub Copilot modes
\\\

## Technical Constraints

### PowerShell Limitations
1. **No Native Sandboxing:** Cannot safely execute untrusted code
   - Mitigation: Static analysis only, no code execution

2. **Parser API Limitations:** Some obfuscation can bypass AST parsing
   - Mitigation: Multi-layer detection (lexical + syntactic + heuristic)

3. **Performance:** Interpreted language, slower than compiled alternatives
   - Mitigation: Parallel processing, efficient algorithms

4. **Memory:** Large files can consume significant memory during AST parsing
   - Mitigation: Streaming analysis for large files, chunked processing

### Analysis Limitations
1. **Static Analysis Blind Spots:**
   - Cannot detect runtime-only behaviors
   - Dynamically generated code may be missed
   - Polymorphic malware detection limited

2. **False Positive/Negative Balance:**
   - Strict rules = higher false positive rate
   - Lenient rules = higher false negative rate
   - Approach: Configurable sensitivity with severity classification

3. **Module Dependencies:**
   - Cannot analyze external module calls deeply
   - Limited to module boundary analysis

## Dependencies

### Built-in PowerShell Modules (No Installation Required)
- **Microsoft.PowerShell.Management:** File system operations
- **Microsoft.PowerShell.Utility:** Data parsing, formatting
- **Microsoft.PowerShell.Core:** Core cmdlets

### Optional Dependencies (Future Enhancement)
- **PSScriptAnalyzer:** Code quality and style validation
- **PowerShellGet:** Module metadata retrieval
- **Pester:** Automated testing framework

### Module Manifest Dependencies
\\\powershell
# Planned: CodeVerification.psd1
@{
    ModuleVersion = '1.0.0'
    RootModule = 'CodeVerification.psm1'
    PowerShellVersion = '5.1'
    RequiredModules = @()  # None - self-contained
    FunctionsToExport = @(
        'Invoke-SecurityScan',
        'Get-SecurityReport',
        'New-DetectionRule'
    )
}
\\\

## Tool Usage Patterns

### PowerShell Parser API
\\\powershell
# Parse PowerShell file into AST
\ = @()
\ = @()
\ = [System.Management.Automation.Language.Parser]::ParseFile(
    \,
    [ref]\,
    [ref]\
)

# Traverse AST
\.FindAll({
    param(\)
    \ -is [System.Management.Automation.Language.CommandAst]
}, \True)
\\\

### Detection Pattern Example
\\\powershell
# Detect Invoke-Expression usage (code injection risk)
\ = \.FindAll({
    param(\)
    \ -is [System.Management.Automation.Language.CommandAst] -and
    \.GetCommandName() -eq 'Invoke-Expression'
}, \True)

foreach (\ in \) {
    \ = @{
        Severity = 'Medium'
        Rule = 'PS001'
        Description = 'Invoke-Expression detected (potential code injection)'
        File = \
        Line = \.Extent.StartLineNumber
        Context = \.Extent.Text
    }
    \ += \
}
\\\

### Entropy Calculation (Obfuscation Detection)
\\\powershell
function Get-StringEntropy {
    param([string]\)

    \ = @{}
    foreach (\ in \.ToCharArray()) {
        \[\] = (\[\] ?? 0) + 1
    }

    \ = 0
    foreach (\ in \.Values) {
        \ = \ / \.Length
        \ -= \ * [Math]::Log(\, 2)
    }

    return \
}

# High entropy suggests obfuscation (random-looking strings)
# Threshold: >4.5 for base64, >5.5 for compressed/encrypted
\\\

## Development Workflow

### Analysis Execution Flow
\\\
1. Developer places modules in source/
2. Execute: .\scripts\Invoke-SecurityScan.ps1
3. Script discovers all PowerShell files
4. For each file:
   a. Parse into AST
   b. Apply all detection rules
   c. Collect findings
5. Generate reports in security-reports/
6. Display summary to console
7. Exit code indicates risk level (0=clean, 1+=findings)
\\\

### Testing Workflow
\\\powershell
# Run all tests
Invoke-Pester -Path .\scripts\tests\

# Run specific test suite
Invoke-Pester -Path .\scripts\tests\Detector.Tests.ps1

# Generate coverage report
Invoke-Pester -Path .\scripts\tests\ -CodeCoverage .\scripts\modules\**\*.ps1
\\\

### Report Generation
\\\powershell
# Generate all report formats
\ = Get-SecurityFinding -Path source/AADConnectDsc/
Export-SecurityReport -Findings \ -Format Markdown -OutputPath security-reports/
Export-SecurityReport -Findings \ -Format JSON -OutputPath security-reports/
Export-SecurityReport -Findings \ -Format HTML -OutputPath security-reports/
\\\

## Configuration Management

### Detection Rule Configuration
\\\powershell
# rules.psd1 - Detection rule definitions
@{
    Rules = @(
        @{
            Id = 'PS001'
            Name = 'Invoke-Expression Usage'
            Severity = 'Medium'
            Description = 'Detects use of Invoke-Expression which can execute arbitrary code'
            Pattern = 'CommandName -eq ''Invoke-Expression'''
            Remediation = 'Replace Invoke-Expression with safer alternatives like & or dot-sourcing'
        },
        @{
            Id = 'PS002'
            Name = 'Base64 Encoded Command'
            Severity = 'High'
            Description = 'Detects base64-encoded commands often used for obfuscation'
            Pattern = '(-enc|-encodedcommand)\s+[A-Za-z0-9+/=]{20,}'
            Remediation = 'Decode and review the command contents'
        }
        # ... additional rules
    )
    Thresholds = @{
        EntropyThreshold = 4.5
        MaxFindingsBeforeCritical = 10
    }
}
\\\

### Scan Configuration
\\\powershell
# scan-config.psd1
@{
    IncludePatterns = @('*.ps1', '*.psm1', '*.psd1')
    ExcludePatterns = @('*.Tests.ps1', 'Examples/*')
    ParallelProcessing = \True
    MaxThreads = 4
    Verbose = \False
    StopOnCritical = \False
}
\\\

## Environment Variables

### Execution Context
- **PSModulePath:** Includes source/ for module discovery
- **ExecutionPolicy:** Set appropriately for script execution
- **PSVersionTable:** Used to detect PowerShell version compatibility

### Custom Variables (Proposed)
- **CODEVRF_REPORT_PATH:** Override default report output location
- **CODEVRF_VERBOSE:** Enable detailed logging
- **CODEVRF_RULE_PATH:** Custom detection rule directory

## Security Tooling Integration

### Integration Points
1. **CI/CD Pipelines:** Exit codes and JSON output for automation
   \\\yaml
   # Example: GitHub Actions
   - name: Security Scan
     run: .\scripts\Invoke-SecurityScan.ps1
     continue-on-error: false
   - name: Upload Reports
     uses: actions/upload-artifact@v3
     with:
       name: security-reports
       path: security-reports/
   \\\

2. **SIEM Integration:** JSON output can be ingested by log management
3. **Compliance Tools:** Reports map to compliance frameworks

## Performance Metrics

### Benchmarks (Target)
- **Small Module (<50 files):** <10 seconds
- **Medium Module (50-200 files):** <30 seconds
- **Large Module (>200 files):** <2 minutes
- **Memory Usage:** <500MB per analysis session

### Optimization Techniques
- Parallel file processing using runspaces
- AST caching for repeated analysis
- Incremental scanning (only changed files)
- Rule optimization (early exit conditions)

## Monitoring and Logging

### Logging Strategy
\\\powershell
# Structured logging with severity levels
Write-SecurityLog -Level INFO -Message 'Starting security scan'
Write-SecurityLog -Level WARNING -Message 'Parsing error in file.ps1'
Write-SecurityLog -Level ERROR -Message 'Critical finding detected'

# Log output locations
# - Console (real-time feedback)
# - security-reports/scan.log (persistent record)
# - Event Log (future: Windows Event Viewer integration)
\\\

### Metrics Collection
- Files scanned count
- Findings by severity
- Scan duration
- Parser errors encountered
- Rules executed
- False positive rate (when available)

## Future Technical Enhancements

### Planned Capabilities
1. **PowerShell 7 Core Support:** Cross-platform analysis
2. **Remote Analysis:** Scan modules directly from PowerShell Gallery
3. **Differential Analysis:** Compare scans over time, detect changes
4. **Machine Learning:** Pattern recognition for unknown threats
5. **Plugin Architecture:** Custom detection rule modules
6. **REST API:** Web service for centralized scanning

### Research Areas
- Advanced obfuscation detection techniques
- Behavioral analysis through symbolic execution
- Integration with threat intelligence feeds
- Automated remediation suggestions with code fixes
