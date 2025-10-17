# System Patterns: PowerShell Security Code Review System

## Architecture Overview

```
CodeVerification/
├── source/               # PowerShell modules to analyze
├── memory-bank/          # Project documentation and knowledge base
├── Rules/                # Security detection rules (to be created)
├── Scripts/              # Analysis scripts (to be created)
└── Report/               # Generated security reports (to be created)
```

## Key Components

### 1. Detection Rules Engine
**Purpose**: Define and store security detection patterns

**Structure**:
- Rule definitions with unique IDs
- Pattern matching criteria (AST patterns, command names, regex)
- Severity and CVSS scoring
- Remediation guidance

**Pattern**:
```powershell
@{
    Id = 'PS001'
    Name = 'Rule Name'
    Severity = 'Critical|High|Medium|Low'
    Category = 'CodeExecution|DataExfiltration|etc'
    Description = 'What this rule detects'
    ASTPattern = 'CommandAst|StringConstantExpressionAst|etc'
    CommandName = 'Specific-Command' # Optional
    Pattern = 'regex pattern' # Optional
    Remediation = 'How to fix'
    CVSS = 0.0-10.0
}
```

### 2. Analysis Scripts
**Purpose**: Scan PowerShell code using detection rules

**Components**:
- Rule loader: Imports detection rules
- AST parser: Analyzes PowerShell syntax trees
- PSScriptAnalyzer integration: Applies built-in rules
- Pattern matcher: Applies custom detection rules
- Finding aggregator: Collects and classifies issues

**Key Functions**:
- `Get-SecurityFindings`: Main analysis orchestrator
- `Test-ASTPattern`: Match AST patterns against rules
- `Invoke-CustomRules`: Apply custom security rules
- `Get-CVSSScore`: Calculate risk scores

### 3. Report Generation
**Purpose**: Generate actionable security reports

**Outputs**:
- **Executive Summary** (`Report/ExecutiveSummary.md`):
  - Overall security posture
  - High-level statistics
  - Critical findings summary
  - Risk distribution
  
- **Module Reports** (`Report/ModuleName_Report.md`):
  - Detailed findings per file
  - Line numbers and code excerpts
  - Remediation guidance
  - CVSS scores

**Report Structure**:
```
Rule: <Rule Name>
Category: <Category>
File: <Full Path>
- Line: <Line Numbers>
  Code: <Code Excerpt>
Description: <What was found>
Remediation: <How to fix>
CVSS Score: <Score>
```

## Design Patterns

### Pattern: Rule-Based Detection System
**When**: Analyzing code for known security patterns
**Why**: Extensible, maintainable, consistent
**How**: 
1. Define rules as data structures
2. Load rules dynamically
3. Apply rules to AST or text
4. Collect and classify findings

### Pattern: AST Visitor Pattern
**When**: Traversing PowerShell syntax trees
**Why**: Comprehensive analysis of code structure
**How**:
1. Parse file into AST
2. Recursively visit each node
3. Match node types against rules
4. Extract context (line numbers, surrounding code)

### Pattern: Plugin Architecture for Rules
**When**: Extending detection capabilities
**Why**: Community rules, custom organizational rules
**How**:
1. Define standard rule interface
2. Load rules from directory
3. Validate rule structure
4. Apply all loaded rules

## Critical Implementation Paths

### Path 1: Rule Definition
1. Research security patterns
2. Define rule structure
3. Document rules with examples
4. Organize by category
5. Assign severity and CVSS scores

### Path 2: Analysis Engine
1. Install dependencies (PSScriptAnalyzer, Pester)
2. Implement AST parsing
3. Implement rule matching
4. Integrate PSScriptAnalyzer
5. Aggregate findings
6. Calculate statistics

### Path 3: Report Generation
1. Collect all findings
2. Group by module and severity
3. Format according to specification
4. Generate executive summary
5. Generate detailed module reports
6. Output to Report/ directory

## Component Relationships

```
Detection Rules ──┐
                  ├──> Analysis Scripts ──> Findings
PSScriptAnalyzer ─┘                          │
                                             │
Source Files ───────────────────────────────┘
                                             │
                                             ▼
                                        Report Generator
                                             │
                                             ├──> Executive Summary
                                             └──> Module Reports
```

## Key Technical Decisions

### Decision 1: Static Analysis Only
**Why**: Safe execution, no environment impact, faster analysis
**Trade-off**: Cannot detect runtime-only behaviors
**Mitigation**: Comprehensive pattern library covers most threats

### Decision 2: PowerShell AST + PSScriptAnalyzer
**Why**: Native PowerShell parsing, industry-standard tool, extensible
**Trade-off**: PowerShell-specific, requires PowerShell environment
**Benefit**: Accurate syntax understanding, existing rule library

### Decision 3: Markdown Reports
**Why**: Human-readable, version-controllable, easy to generate
**Trade-off**: Not machine-parseable without additional processing
**Benefit**: Accessible to all stakeholders, no special tools needed

### Decision 4: Context-Aware Severity
**Why**: Reduce false positives, respect PowerShell idioms
**Trade-off**: More complex rule logic
**Benefit**: Actionable findings, better signal-to-noise ratio
