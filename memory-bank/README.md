# Memory Bank: Project Documentation

This directory contains the Memory Bank documentation for the PowerShell Security Code Review System.

## Purpose

The Memory Bank serves as the permanent knowledge base for the project, maintaining:
- Project scope and objectives
- System architecture and design decisions
- Current work context and progress
- Technical constraints and patterns
- Product vision and user experience goals

## Files

### projectbrief.md
**Foundation document** defining the project:
- Project overview and objectives
- Scope (in-scope and out-of-scope items)
- Success criteria
- Key stakeholders and their needs
- Timeline and constraints

**Key Content**:
- Primary objective: Security analysis of PowerShell modules
- Scope: Static code analysis, automated scanning, comprehensive reporting
- Success criteria: All modules scanned, reports generated, documentation complete

### productContext.md
**Product vision** explaining why the project exists:
- Why this project is needed
- Problems it solves
- How it should work (input, process, output)
- User experience goals for different stakeholders
- Key principles guiding development

**User Perspectives**:
- Security Teams: Risk visibility, prioritized findings, CVSS scoring
- Development Teams: Remediation guidance, context understanding
- Management: Executive summaries, compliance documentation

### techContext.md
**Technical foundation** documenting the technology stack:
- Core technologies (PowerShell AST, PSScriptAnalyzer, Pester)
- Development environment
- PowerShell-specific considerations
- Analysis approach and dependencies
- Security detection categories

**Key Considerations**:
- Credential handling in PowerShell
- High entropy strings are normal
- Dynamic code execution context
- Static analysis limitations

### systemPatterns.md
**Architecture and design** defining system structure:
- Architecture overview
- Key components (Rules Engine, Analysis Scripts, Report Generation)
- Design patterns (Rule-Based Detection, AST Visitor, Plugin Architecture)
- Critical implementation paths
- Component relationships
- Technical decisions and trade-offs

**Design Decisions**:
- Static analysis only (no code execution)
- PowerShell AST + PSScriptAnalyzer
- Markdown reports for accessibility
- Context-aware severity assessment

### activeContext.md
**Current state** tracking ongoing work:
- Current work focus
- Recent changes
- Next steps
- Active decisions and considerations
- Important patterns and learnings
- Current task status

**Updates**: Modified frequently as work progresses

### progress.md
**Project tracker** documenting completion status:
- Completed work with details
- In-progress tasks
- Pending work
- Project statistics
- Known issues
- Risk assessment
- Evolution of decisions

**Milestones Tracked**:
- Prompt completions (1-6)
- Files created
- Analysis results
- Key achievements

## Memory Bank Workflow

```
Project Start
     ↓
Create projectbrief.md (defines scope)
     ↓
Build context files (product, tech, system)
     ↓
Track progress (activeContext, progress)
     ↓
Update continuously as work progresses
     ↓
Final documentation
```

## Using the Memory Bank

### For Project Continuity
After memory resets or team changes:
1. Read `projectbrief.md` first for project scope
2. Review `progress.md` to understand current status
3. Check `activeContext.md` for recent work
4. Reference technical files as needed

### For Decision Making
When making decisions:
1. Check `systemPatterns.md` for existing patterns
2. Review `techContext.md` for constraints
3. Document new decisions in appropriate files
4. Update `activeContext.md` with rationale

### For Status Updates
When reporting progress:
1. Update `progress.md` with completions
2. Modify `activeContext.md` with current focus
3. Document achievements and issues
4. Track statistics and metrics

## File Relationships

```
projectbrief.md
    ├── Defines scope for all other files
    ├── Referenced by: productContext.md
    └── Referenced by: techContext.md

productContext.md
    └── Informs: systemPatterns.md (design decisions)

techContext.md
    └── Informs: systemPatterns.md (technical constraints)

systemPatterns.md
    └── Guides: Implementation decisions

activeContext.md
    ├── Tracks: Current work
    └── Updates: progress.md

progress.md
    └── Summarizes: All project status
```

## Maintenance

### Regular Updates
- **activeContext.md**: After each significant task
- **progress.md**: When milestones complete
- **Technical files**: When architecture changes
- **All files**: During formal "update memory bank" reviews

### Update Triggers
1. Completing prompts or major tasks
2. Making architectural decisions
3. Discovering new patterns or constraints
4. User requesting "update memory bank"
5. Before project handoff

## Memory Bank Principles

### Comprehensive
Document everything needed to understand and continue the project

### Current
Keep information up-to-date, especially activeContext.md and progress.md

### Clear
Write for someone who knows nothing about the project

### Contextual
Explain not just what, but why decisions were made

### Structured
Follow consistent format for easy navigation

## Project Statistics (Current)

From `progress.md`:
- **Prompts Completed**: 5 of 6
- **Files Created**: 19 total
- **Modules Analyzed**: 3
- **Total Findings**: 6,529
- **Reports Generated**: 4

## Key Achievements

1. ✅ Established complete Memory Bank documentation
2. ✅ Created 55 comprehensive security detection rules
3. ✅ Built automated scanning infrastructure
4. ✅ Analyzed 157 PowerShell files across 3 modules
5. ✅ Generated actionable security reports with CVSS scores
6. ✅ Provided context-aware severity assessment
7. ✅ Documented PowerShell-specific security considerations

## Next Steps

From `progress.md`:
- Complete Prompt 5: Create README files (In Progress)
- Execute Prompt 6: Optional tasks
- Final Memory Bank update

## For More Information

- Project scope: See `projectbrief.md`
- Why we're doing this: See `productContext.md`
- How it works: See `techContext.md` and `systemPatterns.md`
- Current status: See `progress.md`
- Recent work: See `activeContext.md`
