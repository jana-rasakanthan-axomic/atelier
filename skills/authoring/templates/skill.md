# Skill Template

Use this template when creating a new skill.

## File Structure

```
skill-name/
├── SKILL.md              # Main instructions (< 500 lines)
├── patterns/             # Detailed patterns (if needed)
│   └── pattern-name.md
├── templates/            # Code templates (if needed)
│   └── template.py.template
├── checklists/           # Validation checklists (if needed)
│   └── checklist-name.md
└── scripts/              # Executable scripts (if needed)
    └── utility.py
```

## SKILL.md Template

```markdown
---
name: skill-name-here
description: Brief description of what this skill does. Use when [trigger conditions].
allowed-tools: Read, Write, Edit, Grep, Glob
---

# Skill Name

One-line description of what this skill does.

## When to Use

- Trigger condition 1
- Trigger condition 2
- Trigger condition 3

## When NOT to Use

**Only for [specific purpose].** Do not use for any other purpose.

## Progressive Disclosure

### Core Concepts (Read First)

| File | Contains |
|------|----------|
| `_shared.md` | Common concepts, terminology |

### Pattern Files

| Pattern | File | Purpose |
|---------|------|---------|
| Pattern A | `patterns/a.md` | Description |
| Pattern B | `patterns/b.md` | Description |

## Quick Reference

[Summary of key rules - this should be scannable]

### Rule Category 1
- Rule 1
- Rule 2

### Rule Category 2
- Rule 3
- Rule 4

## Workflow

1. **Step 1**: Description
2. **Step 2**: Description
3. **Step 3**: Description

## Output Format

```json
{
  "field1": "description",
  "field2": "description"
}
```

## Tools Used

| Tool | Purpose |
|------|---------|
| Read | Examine existing code |
| Write | Create new files |
| Edit | Modify existing files |
```

## Key Principles

### 1. Conciseness

**Bad:**
```markdown
PDF (Portable Document Format) files are a common file format that contains
text, images, and other content. To extract text from a PDF, you'll need to
use a library. There are many libraries available...
```

**Good:**
```markdown
Use pdfplumber for text extraction:
```python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```
```

### 2. Progressive Disclosure

Keep SKILL.md lean (< 500 lines). Put details in separate files:
- SKILL.md → overview and navigation
- patterns/*.md → detailed patterns
- templates/*.template → code templates

### 3. One Level Deep

References should be direct from SKILL.md:

**Good:**
```markdown
# SKILL.md
See [patterns/validation.md](patterns/validation.md) for details
```

**Bad:**
```markdown
# SKILL.md
See [advanced.md](advanced.md)

# advanced.md
See [details.md](details.md)  # Too deep!
```

### 4. Third Person Descriptions

**Good:** "Extracts text from PDF files"
**Bad:** "I can help you extract text" or "You can use this to extract"

### 5. Include Trigger Conditions

**Good:** "Extract text from PDF files. Use when working with PDFs or document extraction."
**Bad:** "Helps with documents"
