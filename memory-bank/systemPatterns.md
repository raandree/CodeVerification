# System Patterns: PowerShell Module Security Verification

## System Architecture

### Component Structure

```
CodeVerification/
├── source/                          # Input: PowerShell modules to scan
│   ├── AADConnectDsc/
│   └── xPSDesiredStateConfiguration/
├── detection-rules/                 # Detection rule definitions
│   └── [Security rules files]
├── scripts/                         # Scanning and testing scripts
│   ├── tests/                      # Pester test files
│   └── [Scanning scripts]
├── Report/                          # Output: Security reports
│   ├── ExecutiveSummary.md         # High-level overview
│   └── [Module-specific reports]
├── memory-bank/                     # Project documentation
└── .work/                          # Working files and prompts
```

### Data Flow

```
[PowerShell Modules]
      ↓
[Detection Rules] → [Scanner Scripts] → [PSScriptAnalyzer]
      ↓                    ↓
[Raw Findings]      [Analysis Results]
      ↓                    ↓
[Aggregation & Deduplication]
      ↓
[Severity Classification]
      ↓
[Report Generation]
      ↓
[Executive Summary] + [Detailed Reports]
```

## Key Technical Decisions

### Decision 1: Detection Rule Format
**Context**: Need structured, machine-readable security rules

**Decision**: Use PowerShell object format with specific properties
```powershell
@{
    Id = 'PS001'
    Name = 'Rule Name'
    Severity = 'Critical|High|Medium|Low'
    Category = 'Category'
    Description = 'Description'
    ASTPattern = 'AST Type to match'
    CommandName = 'Command to detect'
    Remediation = 'Fix guidance'
    CVSS = 0.0-10.0
}
```

**Rationale**: 
- Structured format enables automation
- CVSS scoring provides industry-standard severity
- Remediation field ensures actionable output
- Category enables grouping and filtering

### Decision 2: Multi-Tool Approach
**Context**: Single tool may miss issues or generate false positives

**Decision**: Combine multiple detection methods:
1. Custom AST-based pattern matching
2. PSScriptAnalyzer built-in rules
3. Custom PSScriptAnalyzer rules from community
4. Pester-based validation tests

**Rationale**:
- Layered detection increases coverage
- Each tool has different strengths
- Cross-validation reduces false positives

### Decision 3: PowerShell-Aware Rule Tuning
**Context**: Standard security rules generate false positives in PowerShell

**Decision**: Context-aware rule interpretation:
- SecureString/PSCredential usage is acceptable
- Username/ID logging is permitted
- High entropy strings require additional analysis
- Focus on plaintext credential exposure

**Rationale**:
- Reduces false positives
- Reflects PowerShell best practices
- Improves signal-to-noise ratio

### Decision 4: Report Structure
**Context**: Different audiences need different views

**Decision**: Two-tier reporting:
- Executive Summary: High-level, all modules
- Detailed Reports: Per-module, with code snippets

**Rationale**:
- Executives need quick overview
- Developers need specific fixes
- Separates strategic from tactical information

## Design Patterns in Use

### Pattern 1: Abstract Syntax Tree (AST) Analysis
PowerShell's AST enables deep code analysis without execution:
```powershell
$ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$null)
$commandAsts = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)
```

**Usage**: Detect dangerous commands, patterns, and structures

### Pattern 2: Rule-Based Detection Engine
Each rule is evaluated independently:
```powershell
foreach ($rule in $rules) {
    $findings += Test-Rule -Rule $rule -AST $ast -Content $content
}
```

**Usage**: Extensible, maintainable security checks

### Pattern 3: Severity Aggregation
Findings are aggregated and deduplicated:
```powershell
$findings | Group-Object File, Line, Rule | 
    Select-Object -First 1 -ExpandProperty Group
```

**Usage**: Prevent duplicate reporting, clarify scope

### Pattern 4: Report Template System
Consistent report formatting:
```markdown
Rule: <Rule>
Category: <Category>
File: <Full File Path>
- Line: <Line numbers>
  Code: <Code snippet>
```

**Usage**: Standardized output for all findings

## Component Relationships

### Scanner → Rules
- Scanner loads rule definitions
- Applies rules to parsed AST
- Collects matching findings

### Scanner → PSScriptAnalyzer
- Scanner invokes PSScriptAnalyzer
- Filters results based on severity
- Merges with custom rule findings

### Findings → Reports
- Findings aggregated by module
- Sorted by severity (CVSS)
- Formatted using templates

### Tests → Validation
- Pester tests validate scanner functionality
- Ensure rules detect known patterns
- Regression testing for rule changes

## Critical Implementation Paths

### Path 1: Module Scanning Flow
1. Enumerate PowerShell files in module
2. Parse each file into AST
3. Apply all detection rules
4. Run PSScriptAnalyzer
5. Aggregate findings
6. Generate report

### Path 2: Rule Evaluation Flow
1. Load rule definition
2. Match AST pattern
3. Extract context (file, line, code)
4. Apply severity rating
5. Generate remediation guidance
6. Return structured finding

### Path 3: Report Generation Flow
1. Group findings by module
2. Calculate statistics (total, by severity)
3. Generate executive summary
4. Generate per-module details
5. Include code snippets
6. Output markdown files

## Integration Points

### PSScriptAnalyzer Integration
- Installed via PowerShell Gallery
- Invoked with custom settings
- Results filtered and formatted
- Community rules incorporated

### Pester Integration
- Test framework for validation
- Rule detection testing
- False positive verification
- Regression testing

### File System Integration
- Source: Read PowerShell modules
- Detection Rules: Load rule definitions
- Reports: Write markdown output
- Memory Bank: Documentation updates
