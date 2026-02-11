# Authoring Best Practices

Based on Anthropic's official guidance for writing effective agent skills.

Source: [Skill Authoring Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

## Core Principles

### 1. Concise is Key

The context window is a public good. Every token competes with conversation history.

**Default assumption:** Claude is already very smart. Only add context Claude doesn't already have.

**Test each piece of information:**
- "Does Claude really need this explanation?"
- "Can I assume Claude knows this?"
- "Does this paragraph justify its token cost?"

**Example:**

Bad (~150 tokens):
```markdown
PDF (Portable Document Format) files are a common file format that contains
text, images, and other content. To extract text from a PDF, you'll need to
use a library. There are many libraries available...
```

Good (~50 tokens):
```markdown
Use pdfplumber for text extraction:
```python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```
```

### 2. Set Appropriate Degrees of Freedom

Match specificity to task fragility.

| Freedom | When to Use | Example |
|---------|-------------|---------|
| **High** (text-based) | Multiple approaches valid, context-dependent | Code review process |
| **Medium** (pseudocode/templates) | Preferred pattern exists, some variation OK | Report generation |
| **Low** (exact scripts) | Fragile operations, consistency critical | Database migrations |

**Analogy:**
- **Narrow bridge with cliffs:** Only one safe path → exact instructions
- **Open field:** Many paths work → general direction

### 3. Progressive Disclosure

Load information in stages as needed.

**Three levels:**
1. **Metadata** (always loaded) - ~100 tokens per skill
2. **Instructions** (when triggered) - < 5k tokens
3. **Resources** (as needed) - effectively unlimited

**Rules:**
- Keep SKILL.md body under 500 lines
- References one level deep from SKILL.md
- Supporting files have table of contents if >100 lines

### 4. Test with All Models

What works for Opus might need more detail for Haiku.

| Model | Consideration |
|-------|---------------|
| Haiku | Does skill provide enough guidance? |
| Sonnet | Is skill clear and efficient? |
| Opus | Does skill avoid over-explaining? |

## Structure Guidelines

### YAML Frontmatter

```yaml
---
name: skill-name          # max 64 chars, lowercase + hyphens
description: What it does. When to use it.  # max 1024 chars, third person
---
```

**Name rules:**
- Lowercase letters, numbers, hyphens only
- No "anthropic" or "claude"
- No XML tags

**Description rules:**
- Always third person ("Processes files", not "I process")
- Include WHAT it does AND WHEN to use it
- No XML tags

### Naming Conventions

**Gerund form (verb + -ing):**
- `processing-pdfs`
- `analyzing-spreadsheets`
- `managing-databases`

**Avoid:**
- Vague: `helper`, `utils`, `tools`
- Generic: `documents`, `data`, `files`

### File Organization

```
skill-name/
├── SKILL.md              # Overview and navigation
├── REFERENCE.md          # Detailed docs (loaded on-demand)
├── EXAMPLES.md           # Concrete patterns
└── scripts/
    └── utility.py        # Executed, not loaded into context
```

## Content Patterns

### Template Pattern

Provide output format. Match strictness to requirements.

**Strict (API responses):**
```markdown
ALWAYS use this exact structure:
```json
{"field": "value"}
```
```

**Flexible (when adaptation useful):**
```markdown
Sensible default format, adjust as needed:
```json
{"field": "value"}
```
```

### Examples Pattern

Input/output pairs help Claude understand style:

```markdown
**Example 1:**
Input: Added user authentication
Output: `feat(auth): implement JWT-based authentication`

**Example 2:**
Input: Fixed date display bug
Output: `fix(reports): correct date formatting`
```

### Workflow Pattern

Clear sequential steps with checklists:

```markdown
## Workflow

Task Progress:
- [ ] Step 1: Analyze input
- [ ] Step 2: Generate plan
- [ ] Step 3: Execute
- [ ] Step 4: Validate

**Step 1: Analyze input**
[Details]

**Step 2: Generate plan**
[Details]
```

### Feedback Loop Pattern

Validate → fix → repeat:

```markdown
1. Make changes
2. Validate: `python validate.py`
3. If validation fails:
   - Review error message
   - Fix the issue
   - Validate again
4. Only proceed when validation passes
```

## Anti-Patterns to Avoid

### Windows Paths
- **Good:** `scripts/helper.py`
- **Bad:** `scripts\helper.py`

### Too Many Options
- **Good:** Provide default with escape hatch
- **Bad:** "You can use A, or B, or C, or D..."

### Time-Sensitive Info
- **Good:** Use "old patterns" section
- **Bad:** "If you're doing this before August 2025..."

### Inconsistent Terminology
- **Good:** Always "API endpoint"
- **Bad:** Mix "endpoint", "URL", "route", "path"

### Deeply Nested References
- **Good:** SKILL.md → reference.md (one level)
- **Bad:** SKILL.md → advanced.md → details.md (too deep)

## Iteration Process

### Build Evaluations First

1. Run Claude on tasks WITHOUT skill
2. Document specific failures
3. Create 3+ test scenarios
4. Write minimal instructions to pass
5. Iterate based on real usage

### Develop with Claude

Use "Claude A" (author) to refine, "Claude B" (agent) to test:

1. Complete task with Claude A normally
2. Identify reusable patterns
3. Ask Claude A to create skill
4. Review for conciseness
5. Test with Claude B on real tasks
6. Iterate based on observed behavior
