---
applyTo: "**/*.md"
---

# Markdown Best Practices and Standards

When working with Markdown files, adhere to the following comprehensive guidelines derived from the Markdown Guide and community best practices.

## Core Principles

### What is Markdown?
- Lightweight markup language with plain text formatting syntax
- Created by John Gruber in 2004
- Designed to be easy to read and write
- Converts to HTML and other formats
- Multiple flavors: CommonMark, GitHub Flavored Markdown (GFM), etc.

### Design Philosophy
- **Readable**: Source should be as readable as rendered output
- **Simple**: Easy to learn and use
- **Portable**: Works across platforms and tools
- **Flexible**: Supports basic formatting and advanced features

## Headings

### ATX-Style Headings (Preferred)
```markdown
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6
```

### Best Practices
- **Always** use a space after the `#` symbols
- Use only one H1 (`#`) per document (document title)
- Don't skip heading levels (go H1 → H2 → H3, not H1 → H3)
- Add blank lines before and after headings

```markdown
# Document Title

This is the introduction paragraph.

## Section One

Content for section one.

### Subsection 1.1

More detailed content.
```

### Setext-Style Headings (Alternative, Less Common)
```markdown
Heading 1
=========

Heading 2
---------
```

**Note**: ATX-style is preferred for consistency and clarity.

## Emphasis

### Bold
```markdown
**Bold text** using double asterisks
__Bold text__ using double underscores

Preferred: **bold**
```

### Italic
```markdown
*Italic text* using single asterisks
_Italic text_ using single underscores

Preferred: *italic*
```

### Bold and Italic
```markdown
***Bold and italic*** using triple asterisks
___Bold and italic___ using triple underscores
**_Mixed approach_**
*__Also mixed__*

Preferred: ***bold and italic***
```

### Best Practices
- Use asterisks (`*`) for consistency
- Don't use underscores in the middle of words
- Add spaces around emphasis for readability in source

```markdown
<!-- Good -->
This is **really** important.

<!-- Avoid - no spaces makes source harder to read -->
This is**really**important.
```

## Lists

### Unordered Lists
```markdown
- Item 1
- Item 2
- Item 3

* Alternative using asterisks
* Item 2
* Item 3

+ Another alternative using plus
+ Item 2
+ Item 3

Preferred: Use dashes (-)
```

### Ordered Lists
```markdown
1. First item
2. Second item
3. Third item

<!-- Numbers can all be 1 (auto-numbered) -->
1. First item
1. Second item
1. Third item

<!-- But explicit numbering is preferred for clarity -->
1. First item
2. Second item
3. Third item
```

### Nested Lists
```markdown
1. First item
   - Nested bullet
   - Another nested bullet
2. Second item
   1. Nested number
   2. Another nested number
```

### Task Lists (GitHub Flavored Markdown)
```markdown
- [x] Completed task
- [ ] Incomplete task
- [ ] Another incomplete task
```

### Best Practices
- Use consistent markers (prefer `-` for unordered lists)
- Add blank lines before and after lists
- Indent nested items with 2 or 4 spaces (be consistent)
- For ordered lists, use sequential numbers

```markdown
This is a paragraph.

- Item 1
- Item 2
  - Nested item 2.1
  - Nested item 2.2
- Item 3

This is another paragraph.
```

## Links

### Inline Links
```markdown
[Link text](https://www.example.com)
[Link with title](https://www.example.com "Title text")
```

### Reference Links
```markdown
[Link text][reference]
[Another link][ref2]

[reference]: https://www.example.com
[ref2]: https://www.example.com "Optional title"
```

### Automatic Links
```markdown
<https://www.example.com>
<email@example.com>
```

### Internal Links (Anchors)
```markdown
[Link to heading](#heading-id)

<!-- GitHub auto-generates IDs from headings -->
[Jump to Examples](#examples-section)
```

### Best Practices
- Use descriptive link text (not "click here")
- Use reference links for repeated URLs
- Add titles for additional context

```markdown
<!-- Good -->
Read the [official documentation](https://docs.example.com) for details.

<!-- Avoid -->
[Click here](https://docs.example.com) for documentation.
```

## Images

### Inline Images
```markdown
![Alt text](path/to/image.png)
![Alt text](path/to/image.png "Image title")
```

### Reference Images
```markdown
![Alt text][image-reference]

[image-reference]: path/to/image.png "Optional title"
```

### Best Practices
- Always provide meaningful alt text for accessibility
- Use relative paths for images in the same repository
- Consider image size and optimization

```markdown
<!-- Good - descriptive alt text -->
![Screenshot of the application dashboard showing user statistics](./images/dashboard.png)

<!-- Avoid - non-descriptive alt text -->
![Image](./images/dashboard.png)
```

## Code

### Inline Code
```markdown
Use `inline code` for commands, variables, or short snippets.
Example: Run the `Get-Command` cmdlet.
```

### Code Blocks (Fenced)
````markdown
```
Plain code block without syntax highlighting
```

```powershell
# PowerShell code with syntax highlighting
Get-Process | Where-Object { $_.CPU -gt 100 }
```

```yaml
# YAML code with syntax highlighting
key: value
nested:
  item: value
```
````

### Code Blocks (Indented - Less Common)
```markdown
    Indent with 4 spaces for code block
    Another line of code
```

### Best Practices
- Always specify language for syntax highlighting in fenced code blocks
- Use fenced code blocks (```) instead of indented
- Escape backticks in inline code with double backticks

````markdown
<!-- Escaping backticks -->
Use ``code with `backticks` inside`` like this.
````

### Common Language Identifiers
```markdown
```bash        # Bash/Shell scripts
```powershell  # PowerShell
```python      # Python
```javascript  # JavaScript
```json        # JSON
```yaml        # YAML
```markdown    # Markdown
```csharp      # C#
```html        # HTML
```css         # CSS
```sql         # SQL
```
```

## Blockquotes

### Basic Blockquote
```markdown
> This is a blockquote.
> It can span multiple lines.
```

### Nested Blockquotes
```markdown
> First level
>> Second level
>>> Third level
```

### Blockquotes with Other Elements
```markdown
> ## Heading in Blockquote
>
> - List item 1
> - List item 2
>
> **Bold text** in blockquote.
```

### Best Practices
- Add blank line before and after blockquotes
- Use for quotes, notes, or callouts

```markdown
Regular paragraph.

> **Note**: This is an important note to remember.

Another paragraph.
```

## Horizontal Rules

### Creating Horizontal Rules
```markdown
---

***

___

Preferred: --- (three hyphens)
```

### Best Practices
- Add blank lines before and after horizontal rules
- Use three hyphens (`---`) for consistency
- Don't overuse - only for major section breaks

## Tables (GitHub Flavored Markdown)

### Basic Table
```markdown
| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |
```

### Alignment
```markdown
| Left Aligned | Center Aligned | Right Aligned |
|:-------------|:--------------:|--------------:|
| Left         | Center         | Right         |
| Text         | Text           | Text          |
```

### Best Practices
- Align columns in source for readability
- Use alignment syntax when appropriate
- Keep tables simple - complex tables are hard to maintain

```markdown
| Command        | Description                          |
|:---------------|:-------------------------------------|
| `Get-Process`  | Gets running processes               |
| `Get-Service`  | Gets Windows services                |
| `Get-Command`  | Gets all available PowerShell cmdlets|
```

## Line Breaks and Paragraphs

### Paragraphs
```markdown
This is paragraph one.

This is paragraph two.
```

### Line Breaks
```markdown
Line one  
Line two (two spaces at end of line one)

Or use a backslash\
Like this
```

### Best Practices
- Use blank lines to separate paragraphs
- Avoid trailing spaces (use `<br>` if needed)
- Don't add extra blank lines for spacing

## Escaping Characters

### Backslash Escapes
```markdown
\* Not italic \*
\# Not a heading
\[Not a link\]
\`Not code\`
```

### Characters That Can Be Escaped
```markdown
\   backslash
`   backtick
*   asterisk
_   underscore
{}  curly braces
[]  square brackets
()  parentheses
#   hash
+   plus
-   minus
.   dot
!   exclamation
```

## Extended Syntax (GitHub Flavored Markdown)

### Strikethrough
```markdown
~~Strikethrough text~~
```

### Emoji
```markdown
:smile: :heart: :thumbsup:
```

### Footnotes
```markdown
Here's a sentence with a footnote[^1].

[^1]: This is the footnote content.
```

### Definition Lists
```markdown
Term
: Definition of the term

Another term
: Another definition
```

### Automatic URL Linking
```markdown
GitHub automatically converts URLs to links:
https://www.example.com
```

## Best Practices Summary

### Document Structure
- ✅ Use one H1 per document (title)
- ✅ Follow logical heading hierarchy
- ✅ Add blank lines between sections
- ✅ Use consistent list markers
- ✅ Start lists and code blocks on new lines

### Formatting
- ✅ Use ATX-style headings (`#`)
- ✅ Use asterisks for emphasis (`*italic*`, `**bold**`)
- ✅ Use dashes for unordered lists (`-`)
- ✅ Use fenced code blocks with language specification
- ✅ Add alt text to all images

### Readability
- ✅ Keep lines under 100 characters when possible
- ✅ Use blank lines generously for visual separation
- ✅ Align table columns in source
- ✅ Use descriptive link text
- ✅ Write meaningful alt text for images

### Compatibility
- ✅ Test in target Markdown processor (GitHub, VS Code, etc.)
- ✅ Avoid processor-specific syntax when portability matters
- ✅ Use standard Markdown for maximum compatibility
- ✅ Document when using extended syntax

## Common Pitfalls

### Pitfall 1: Missing Blank Lines
```markdown
<!-- Wrong -->
# Heading
Content immediately after

<!-- Right -->
# Heading

Content with blank line after heading
```

### Pitfall 2: Incorrect List Indentation
```markdown
<!-- Wrong -->
- Item 1
 - Nested item (only 1 space)
- Item 2

<!-- Right -->
- Item 1
  - Nested item (2 spaces)
- Item 2
```

### Pitfall 3: Missing Language in Code Blocks
````markdown
<!-- Less useful -->
```
function Get-Data {
    # Code without syntax highlighting
}
```

<!-- Better -->
```powershell
function Get-Data {
    # Code with syntax highlighting
}
```
````

### Pitfall 4: Not Escaping Special Characters
```markdown
<!-- Wrong - will render as emphasis -->
File_name_with_underscores

<!-- Right -->
File\_name\_with\_underscores
```

### Pitfall 5: Inconsistent Formatting
```markdown
<!-- Wrong - mixed emphasis syntax -->
This is *italic* and this is _also italic_.
This is **bold** and this is __also bold__.

<!-- Right - consistent syntax -->
This is *italic* and this is *also italic*.
This is **bold** and this is **also bold**.
```

## Documentation Patterns

### README Structure
```markdown
# Project Name

Brief description of the project.

## Features

- Feature 1
- Feature 2
- Feature 3

## Installation

\```powershell
Install-Module -Name ModuleName
\```

## Usage

\```powershell
Get-Example -Name 'Test'
\```

## Examples

### Example 1: Basic Usage
Description and code.

### Example 2: Advanced Usage
Description and code.

## Contributing

Guidelines for contributors.

## License

License information.
```

### Changelog Structure
```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- New feature description

### Changed
- Changed feature description

### Fixed
- Bug fix description

## [1.0.0] - 2025-01-03

### Added
- Initial release
```

### Module Documentation Pattern
```markdown
# Get-Example

## Synopsis
Brief description of the function.

## Syntax

\```powershell
Get-Example [-Name] <String> [[-Path] <String>] [<CommonParameters>]
\```

## Description
Detailed description of what the function does.

## Parameters

### -Name
Description of Name parameter.

- Type: String
- Required: Yes
- Position: 0

### -Path
Description of Path parameter.

- Type: String
- Required: No
- Position: 1

## Examples

### Example 1
\```powershell
Get-Example -Name 'Test'
\```

Description of what this example does.

## Inputs

- System.String

## Outputs

- System.Management.Automation.PSCustomObject

## Notes
Additional notes and information.
```

## Linting and Validation

### Markdownlint Rules
Common rules to follow:
- MD001: Heading levels should increment by one
- MD003: Heading style should be consistent
- MD004: List style should be consistent
- MD009: No trailing spaces
- MD010: No hard tabs
- MD012: No multiple blank lines
- MD022: Headings should be surrounded by blank lines
- MD031: Fenced code blocks should be surrounded by blank lines
- MD032: Lists should be surrounded by blank lines

### VS Code Extensions
- `markdownlint` - Linting and style checking
- `Markdown All in One` - Shortcuts and formatting
- `Markdown Preview Enhanced` - Enhanced preview

## Summary Checklist

- ✅ One H1 heading per document
- ✅ Logical heading hierarchy (no skipped levels)
- ✅ Blank lines around headings, lists, code blocks
- ✅ Consistent emphasis syntax (prefer asterisks)
- ✅ Consistent list markers (prefer dashes)
- ✅ Fenced code blocks with language specification
- ✅ Descriptive link text and alt text
- ✅ No trailing spaces (except for line breaks)
- ✅ Escaped special characters where needed
- ✅ Tables aligned in source
- ✅ Tested in target Markdown processor
