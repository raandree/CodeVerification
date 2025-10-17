<#
.SYNOPSIS
    Core detection engine for security findings

.DESCRIPTION
    Analyzes PowerShell files using AST parsing and pattern matching against security rules.
    This is the core detection logic used by the scanner.

.PARAMETER FilePath
    Path to the PowerShell file to analyze

.PARAMETER Rules
    Array of detection rules to apply

.EXAMPLE
    $rules = & ".\SecurityRules.ps1"
    $findings = Get-SecurityFindings -FilePath ".\script.ps1" -Rules $rules

.NOTES
    Uses PowerShell Abstract Syntax Tree (AST) for code analysis
    Author: Security Review System
    Date: October 17, 2025
#>

function Get-SecurityFindings {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [array]$Rules
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Warning "File not found: $FilePath"
        return @()
    }
    
    $findings = @()
    
    try {
        # Read file content
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        # Parse file into AST
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $FilePath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        
        if ($parseErrors) {
            Write-Warning "Parse errors in $FilePath : $($parseErrors.Count) errors"
            # Continue anyway - we can still analyze what parsed
        }
        
        # Apply each rule
        foreach ($rule in $Rules) {
            try {
                $ruleFindings = Test-SecurityRule -Rule $rule -AST $ast -Content $content -FilePath $FilePath
                if ($ruleFindings) {
                    $findings += $ruleFindings
                }
            }
            catch {
                Write-Verbose "Rule $($rule.Id) failed on $FilePath : $_"
            }
        }
    }
    catch {
        Write-Warning "Failed to analyze $FilePath : $_"
    }
    
    return $findings
}

function Test-SecurityRule {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Rule,
        
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$AST,
        
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $ruleFindings = @()
    
    # Determine AST pattern to search for
    $astTypeName = "System.Management.Automation.Language.$($Rule.ASTPattern)"
    
    try {
        $astType = [Type]::GetType($astTypeName)
        
        if (-not $astType) {
            Write-Verbose "Could not load AST type: $astTypeName"
            return @()
        }
        
        # Find all matching AST nodes
        $matchingNodes = $AST.FindAll({
            param($node)
            $node.GetType().Name -eq $Rule.ASTPattern -or
            $node.GetType().FullName -eq $astTypeName
        }, $true)
        
        foreach ($node in $matchingNodes) {
            $isMatch = $false
            $matchedCode = ""
            
            # Check CommandName if specified
            if ($Rule.CommandName) {
                if ($node -is [System.Management.Automation.Language.CommandAst]) {
                    $commandName = $node.GetCommandName()
                    $commandNames = $Rule.CommandName -split '\|'
                    
                    if ($commandNames -contains $commandName) {
                        $isMatch = $true
                    }
                    
                    # Check aliases if specified
                    if ($Rule.Aliases -and ($Rule.Aliases -contains $commandName)) {
                        $isMatch = $true
                    }
                }
            }
            
            # Check MemberName if specified (for MemberExpression)
            if ($Rule.MemberName) {
                if ($node -is [System.Management.Automation.Language.MemberExpressionAst]) {
                    $memberName = $node.Member.Value
                    $memberNames = $Rule.MemberName -split '\|'
                    
                    if ($memberNames -contains $memberName) {
                        $isMatch = $true
                    }
                }
            }
            
            # Check ParameterCheck if specified
            if ($isMatch -and $Rule.ParameterCheck) {
                $nodeText = $node.Extent.Text
                if ($nodeText -match $Rule.ParameterCheck) {
                    # Parameter check confirmed
                }
                else {
                    $isMatch = $false
                }
            }
            
            # Check ContextCheck if specified
            if ($Rule.ContextCheck) {
                # Get surrounding context (5 lines before and after)
                $startLine = [Math]::Max(1, $node.Extent.StartLineNumber - 5)
                $endLine = [Math]::Min($AST.Extent.EndLineNumber, $node.Extent.EndLineNumber + 5)
                
                $contextLines = $Content -split "`r?`n" | Select-Object -Skip ($startLine - 1) -First ($endLine - $startLine + 1)
                $context = $contextLines -join "`n"
                
                if ($context -match $Rule.ContextCheck) {
                    $isMatch = $true
                }
            }
            
            # Check PatternMatch if specified (for string content matching)
            if ($Rule.PatternMatch -and -not $isMatch) {
                if ($node -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                    if ($node.Value -match $Rule.PatternMatch) {
                        $isMatch = $true
                    }
                }
            }
            
            # If no specific checks, pattern match is enough
            if (-not $Rule.CommandName -and -not $Rule.MemberName -and -not $Rule.ParameterCheck -and -not $Rule.ContextCheck -and -not $Rule.PatternMatch) {
                $isMatch = $true
            }
            
            # Create finding if matched
            if ($isMatch) {
                # Extract code snippet
                $matchedCode = $node.Extent.Text
                if ($matchedCode.Length > 200) {
                    $matchedCode = $matchedCode.Substring(0, 197) + "..."
                }
                
                $finding = [PSCustomObject]@{
                    Source = 'CustomRules'
                    RuleId = $Rule.Id
                    RuleName = $Rule.Name
                    Severity = $Rule.Severity
                    Category = $Rule.Category
                    File = $FilePath
                    Line = $node.Extent.StartLineNumber
                    Column = $node.Extent.StartColumnNumber
                    EndLine = $node.Extent.EndLineNumber
                    Code = $matchedCode
                    Message = $Rule.Description
                    Remediation = $Rule.Remediation
                    CVSS = $Rule.CVSS
                    RequiresManualReview = if ($Rule.RequiresManualReview) { $true } else { $false }
                    FalsePositiveRisk = if ($Rule.FalsePositiveRisk) { $Rule.FalsePositiveRisk } else { 'Low' }
                }
                
                $ruleFindings += $finding
            }
        }
    }
    catch {
        Write-Verbose "Error testing rule $($Rule.Id): $_"
    }
    
    return $ruleFindings
}

# Note: Export-ModuleMember only works in modules, not in scripts
# These functions are made available when dot-sourced
