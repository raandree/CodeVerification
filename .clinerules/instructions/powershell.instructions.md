---
applyTo: "**/*.ps1,**/*.psm1,**/*.psd1"
---

# PowerShell Best Practices and Standards

When working with PowerShell code, adhere to the following comprehensive guidelines derived from PSScriptAnalyzer rules, DSC Community standards, and PowerShell community best practices. These guidelines are based on the official DSC Community Style Guidelines (https://dsccommunity.org/styleguidelines/).

## File Encoding

### UTF-8 Encoding
- **ALWAYS** use UTF-8 encoding (without BOM) for all PowerShell files
- **Exception**: MOF files should use ASCII encoding
- Use `ConvertTo-UTF8` and `ConvertTo-ASCII` cmdlets when available

### Line Endings
- Save newlines using CR+LF (Windows style) for consistency
- All files must end with a newline character
- No trailing whitespace after backticks

## Approved Verbs

PowerShell uses a standardized Verb-Noun naming convention for cmdlets and functions.

### Use Only Approved Verbs
- **ALWAYS** use approved PowerShell verbs from `Get-Verb`
- Common verbs: `Get`, `Set`, `New`, `Remove`, `Add`, `Clear`, `Copy`, `Find`, `Format`, `Join`, `Move`, `Rename`, `Reset`, `Search`, `Select`, `Show`, `Split`, `Test`, `Invoke`, `Start`, `Stop`, `Enable`, `Disable`
- **NEVER** use synonyms: Use `Remove` not `Delete`, `Get` not `Retrieve`, `Set` not `Change`

### Verb Usage Examples
```powershell
# Correct
function Get-UserProfile { }
function Set-Configuration { }
function New-TemporaryFile { }
function Test-Connection { }

# Incorrect
function Retrieve-UserProfile { }  # Use Get-
function Change-Configuration { }   # Use Set-
function Create-TemporaryFile { }   # Use New-
function Check-Connection { }       # Use Test-
```

## Function Structure (DSC Community Standards)

### Function Names
- **MUST** use PascalCase: `Get-TargetResource`
- **MUST** use approved Verb-Noun format
- **MUST** use approved verbs only (from `Get-Verb`)
- **NO** synonyms: Use `Remove` not `Delete`, `Get` not `Retrieve`

```powershell
# Correct
function Get-TargetResource { }
function Set-Configuration { } 
function New-Event { }

# Incorrect
function get-targetresource { }        # Wrong case
function TargetResourceGetter { }      # Not Verb-Noun format 
function Normalize-String { }          # Not approved verb, use ConvertTo-
```

### Comment-Based Help
- **MANDATORY** for all functions
- **MUST** include at least SYNOPSIS and PARAMETER sections
- Use correct syntax directly above function

```powershell
# Incorrect - Simple comment
# Creates an event
function New-Event { }

# Correct - Proper comment-based help
<#
    .SYNOPSIS
        Creates an event

    .PARAMETER Message
        Message to write

    .PARAMETER Channel
        Channel where message should be stored

    .EXAMPLE
        New-Event -Message 'Attempting to connect to server' -Channel 'debug'
#>
function New-Event
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter()]
        [ValidateSet('operational', 'debug', 'analytic')]
        [String]
        $Channel = 'operational'
    )
    # Implementation
}
```

### Parameter Block Requirements
- **MANDATORY** parameter block for every function
- **MUST** be at top of function, not next to function name
- **MUST** display empty parameter block even if no parameters: `param ()`

```powershell
# Incorrect - Parameters next to function name
function Write-Text([Parameter(Mandatory = $true)][String]$Text) { }

# Incorrect - No parameter block
function Write-Nothing
{
    Write-Verbose -Message 'Nothing'
}

# Correct - Proper parameter block placement
function Write-Text
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Text
    )

    Write-Verbose -Message $Text
}

# Correct - Empty parameter block shown
function Write-Nothing
{
    param ()

    Write-Verbose -Message 'Nothing'
}
```

### Parameter Formatting Standards
- **Opening/closing parentheses**: Must be on their own lines for non-empty parameter blocks
- **Every parameter**: Must include `[Parameter()]` attribute
- **Mandatory parameters**: Use `[Parameter(Mandatory = $true)]`
- **Non-mandatory**: Use `[Parameter()]` (no Mandatory decoration)
- **Parameter separation**: Single blank line between parameters
- **Type placement**: Parameter type must be on its own line above parameter name
- **Attribute placement**: Each attribute on separate line

```powershell
# Correct parameter formatting
function Write-Text
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Text

        [Parameter()]
        [ValidateNotNullOrEmpty()]  
        [String]
        $PrefixText

        [Parameter()]
        [Boolean]
        $AsWarning = $false
    )
}

# Incorrect - All on one line  
function Write-Text
{
    param([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $Text )
}

# Incorrect - Wrong mandatory syntax
function Write-Text  
{
    param
    (
        [Parameter(Mandatory)]              # Should be Mandatory = $true
        [Parameter(Mandatory = $false)]     # Should omit Mandatory for non-mandatory
        [String]
        $Text
    )
}

# Incorrect - Missing separation and wrong formatting
function Write-Text
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Text
        [Parameter()]                       # Missing blank line above
        [Boolean]
        $AsWarning = $false
    )
}
```

### CmdletBinding Attribute
- **ALWAYS** use `[CmdletBinding()]` for advanced functions
- Provides access to common parameters (`-Verbose`, `-Debug`, `-ErrorAction`, etc.)
- Enables advanced parameter validation

```powershell
function Get-Example {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    Write-Verbose "Processing $Name"
}
```

### Output Type Declaration
- Declare output types using `[OutputType()]` attribute
- Helps with pipeline operations and IntelliSense

```powershell
function Get-Example {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    [PSCustomObject]@{
        Name = 'Value'
    }
}
```

### Parameter Best Practices

#### Mandatory Parameters
```powershell
[Parameter(Mandatory)]
[string]$RequiredParameter

# With custom error message (PowerShell 6+)
[Parameter(Mandatory, HelpMessage = 'Please provide the server name')]
[string]$ServerName
```

#### Parameter Validation
```powershell
# ValidateNotNullOrEmpty
[Parameter()]
[ValidateNotNullOrEmpty()]
[string]$Path

# ValidateSet for allowed values
[Parameter()]
[ValidateSet('Development', 'Test', 'Production')]
[string]$Environment

# ValidatePattern for regex validation
[Parameter()]
[ValidatePattern('^[A-Z]{3}-\d{4}$')]
[string]$Code

# ValidateScript for custom validation
[Parameter()]
[ValidateScript({ Test-Path $_ })]
[string]$FilePath

# ValidateRange for numeric ranges
[Parameter()]
[ValidateRange(1, 100)]
[int]$Percentage
```

#### Parameter Sets
```powershell
function Get-Data {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(ParameterSetName = 'ByName', Mandatory)]
        [string]$Name,
        
        [Parameter(ParameterSetName = 'ById', Mandatory)]
        [int]$Id
    )
}
```

#### Pipeline Input
```powershell
[Parameter(ValueFromPipeline)]
[string]$InputObject

[Parameter(ValueFromPipelineByPropertyName)]
[string]$ComputerName
```

## Whitespace and Formatting (DSC Community Standards)

### Indentation
- **ALWAYS** use 4 spaces for indentation, **NEVER** tabs
- **NO** tab characters allowed in files (except in here-strings)

### Braces and Newlines
- **Opening braces**: Always on new line for control structures
- **Closing braces**: Always on their own line
- **Assignment braces**: Stay on same line as assignment operator

```powershell
# Correct - Control structures
if ($booleanValue)
{
    Write-Verbose -Message "Boolean is $booleanValue"
}

# Correct - Assignments  
$scriptBlockVariable = {
    Write-Verbose -Message 'Executing script block'
}

$hashtableVariable = @{
    Key1 = 'Value1'
    Key2 = 'Value2'
}

# Incorrect - Opening brace on same line for control structures
if ($booleanValue) {
    Write-Verbose -Message "Boolean is $booleanValue"
}

# Incorrect - Assignment brace on new line
$scriptBlockVariable =
{
    Write-Verbose -Message 'Executing script block'
}
```

### Newline Rules
- **One newline** before opening braces (except assignments)
- **One newline** after opening braces
- **Two newlines** after closing braces (except when followed by another brace)
- **No more than two** consecutive newlines anywhere
- **One newline** when followed by another closing brace or continuing conditional/switch

```powershell
# Correct
function Get-MyValue
{
    Write-Verbose -Message 'Getting MyValue'

    if ($myBoolean)
    {
        return $MyValue
    }
    else
    {
        return 0
    }
}

Get-MyValue

# Incorrect - Too many newlines
function Get-MyValue
{
    Write-Verbose -Message 'Getting MyValue'


    return $MyValue
}
```

### Spacing Rules
- **One space** between type and variable name: `[Int] $number = 2`
- **One space** on either side of all operators: `$number = 2 + 4 - 5 * 9 / 6`
- **One space** between keywords and parentheses: `if ('example' -eq 'example')`
- **No spaces** inside parentheses: `if ($condition)`
- **Single space** between array elements: `@('one', 'two', 'three')`

```powershell
# Correct spacing
[Int] $number = 2
$result = $value1 + $value2
$condition = ($x -eq 5) -and ($y -gt 10)
if ('example' -eq 'example' -or 'magic')
foreach ($example in $examples)
@{ Name = 'Value' }
$array = @('one', 'two', 'three')

# Incorrect spacing  
[Int]$number = 2                    # Missing space after type
$number=2+4-5*9/6                   # Missing spaces around operators
if('example'-eq'example'-or'magic') # Missing spaces
foreach($example in $examples)      # Missing space after keyword
@{Name='Value'}                     # Missing spaces in hashtable
$array = @('one','two','three')     # Missing spaces after commas
```

### Array Formatting
Arrays should follow specific formatting rules:

```powershell
# Single line arrays (acceptable for short arrays)
$array = @('one', 'two', 'three')

# Multi-line arrays (preferred for readability)
$array = @(
    'one',
    'two', 
    'three'
)

# Alternative multi-line format (also acceptable)
$array = @(
    'one'
    'two'
    'three'
)

# Complex arrays with hashtables
$myArray = @(
    @{
        Key1 = Value1
        Key2 = Value2
    },
    @{
        Key1 = Value1
        Key2 = Value2
    }
)

# Incorrect - Mixed formatting
$array = @( 'one', `
'two', `
'three'
)

# Incorrect - Multiple elements on same line
$array = @(
    'one', 'two', `
    'my long string example', `
    'three', 'four'
)
```

### Hashtable Formatting
- Each property on its own line
- Proper indentation
- No space between brackets for empty hashtables

```powershell
# Correct - Empty hashtable
$hashtable = @{}

# Correct - Single property
$hashtable = @{
    Key1 = 'Value1'
}

# Correct - Multiple properties
$hashtable = @{
    Key1 = 'Value1'
    Key2 = 2
    Key3 = @{
        Key3Key1 = 'ExampleText'
        Key3Key2 = 42
    }
}

# Incorrect - Extra space in empty hashtable
$hashtable = @{
}

# Incorrect - All on one line
$hashtable = @{Key1 = 'Value1';Key2 = 2;Key3 = '3'}

# Incorrect - Mixed line formatting
$hashtable = @{ Key1 = 'Value1'
Key2 = 2
Key3 = '3' }
```

## Naming Conventions

### Functions and Cmdlets
- **ALWAYS** use PascalCase for function names: `Get-UserInformation`
- **ALWAYS** use approved Verb-Noun format
- **ALWAYS** use singular nouns (use `Get-User` not `Get-Users`)
- Names must be descriptive and clear - minimum 3 characters
- **NO** abbreviations should be used

#### Examples
```powershell
# Correct
function Get-TargetResource { }
function Set-Configuration { }
function New-TemporaryFile { }
function Test-Connection { }

# Incorrect  
function Get-TgtRes { }           # Abbreviated
function Change-Configuration { } # Use Set- not Change-
function Create-TemporaryFile { } # Use New- not Create-
function Check-Connection { }     # Use Test- not Check-
```

### Variables
- **Local variables**: Use camelCase: `$userName`, `$connectionString`
- **Script variables**: Use camelCase with scope: `$script:fileCount`
- **Global variables**: Use camelCase with scope: `$global:myResourceName`
- **Environment variables**: Use camelCase with scope: `$env:computerName`
- Names must be descriptive and clear - minimum 3 characters
- **NO** abbreviations should be used

```powershell
# Good - Descriptive camelCase
$remoteDesktopSessionHost = Get-RemoteDesktopSessionHost
$fileCharacterLimit = 42
$verboseMessage = 'New log message'

# Good - Proper scope usage
$script:fileCount = 0
$global:myResourceName = 'MyResource'

# Bad - Abbreviated or unclear
$r = Get-RdsHost
$frtytw = 42
$VerboseMessage = 'New log message'  # Should be camelCase
$verbosemessage = 'New log message'  # Should be camelCase
```

### Parameters
- **ALWAYS** use PascalCase for parameter names: `$SourcePath`, `$UserCredential`
- Names must be descriptive and clear
- **NO** abbreviations should be used

```powershell
# Good
param(
    [Parameter()]
    $SourcePath,
    
    [Parameter()]
    $myServerToUse
)

# Bad
param(
    [Parameter()]
    $SOURCEPATH,  # Wrong case
    
    [Parameter()]
    $sourcepath,  # Wrong case
    
    [Parameter()]
    $mySTU        # Abbreviated
)
```
$cs = 'Server=localhost'  # Unclear
$x = 3  # Non-descriptive
```

### Constants and Enumerations
```powershell
# Constants (Read-Only variables)
New-Variable -Name 'MAX_RETRY_COUNT' -Value 3 -Option ReadOnly

# Enumerations
enum LogLevel {
    Debug
    Information
    Warning
    Error
    Critical
}
```

)

## String Quotes and Comments (DSC Community Standards)

### Quote Usage Rules
- **Single quotes**: ALWAYS use for string literals (default choice)
- **Double quotes**: ONLY use when string contains expressions that need evaluation
- **Consistency**: Do not mix quote styles unnecessarily

```powershell
# Correct - Single quotes for literals
$string = 'String that does not evaluate variables'
$string = 'String that evaluate variable {0}' -f $SomeObject.SomeProperty

# Correct - Double quotes when variable evaluation needed  
$string = "String that evaluates variable $($SomeObject.SomeProperty)"

# Correct - Escaping quotes when needed
$string = 'String that evaluate variable ''{0}''' -f $SomeObject.SomeProperty
$string = "String that evaluate variable '{0}'" -f $SomeObject.SomeProperty

# Incorrect - Unnecessary double quotes
$string = "String that does not evaluate variables"
$string = "String that evaluate variable {0}" -f $SomeObject.SomeProperty
```

### Comment Formatting Rules
- **NO** commented-out code in checked-in files
- **First letter**: Must be capitalized
- **Single line**: On own line, single `#` followed by single space
- **Multi-line**: Use `<# #>` format with proper indentation
- **Indentation**: Comments indented same as following code line

```powershell
# Correct - Proper comment formatting
function Get-MyVariable
{
    # This is a good comment
    [CmdletBinding()]
    param ()

    # This is a good comment
    foreach ($example in $examples)
    {
        # This is a good comment
        Write-Verbose -Message $example
    }
}

# Correct - Multi-line comments
function Get-MyVariable
{
    [CmdletBinding()]
    param ()

    <#
        This is a good comment
        on multiple lines
    #>
    foreach ($example in $examples)
    {
        Write-Verbose -Message $example
    }
}

# Incorrect - Bad comment formatting  
function Get-MyVariable
{#this is a bad comment                    # Wrong placement
    [CmdletBinding()]
    param ()
#this is a bad comment                     # Not capitalized, no space
    foreach ($example in $examples)
    {
        Write-Verbose -Message $example #this is a bad comment  # Wrong placement
    }
}

# Incorrect - Using single # for multi-line
function Get-MyVariable
{
    [CmdletBinding()]
    param ()

    # this is a bad comment
    # On multiple lines
    foreach ($example in $examples)
    {
        # No commented-out code!
        # Write-Verbose -Message $example
    }
}
```

### PowerShell Keywords
- **Case**: All PowerShell keywords must be lowercase
- **Spacing**: Keywords followed by space if non-whitespace follows
- **Braces**: Keywords followed by curly brace follow "One Newline Before Braces" rule

```powershell
# PowerShell Keywords (must be lowercase):
# begin, break, catch, class, continue, data, define, do, dynamicparam, 
# else, elseif, end, enum, exit, filter, finally, for, foreach, from, 
# function, hidden, if, in, inlinescript, param, process, return, static, 
# switch, throw, trap, try, until, using, var, while

# Correct
foreach ($item in $list)
begin
{
    # Do some work
}

# Incorrect - Wrong case
ForEach ($item In $list)  # Should be lowercase
BEGIN                     # Should be lowercase  

# Incorrect - Missing space  
foreach($item in $list)   # Missing space after keyword

# Incorrect - Wrong brace placement
begin {                   # Should have newline before brace
    # Do some work
}
```

## Function Call Standards (DSC Community)

### Named Parameters Required
- **ALWAYS** use named parameters instead of positional parameters
- **Improves** readability and maintainability  
- **Use splatting** for functions with many parameters
- **All parameters** should be in splat when splatting is used

```powershell
# Incorrect - Positional parameters
Get-ChildItem C:\Documents *.md

# Correct - Named parameters
Get-ChildItem -Path C:\Documents -Filter *.md
```

### Parameter Splatting Standards
- Use splatting for long parameter lists
- Hashtable parameters must follow proper formatting rules
- All parameters should be in the splat

```powershell
# Correct - Simple call
$superLongVariableName = Get-MyVariablePlease -MyStringParameter '123456789012349012345678901234567890' -Verbose

# Correct - Splatting with all parameters
$getMySuperLongVariablePleaseParameters = @{
    MySuperLongHashtableParameter = @{
        MySuperLongKey1 = 'MySuperLongValue1'
        MySuperLongKey2 = 'MySuperLongValue2'
    }
    MySuperLongStringParameter = '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890'
    Verbose = $true
}
$superLongVariableName = Get-MySuperLongVariablePlease @getMySuperLongVariablePleaseParameters

# Correct - Line continuation with proper hashtable formatting
$superLongVariableName = Get-MySuperLongVariablePlease `
    -MySuperLongHashtableParameter @{
        MySuperLongKey1 = 'MySuperLongValue1'
        MySuperLongKey2 = 'MySuperLongValue2'
    } `
    -MySuperLongStringParameter '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890' `
    -Verbose

# Incorrect - Mixed splatting and direct parameters
$getMySuperLongVariablePleaseParameters = @{
    MySuperLongHashtableParameter = @{
        MySuperLongKey1 = 'MySuperLongValue1'
        MySuperLongKey2 = 'MySuperLongValue2'
    }
    MySuperLongStringParameter = '123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890'
}
$superLongVariableName = Get-MySuperLongVariablePlease @getMySuperLongVariablePleaseParameters -Verbose

# Incorrect - Poor hashtable formatting
$superLongVariableName = Get-MySuperLongVariablePlease -MySuperLongHashtableParameter @{ MySuperLongKey1 = 'MySuperLongValue1'; MySuperLongKey2 = 'MySuperLongValue2' } -Verbose
```

## Error Handling

### Use Try-Catch-Finally
```powershell
try {
    $content = Get-Content -Path $filePath -ErrorAction Stop
    Process-Content -Content $content
}
catch [System.IO.FileNotFoundException] {
    Write-Error "File not found: $filePath"
}
catch {
    Write-Error "An unexpected error occurred: $_"
    Write-Debug $_.ScriptStackTrace
}
finally {
    # Cleanup code
    if ($resource) {
        $resource.Dispose()
    }
}
```

### Error Action Preference
```powershell
# For specific commands
Get-Item -Path $path -ErrorAction SilentlyContinue

# For script scope
$ErrorActionPreference = 'Stop'  # Treat all errors as terminating
```

### Throwing Errors
```powershell
# Throw with message
throw "Configuration file not found at: $configPath"

# Throw with error record
$errorRecord = [System.Management.Automation.ErrorRecord]::new(
    [System.Exception]::new('Custom error'),
    'CustomErrorId',
    [System.Management.Automation.ErrorCategory]::InvalidOperation,
    $targetObject
)
throw $errorRecord

# Write-Error for non-terminating errors
Write-Error -Message "Failed to process item" -ErrorId "ProcessingError" -Category InvalidOperation
```

## Comment-Based Help

### Complete Help Template
```powershell
function Get-Example {
    <#
    .SYNOPSIS
        Brief description of the function (one line).
    
    .DESCRIPTION
        Detailed description of what the function does.
        Can span multiple lines.
    
    .PARAMETER Name
        Description of the Name parameter.
    
    .PARAMETER Path
        Description of the Path parameter.
    
    .EXAMPLE
        Get-Example -Name 'Test'
        
        Description of what this example does.
    
    .EXAMPLE
        'Item1', 'Item2' | Get-Example -Path C:\Temp
        
        Description of pipeline example.
    
    .INPUTS
        System.String
        
        Objects that can be piped to the function.
    
    .OUTPUTS
        System.Management.Automation.PSCustomObject
        
        Objects that the function outputs.
    
    .NOTES
        Author: Your Name
        Date: 2025-11-03
        Version: 1.0.0
        
        Additional notes about the function.
    
    .LINK
        https://docs.example.com/Get-Example
    
    .LINK
        Get-RelatedCommand
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter()]
        [string]$Path
    )
    
    process {
        # Function implementation
    }
}
```

## Code Style and Formatting

### Indentation and Braces
- Use 4 spaces for indentation (NOT tabs)
- Opening brace on same line as statement (One True Brace Style)
- Closing brace on its own line, aligned with statement

```powershell
# Correct
if ($condition) {
    Write-Output "True"
} else {
    Write-Output "False"
}

# Incorrect - K&R style not preferred
if ($condition)
{
    Write-Output "True"
}
```

### Line Length
- Keep lines under 115 characters when possible
- Break long lines at logical points
- Use backtick (`) for line continuation sparingly, prefer splatting

```powershell
# Long parameter list - use splatting
$splat = @{
    ComputerName = $server
    Credential = $cred
    ErrorAction = 'Stop'
    Verbose = $true
}
Get-WmiObject @splat

# Long pipeline - break after pipe
$result = Get-Process |
    Where-Object { $_.CPU -gt 100 } |
    Select-Object Name, CPU, Id |
    Sort-Object CPU -Descending
```

### Whitespace
```powershell
# Spaces after commas
$array = @(1, 2, 3, 4)

# Spaces around operators
$result = $value1 + $value2
$condition = ($x -eq 5) -and ($y -gt 10)

# No spaces inside parentheses
if ($condition) { }  # Correct
if ( $condition ) { }  # Incorrect

# Space after opening brace and before closing brace
@{ Name = 'Value' }  # Correct
@{Name='Value'}  # Incorrect
```

## Output and Formatting

### Return Objects, Not Formatted Output
```powershell
# Good - Returns objects
function Get-UserInfo {
    [PSCustomObject]@{
        Name = $user.Name
        Email = $user.Email
        Department = $user.Department
    }
}

# Bad - Returns formatted string
function Get-UserInfo {
    "$($user.Name) - $($user.Email)"
}
```

### Use Write-Output (Implicitly)
```powershell
# These are equivalent and correct
function Get-Value {
    "Value"  # Implicit Write-Output
}

function Get-Value {
    Write-Output "Value"  # Explicit
}

# DON'T use Write-Host for output (use for information display only)
```

### Use Appropriate Write Streams
```powershell
Write-Verbose "Detailed processing information"  # -Verbose flag
Write-Debug "Debug information"  # -Debug flag
Write-Warning "Warning message"  # Always shown
Write-Error "Error message"  # Always shown
Write-Information "Informational message"  # PowerShell 5+
```

## DSC Community Best Practices

### Avoid Hard-coded Computer Names  
- **NEVER** use hard-coded computer names (security risk)
- **USE** parameters or environment variables instead

```powershell
# Incorrect - Hard-coded computer name
Invoke-Command -Port 0 -ComputerName 'hardcodedName'

# Correct - Use environment variable  
Invoke-Command -Port 0 -ComputerName $env:computerName
```

### Avoid Empty Catch Blocks
- **NEVER** use empty catch blocks
- **USE** ErrorAction parameter with SilentlyContinue if you want to suppress errors
- **HANDLE** errors appropriately or let them bubble up

```powershell
# Incorrect - Empty catch block
try
{
    Get-Command -Name Invoke-NotACommand
}
catch {}

# Correct - Suppress with ErrorAction
Get-Command -Name Invoke-NotACommand -ErrorAction SilentlyContinue

# Correct - Handle the error
try  
{
    Get-Command -Name Invoke-NotACommand
}
catch
{
    Write-Warning "Command not found: $_"
}
```

### Null Comparisons
- **ALWAYS** place `$null` on the left side of comparisons
- **Prevents** PowerShell collection comparison issues

```powershell
# Incorrect - $null on right side
if ($myArray -eq $null)
{
    Remove-AllItems
}

# Correct - $null on left side  
if ($null -eq $myArray)
{
    Remove-AllItems
}
```

### Global Variables  
- **AVOID** global variables whenever possible
- **USE** script/local variables or parameters instead
- **Exception**: `$global:DSCMachineStatus` for DSC resource machine restarts

```powershell
# Incorrect - Global variable usage
$global:configurationName = 'MyConfigurationName'
Set-MyConfiguration -ConfigurationName $global:configurationName

# Correct - Script variable usage
$script:configurationName = 'MyConfigurationName'  
Set-MyConfiguration -ConfigurationName $script:configurationName
```

### Variable Declaration and Usage
- **NEVER** declare local/script variables unless used more than once
- **REMOVE** unused variables to reduce code clutter

### Credentials Security
- **ALWAYS** use PSCredential for credentials
- **NEVER** use plain text username/password parameters

```powershell
# Incorrect - Plain text credentials
function Get-Settings
{
    param
    (
        [String]
        $Username

        [String]
        $Password
    )
}

# Correct - PSCredential
function Get-Settings
{
    param
    (
        [Parameter()]
        [PSCredential]
        [Credential()]
        $UserCredential
    )
}
```

### Pipeline Usage
- **LIMIT** pipeline to maximum 1 pipe per line for readability  
- **USE** variables for complex pipeline operations
- **PREFER** foreach loops over extensive piping for script clarity

```powershell
# Incorrect - Too many pipes
Get-Objects | Where-Object { $_.Property -ieq 'Valid' } | Set-ObjectValue `
    -Value 'Invalid' | Foreach-Object { Write-Output $_ }

# Correct - Broken into readable steps
$validPropertyObjects = Get-Objects | Where-Object { $_.Property -ieq 'Valid' }

foreach ($validPropertyObject in $validPropertyObjects)
{
    $propertySetResult = Set-ObjectValue $validPropertyObject -Value 'Invalid'
    Write-Output $propertySetResult
}
```

### Type Declarations
- **AVOID** unnecessary type declarations when type is clear from context
- **USE** type declarations when they add clarity or are required

```powershell
# Incorrect - Unnecessary type declarations  
[String] $myString = 'My String'
[System.Boolean] $myBoolean = $true

# Correct - Type is clear from context
$myString = 'My String'
$myBoolean = $true

# Correct - Type declaration adds clarity
[ValidateSet('Start', 'Stop')]
[String] $Action = 'Start'
```

## Pester Testing Standards (DSC Community)

### Test Structure Requirements
- **Tests written in**: Pester framework
- **Development approach**: Preferably test-driven development (TDD)
- **Module test structure**: Must follow specific folder structure
- **Templates**: Use Sampler project Plaster templates for consistency

#### Required Folder Structure
```
tests/
├── Unit/                    # Unit tests for each resource
│   └── DSC_ResourceName.Tests.ps1
└── Integration/            # Integration tests when possible
    └── DSC_ResourceName.integration.Tests.ps1
```

#### File Naming Conventions
- **Unit tests**: `DSC_<ResourceName>.Tests.ps1`
- **Integration tests**: `DSC_<ResourceName>.integration.Tests.ps1`
- **Configuration files**: `DSC_<ResourceName>.config.ps1` (for integration tests)

### Test Categories

#### Unit Tests
- **Purpose**: Test individual functions in isolation
- **Scope**: All DSC resource functions (Get/Set/Test-TargetResource)
- **Requirements**: Must exist for every DSC resource
- **Dependencies**: Use mocking for external dependencies

#### Integration Tests  
- **Purpose**: Test complete functionality in realistic scenarios
- **Scope**: End-to-end testing of DSC resources
- **Requirement**: Should be created when possible
- **Limitations**: May not be possible if testing would damage system configuration

### Test Formatting
- **Capitalize** all Pester assertions: `It`, `Should`, `Be`
- **Assertion messages**: Must start with "Should"  
- **Context blocks**: Must start with "When"

```powershell
# Correct - Proper Pester formatting
Describe 'Get-TargetResource' {
    Context 'When called with valid parameters' {
        It 'Should return something' {
            Get-TargetResource @testParameters | Should -Be 'something'
        }
    }
    
    Context 'When Get-TargetResource is called' {
        Context 'When passing default parameters' {
            It 'Should return something' {
                Get-TargetResource @testParameters | Should -Be 'something'  
            }
        }
    }
}

# Incorrect - Wrong capitalization and messaging
Describe 'Get-TargetResource' {
    context 'Calling Get-TargetResource with default parameters' {  # Should start with "When"
        it 'Something is returned' {                                # Should start with "Should"  
            get-targetresource @testParameters | should -be 'something'  # Wrong capitalization
        }
    }
}
```

### Advanced Testing Patterns

#### Testing Private Functions
Use `InModuleScope` to test non-exported functions:

```powershell
InModuleScope $script:dscResourceName {
    Describe "$($script:dscResourceName)\Get-FirewallRuleProperty" {
        Context 'When testing private function' {
            It 'Should return expected result' {
                Get-FirewallRuleProperty -Name 'TestProperty' | Should -Not -BeNullOrEmpty
            }
        }
    }
}
```

#### Accessing Module Variables in Tests
Three approaches for accessing module-scoped variables like `$script:localizedData`:

```powershell
# Method 1: Run tests inside InModuleScope
InModuleScope $script:dscResourceName {
    It 'Should throw correct error message' {
        {
            Set-TargetResource @setTargetResourceParameters
        } | Should -Throw $script:localizedData.DatabaseMailDisabled
    }
}

# Method 2: Copy variable into test scope
$localizedData = InModuleScope $script:dscResourceName {
    $script:localizedData
}

# Method 3: Export variables in module
Export-ModuleMember -Function *-TargetResource -Variables LocalizedData
```

#### Mock Output Variables Pattern
For variables used in mocks within `InModuleScope`:

```powershell
# Create script block variables for mocks
$GetNetAdapter_PhysicalNetAdapterMock = {
    return @{
        Name              = 'Ethernet'
        PhysicalMediaType = '802.3'
        Status            = 'Up'
    }
}

# Use in mock
Mock `
    -CommandName Get-NetAdapter `
    -ModuleName $script:ModuleName `
    -MockWith $GetNetAdapter_PhysicalNetAdapterMock
```

### Test Organization Patterns

#### Pattern 1: Function-Based Organization
```powershell
Describe 'Get-TargetResource' {
    Context 'When called with valid parameters' {
        It 'Should return expected properties' {
            # Test implementation
        }
    }
}

Describe 'Set-TargetResource' {
    Context 'When system is not in desired state' {
        It 'Should configure the resource correctly' {
            # Test implementation
        }
    }
}

Describe 'Test-TargetResource' {
    Context 'When system is in desired state' {
        It 'Should return true' {
            # Test implementation
        }
    }
}
```

#### Pattern 2: State-Based Organization (Recommended)
```powershell
Describe 'The system is not in the desired state' {
    # Mock cmdlets for non-desired state
    Mock Get-Service { return @{ Status = 'Stopped' } }
    
    $testParameters = @{
        Name = 'TestService'
        State = 'Running'
    }

    It 'Should return current state' {
        $result = Get-TargetResource @testParameters
        $result.State | Should -Be 'Stopped'
    }

    It 'Should return false from test' {
        Test-TargetResource @testParameters | Should -Be $false
    }

    It 'Should start the service' {
        Set-TargetResource @testParameters
        Assert-MockCalled Start-Service
    }
}

Describe 'The system is in the desired state' {
    # Mock cmdlets for desired state
    Mock Get-Service { return @{ Status = 'Running' } }
    
    $testParameters = @{
        Name = 'TestService'
        State = 'Running'
    }

    It 'Should return current state' {
        $result = Get-TargetResource @testParameters
        $result.State | Should -Be 'Running'
    }

    It 'Should return true from test' {
        Test-TargetResource @testParameters | Should -Be $true
    }
}
```

### Localization Testing

#### Testing Localized Error Messages
Use helper functions to test localized messages:

```powershell
# Helper function for invalid argument errors
$errorRecord = Get-InvalidArgumentRecord `
    -Message ($script:localizedData.InterfaceNotAvailableError -f $interfaceAlias) `
    -ArgumentName 'Interface'

It 'Should throw an InterfaceNotAvailable error' {
    { Assert-ResourceProperty @testRoute } | Should -Throw $errorRecord
}

# Helper function for invalid operation errors  
$errorRecord = Get-InvalidOperationRecord `
    -Message ($script:localizedData.NetAdapterNotFoundError)

It 'Should throw the correct exception' {
    {
        $script:result = Find-NetworkAdapter -Name 'NoMatch'
    } | Should -Throw $errorRecord
}
```

### Running Tests

#### Local Testing Requirements
1. **Resolve dependencies** first
2. **Build module** before testing
3. **Re-build** after any source file changes (tests run against built module)

#### Test Execution Commands
```powershell
# Run all tests
.\build.ps1 -Tasks test

# Run only unit tests with coverage
.\build.ps1 -Tasks test -PesterScript 'tests/Unit'

# Run only integration tests without coverage
.\build.ps1 -Tasks test -PesterScript 'tests/Integration' -CodeCoverageThreshold 0
```

#### Important Notes
- Tests always run against the **built module** in 'output' folder, not source files
- **Known Issue**: Common modules may need manual removal between test runs: `Remove-Module -Name 'ModuleName'`
- Integration tests may temporarily disrupt system configuration

### Test Configuration and Opt-Outs

#### HQRM Tests
- High Quality Resource Module tests from [DscResource.Test](https://github.com/dsccommunity/DscResource.Test)
- Automatically included by default
- Updated independently - check changelog for updates

#### Opting Out of Tests
Configure in `build.yaml` when tests cannot be resolved:

```yaml
# Opt-out from specific unit test tags
Pester:
  ExcludeTag:
    - 'TagOnUnitTest'

# Opt-out from HQRM tests  
DscTest:
  ExcludeTag:
    - 'Common Tests - New Error-Level Script Analyzer Rules'
    - 'Common Tests - Validate Example Files'
    - 'Common Tests - Relative Path Length'
```

#### Default Opt-Outs
- **"New Error-Level Script Analyzer Rules"**: Opt-out by default (tests PSDSCDscExamplesPresent and PSDSCDscTestsPresent rules)
- Still runs but won't fail the test phase
- Shows as yellow (skipped) if violations, green (passed) if no violations

### Best Practices Summary
- ✅ Follow TDD approach when possible
- ✅ Use Sampler templates for consistency
- ✅ Test both desired and non-desired states
- ✅ Mock external dependencies appropriately
- ✅ Test localized error messages
- ✅ Use proper Pester formatting and naming
- ✅ Organize tests by system state rather than just function
- ✅ Build module before testing
- ✅ Run tests locally before committing
- ✅ Create integration tests when safe to do so
```

## PSScriptAnalyzer Rules

### Critical Rules
- **PSAvoidUsingCmdletAliases**: Never use aliases in scripts (use `Get-ChildItem`, not `gci` or `dir`)
- **PSAvoidUsingWriteHost**: Avoid `Write-Host` except for interactive scripts
- **PSUseDeclaredVarsMoreThanAssignments**: Remove unused variables
- **PSAvoidUsingPositionalParameters**: Always use parameter names
- **PSUseApprovedVerbs**: Only use approved PowerShell verbs

```powershell
# Bad
gci $path | % { Write-Host $_.Name }

# Good
Get-ChildItem -Path $path | ForEach-Object { Write-Output $_.Name }
```

### Important Rules
- **PSUseShouldProcessForStateChangingFunctions**: Implement `-WhatIf` and `-Confirm` for state-changing functions
- **PSAvoidUsingPlainTextForPassword**: Use `[SecureString]` for passwords
- **PSAvoidUsingInvokeExpression**: Never use `Invoke-Expression` with user input
- **PSAvoidGlobalVars**: Minimize global variable usage
- **PSUseSingularNouns**: Function nouns should be singular

### ShouldProcess Pattern
```powershell
function Remove-Example {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    if ($PSCmdlet.ShouldProcess($Path, 'Remove item')) {
        Remove-Item -Path $Path
    }
}
```

## Module Development with Sampler

### Module Structure
When using Sampler for module scaffolding:

```
ModuleName/
├── source/
│   ├── Classes/           # PowerShell classes
│   ├── Private/          # Private functions (not exported)
│   ├── Public/           # Public functions (exported)
│   ├── en-US/           # Help files
│   ├── ModuleName.psd1  # Module manifest
│   └── ModuleName.psm1  # Root module
├── tests/
│   └── Unit/            # Pester tests
├── build.ps1            # Build script
├── build.yaml           # Sampler build configuration
└── RequiredModules.psd1 # Module dependencies
```

### Public vs Private Functions
- **Public**: Functions in `Public/` folder are exported and available to users
- **Private**: Functions in `Private/` folder are internal helpers

```powershell
# Public function (source/Public/Get-Example.ps1)
function Get-Example {
    [CmdletBinding()]
    param()
    
    # Can call private functions
    $internal = Get-InternalData
    Process-Data -Data $internal
}

# Private function (source/Private/Get-InternalData.ps1)
function Get-InternalData {
    [CmdletBinding()]
    param()
    
    # Internal implementation
}
```

### Module Manifest Best Practices
```powershell
# ModuleName.psd1
@{
    RootModule = 'ModuleName.psm1'
    ModuleVersion = '1.0.0'
    GUID = '<generate-new-guid>'
    Author = 'Your Name'
    CompanyName = 'Company'
    Copyright = '(c) 2025. All rights reserved.'
    Description = 'Module description'
    PowerShellVersion = '5.1'
    
    # Functions to export (managed by Sampler)
    FunctionsToExport = @('Get-Example', 'Set-Example')
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Tag1', 'Tag2')
            LicenseUri = 'https://github.com/user/repo/blob/main/LICENSE'
            ProjectUri = 'https://github.com/user/repo'
            ReleaseNotes = 'See CHANGELOG.md'
        }
    }
}
```

## Performance Best Practices

### Use .NET Methods When Appropriate
```powershell
# Faster
[System.IO.File]::ReadAllText($path)

# Slower
Get-Content -Path $path -Raw
```

### Avoid Pipeline for Large Collections
```powershell
# Slow for large collections
$results = 1..10000 | Where-Object { $_ % 2 -eq 0 }

# Faster
$results = foreach ($num in 1..10000) {
    if ($num % 2 -eq 0) {
        $num
    }
}

# Or use .Where() method (PowerShell 4+)
$results = (1..10000).Where({ $_ % 2 -eq 0 })
```

### StringBuilder for String Concatenation
```powershell
# Slow
$result = ""
foreach ($item in $largeCollection) {
    $result += "$item`n"
}

# Fast
$sb = [System.Text.StringBuilder]::new()
foreach ($item in $largeCollection) {
    [void]$sb.AppendLine($item)
}
$result = $sb.ToString()
```

## Security Best Practices

### Credentials
```powershell
# Use SecureString for passwords
[Parameter()]
[SecureString]$Password

# Use PSCredential
[Parameter()]
[PSCredential]$Credential

# Creating credentials securely
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$credential = [PSCredential]::new($username, $securePassword)
```

### Avoid Injection
```powershell
# NEVER use Invoke-Expression with user input
# Bad
Invoke-Expression $userInput

# Use parameter binding instead
& $command -Parameter $userInput

# For SQL queries, use parameterized queries
$query = "SELECT * FROM Users WHERE UserID = @UserID"
$params = @{ UserID = $userId }
Invoke-SqlCmd -Query $query -Parameters $params
```

### Execution Policy
```powershell
# Check execution policy
Get-ExecutionPolicy

# Set for current user (doesn't require admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Testing with Pester

### Test Structure
```powershell
# ModuleName.Tests.ps1
BeforeAll {
    $modulePath = "$PSScriptRoot\..\output\ModuleName"
    Import-Module $modulePath -Force
}

Describe 'Get-Example' {
    Context 'When called with valid parameters' {
        It 'Should return expected object' {
            $result = Get-Example -Name 'Test'
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Test'
        }
    }
    
    Context 'When called with invalid parameters' {
        It 'Should throw an error' {
            { Get-Example -Name $null } | Should -Throw
        }
    }
}
```

## Additional Best Practices

### Use Strict Mode
```powershell
# At top of script
Set-StrictMode -Version Latest
```

### Explicit Type Casting
```powershell
# Good
[int]$number = '42'
[datetime]$date = '2025-11-03'

# More reliable than implicit conversion
```

### Region Markers for Organization
```powershell
#region Initialization
$config = Get-Configuration
#endregion

#region Functions
function Get-Data { }
#endregion

#region Main Script
Main-Function
#endregion
```

### Version Compatibility
- Target PowerShell 5.1 for Windows compatibility
- Use `#Requires -Version 5.1` at top of script
- Test on both Windows PowerShell and PowerShell 7+
- Avoid platform-specific features unless necessary

## Summary Checklist

### DSC Community Standards
- ✅ **File Encoding**: UTF-8 without BOM (ASCII for .mof files)
- ✅ **Function Names**: PascalCase, Verb-Noun format, approved verbs only
- ✅ **Variable Names**: camelCase for local, include scope for script/global/environment  
- ✅ **Parameter Names**: PascalCase, descriptive (minimum 3 chars), no abbreviations
- ✅ **Comment-based Help**: Mandatory for all functions with SYNOPSIS and PARAMETER sections
- ✅ **Parameter Blocks**: Always present, proper formatting, [Parameter()] for all parameters
- ✅ **Whitespace**: 4 spaces indentation, proper brace placement, spacing rules
- ✅ **String Quotes**: Single quotes default, double quotes only for variable evaluation
- ✅ **Keywords**: Lowercase PowerShell keywords with proper spacing
- ✅ **Named Parameters**: Always use in function calls, splat for complex parameters
- ✅ **Array/Hashtable**: Proper multi-line formatting with correct indentation

### Security and Best Practices  
- ✅ **No Hard-coded Names**: Use parameters/environment variables
- ✅ **No Empty Catches**: Handle errors or use ErrorAction SilentlyContinue
- ✅ **Null Comparisons**: `$null` on left side of comparisons
- ✅ **Avoid Global Variables**: Use script scope or parameters instead
- ✅ **PSCredential**: Use for all credentials, never plain text
- ✅ **Limited Piping**: Maximum 1 pipe per line, use variables for clarity
- ✅ **Type Declarations**: Only when necessary for clarity

### Pester Testing
- ✅ **Test Structure**: Follow required folder structure (tests/Unit, tests/Integration)
- ✅ **File Naming**: Use DSC_ResourceName.Tests.ps1 and DSC_ResourceName.integration.Tests.ps1
- ✅ **Capitalized Assertions**: `It`, `Should`, `Be` properly capitalized
- ✅ **Test Messages**: Start with "Should" for assertions
- ✅ **Context Messages**: Start with "When" for context blocks
- ✅ **TDD Approach**: Use test-driven development when possible
- ✅ **State-Based Testing**: Organize tests by system state (desired/non-desired)
- ✅ **InModuleScope**: Use for testing private functions and accessing module variables
- ✅ **Mocking**: Proper mocking patterns for external dependencies
- ✅ **Localization**: Test localized error messages with helper functions
- ✅ **Build Before Test**: Always build module before running tests
- ✅ **Local Testing**: Run all tests locally before committing
- ✅ **Integration Tests**: Create when safe and possible
- ✅ **HQRM Tests**: Use High Quality Resource Module tests
- ✅ **Test Coverage**: Ensure adequate coverage for all functions

### General PowerShell Standards
- ✅ Use approved verbs
- ✅ Include `[CmdletBinding()]`
- ✅ Add complete comment-based help
- ✅ Use proper parameter validation
- ✅ Implement error handling
- ✅ Follow naming conventions
- ✅ Return objects, not formatted text
- ✅ Use PSScriptAnalyzer and fix all warnings
- ✅ Write Pester tests for all public functions
- ✅ Use 4-space indentation
- ✅ Avoid aliases in scripts
- ✅ Implement `-WhatIf` and `-Confirm` for state changes
- ✅ Use secure credentials
- ✅ Document with examples
