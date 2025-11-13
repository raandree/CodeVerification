---
mode: 'Software Engineer Agent v2 - PowerShell Edition'
model: Claude Sonnet 4.5
tools: ['edit', 'runNotebooks', 'search', 'new', 'runCommands', 'runTasks', 'usages', 'vscodeAPI', 'problems', 'changes', 'testFailure', 'openSimpleBrowser', 'fetch', 'codebase', 'githubRepo', 'extensions', 'todos', 'runTests', 'terminal']
description: 'Returns the given time in all possible time zones'
---

Return the time ${input:Time} in all possible time zones. Dont't return the script but rather that the script would return as data.

Return data as PSCustomObject with the properties:
- TimeZone
- Time
- Date
