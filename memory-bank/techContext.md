# Technical Context: PowerShell Module Security Verification

## Technologies Used

### Core Technologies

#### PowerShell (5.1+ / 7.x)
- **Purpose**: Primary language for modules being analyzed and scanner scripts
- **Version**: Compatible with both Windows PowerShell 5.1 and PowerShell 7.x
- **Key Features Used**:
  - Abstract Syntax Tree (AST) parsing
  - Script analysis capabilities
  - Object pipeline
  - Module system

#### PSScriptAnalyzer
- **Purpose**: Industry-standard PowerShell static analysis tool
- **Source**: PowerShell Gallery
- **Usage**: 
  - Built-in security rules
  - Custom rule integration
  - Code quality analysis
- **Version**: Latest stable from PSGallery

#### Pester
- **Purpose**: Testing framework for PowerShell
- **Usage**:
  - Validate scanner functionality
  - Regression testing
  - Rule detection verification
- **Version**: 5.x or compatible

### File Formats

#### PowerShell Scripts
- `.ps1` - PowerShell script files
- `.psm1` - PowerShell module files
- `.psd1` - PowerShell manifest files
- `.mof` - Managed Object Format (DSC configuration)

#### Markdown
- `.md` - Documentation and reports
- GitHub-flavored markdown for reports
- Structured format for consistency

#### Detection Rules
- PowerShell hashtable/object format
- Machine-readable structured data
- Embedded documentation

## Development Setup

### Prerequisites

1. **PowerShell Environment**
   - Windows PowerShell 5.1+ OR PowerShell 7.x
   - Execution policy allowing script execution
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Required Modules**
   ```powershell
   Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
   Install-Module -Name Pester -Scope CurrentUser -MinimumVersion 5.0
   ```

3. **Development Tools**
   - Visual Studio Code (recommended)
   - PowerShell extension for VS Code
   - Git for version control

### Directory Structure

```
E:\CodeVerification\
├── source\                  # Input modules to analyze
├── detection-rules\         # Rule definitions
├── scripts\                 # Scanner and utility scripts
│   └── tests\              # Pester test files
├── Report\                  # Generated security reports
├── memory-bank\             # Project documentation
└── .work\                   # Working files
```

### Environment Configuration

#### VS Code Settings
Located in `.vscode/settings.json`:
- PowerShell integration
- Linting configurations
- Workspace-specific settings

#### PowerShell Module Path
Ensure source modules are not in `$env:PSModulePath` during analysis to prevent accidental loading.

## Technical Constraints

### Analysis Constraints

1. **Static Analysis Only**
   - No runtime execution of target modules
   - AST-based pattern matching
   - Cannot detect runtime-only issues

2. **PowerShell Language Limits**
   - Dynamic code generation may evade detection
   - Obfuscated code requires additional analysis
   - Reflection-based patterns may be missed

3. **File System Access**
   - Read-only access to source modules
   - Write access required for reports
   - No network access needed

### Performance Constraints

1. **Large File Handling**
   - Files >50KB may require chunked processing
   - AST parsing is memory-intensive
   - Consider batch processing for many modules

2. **Rule Complexity**
   - Complex regex patterns impact performance
   - AST traversal can be slow on large files
   - Balance thoroughness vs. speed

### Tool Limitations

1. **PSScriptAnalyzer**
   - Built-in rules may generate false positives
   - Custom rules require specific format
   - Rule suppression may hide issues

2. **AST Parsing**
   - Syntax errors prevent AST generation
   - Cannot analyze non-PowerShell files
   - Requires valid PowerShell syntax

## Dependencies

### Direct Dependencies

```powershell
@{
    'PSScriptAnalyzer' = @{
        MinimumVersion = '1.21.0'
        Repository = 'PSGallery'
        Purpose = 'Static code analysis'
    }
    'Pester' = @{
        MinimumVersion = '5.0.0'
        Repository = 'PSGallery'
        Purpose = 'Testing framework'
    }
}
```

### Target Module Dependencies

#### AADConnectDsc
- Depends on: DscResource.Common
- Version: 0.4.1
- Purpose: Azure AD Connect DSC resources

#### xPSDesiredStateConfiguration  
- Depends on: DscResource.Common, xPSDesiredStateConfiguration.Common
- Version: 9.2.1
- Purpose: Extended DSC resources

**Note**: Dependencies are analyzed along with the modules.

## Tool Usage Patterns

### PSScriptAnalyzer Invocation

```powershell
# Basic scan
Invoke-ScriptAnalyzer -Path $modulePath -Recurse

# With custom rules
Invoke-ScriptAnalyzer -Path $modulePath -CustomRulePath $rulesPath -Recurse

# With severity filtering
Invoke-ScriptAnalyzer -Path $modulePath -Severity Error,Warning -Recurse
```

### AST Parsing Pattern

```powershell
# Parse file
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $filePath, 
    [ref]$tokens, 
    [ref]$errors
)

# Find specific AST nodes
$commandAsts = $ast.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst]
}, $true)
```

### Pester Testing Pattern

```powershell
Describe "Detection Rule Tests" {
    BeforeAll {
        # Setup
        $rules = Import-DetectionRules
    }
    
    It "Should detect Invoke-Expression usage" {
        # Test logic
        $result = Test-Rule -Rule $rules['PS001'] -Content $testCode
        $result.Found | Should -Be $true
    }
}
```

### Report Generation Pattern

```powershell
# Template-based generation
$reportTemplate = Get-Content "template.md" -Raw
$findings | ForEach-Object {
    $reportTemplate -replace '{{Placeholder}}', $_.Value
}
```

## Security Considerations

### Tool Security
- Only analyze code, never execute it
- Sandbox environment recommended
- Limit file system access
- No network connectivity required

### Credential Handling
- Scanner does not process actual credentials
- Detects patterns, not values
- No credential storage needed

### Output Security
- Reports may contain sensitive code snippets
- Restrict report directory access
- Consider sanitizing output for sharing

## Integration Points

### Version Control (Git)
- Repository: CodeVerification
- Branch: v3
- Track detection rules changes
- Version control for reports

### CI/CD Potential
- Scanner can be automated
- Return codes indicate severity
- Report artifacts for review
- Suitable for pipeline integration

## Best Practices

### Code Analysis
1. Parse once, analyze multiple times
2. Cache AST results for performance
3. Parallelize file processing when possible
4. Handle parse errors gracefully

### Rule Development
1. Test rules against known patterns
2. Include both positive and negative tests
3. Document rule rationale
4. Version control rule changes

### Report Generation
1. Sanitize code snippets for readability
2. Include file paths relative to workspace
3. Sort findings by severity
4. Deduplicate identical issues

### Error Handling
1. Log all errors for debugging
2. Continue processing on non-critical errors
3. Fail fast on critical issues
4. Provide clear error messages
