# Prompts

## Prompt 1 - Initial setup

The PowerShell modules in the source folder need be checked for security and malicious code. Please start with a memory bank to outline the task and track the progress. Also create documentation to describe the overall purpose of the the project.

## Prompt 2.1 - Define Detection Rules

Browse the web and learn about PowerShell security coding guidelines. Then create a Detection Rules file that combines the knowledge.

This is a sample how the detection rules should be formatted.

```
Id = 'PS001'
Name = 'Invoke-Expression Usage'
Severity = 'Medium'
Category = 'CodeExecution'
Description = 'Detects use of Invoke-Expression which can execute arbitrary code from strings'
ASTPattern = 'CommandAst'
CommandName = 'Invoke-Expression'
Remediation = 'Replace Invoke-Expression with safer alternatives like & operator or dot-sourcing'
CVSS = 5.3
```

Please also use the PowerShell module `PSScriptAnalyzer` as input. Also scan the web
for additional `PSScriptAnalyzer` rules that are available on GitHub for example in the organization
https://github.com/dsccommunity.

## Prompt 2.2 - Realign the detection rules

The source code is PowerShell. In PowerShell it is normal to deal with credentials in a
semi-secure way.

A rule like 'Sensitive Data in Logs' should be only treated as critical if it effects plaintext passwords, security keys or tokens. Writing user names or IDs to log files is essential for debugging.

A rule like 'High Entropy Strings' should be deemphasized. PowerShell by nature uses high entropy strings to express the intend in code. Findings should be analyzed further for security issues and not treated as critical by default.

## Prompt 2.3 - Generate PowerShell security scanning scripts

Please generate scripts that read the previously defined rules to scan the source code for security
issues. Also make use of the `PSScriptAnalyzer` and `Pester` to generate the scripts.

## Prompt 3 - Start the code review

Start the code review according to the process and the definitions in the memory bank.

The report should be created in the folder `Report`. In there, we need a executive summary
covering all PowerShell modules and one detailed report per PowerShell module.

The finings in the details report should have the following structure:

```text
Rule: <Rule>
Category: <Category>
File: <Full File Path>
- Line: <All lines numbers>
  Code: <Code or line content>
- Line: <All lines numbers>
  Code: <Code or line content>
Description: <Description>
Remediation: <Suggestions for remediation>
CVSS Score: <CVSS Score>
```

Important: Report 'High Entropy Detection' with care. If it very likely that we generate a
lot of false positives.

Report on 'Hardcoded Credentials' only if you actually find hard coded credentials in the code
or if the code very likely exposes the credentials in an inappropriate way, for example writing
them to a log file or write them to the console.

## Prompt 4 - Pending tasks

Review the memory bank for pending tasks and print them out.

## Prompt 5 - Optional tasks

Please run also the optional tasks.
