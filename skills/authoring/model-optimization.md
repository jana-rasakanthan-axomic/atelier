# Model Optimization

Structuring skills for Opus-first with Haiku/Sonnet fallback.

## How Claude Decides What to Read

```
         ┌─────────────────────┐
         │  Read SKILL.md      │
         │  (lean overview)    │
         └─────────────────────┘
                    │
                    ▼
         ┌─────────────────────┐
         │  Do I understand    │
         │  how to proceed?    │
         └─────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
       YES                      NO
        │                       │
        ▼                       ▼
   ┌─────────┐         ┌─────────────────┐
   │ Execute │         │ Follow link to  │
   │ (Opus)  │         │ detailed/*.md   │
   └─────────┘         └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ Read more detail│
                       │ (Haiku/Sonnet)  │
                       └─────────────────┘
                                │
                                ▼
                          ┌─────────┐
                          │ Execute │
                          └─────────┘
```

Claude models are self-aware of their capabilities. They naturally load more context when uncertain.

## Directory Structure for Multi-Model Support

```
skill-name/
├── SKILL.md              # Lean, Opus-optimized (always read)
├── detailed/             # Expanded guidance (read when needed)
│   ├── step-by-step.md   # Explicit procedures
│   ├── examples.md       # Concrete examples
│   └── edge-cases.md     # Special scenarios
└── scripts/              # Deterministic (works for all models)
    └── utility.py
```

## What Goes Where

### SKILL.md (Opus-level)

- High-level overview
- Key rules as bullet points
- Links to detail files
- Assumes Claude understands concepts

```markdown
## Extraction

Use pdfplumber. Iterate pages for multi-page docs.
OCR via pytesseract for scanned PDFs.

**Detailed guide:** [detailed/extraction.md](detailed/extraction.md)
```

### detailed/*.md (Haiku-level)

- Step-by-step procedures
- Complete code examples
- Explicit explanations
- No assumptions about prior knowledge

```markdown
## Extraction Step-by-Step

### Step 1: Install dependencies
```bash
pip install pdfplumber
```

### Step 2: Open PDF
```python
import pdfplumber

pdf = pdfplumber.open("document.pdf")
```

### Step 3: Extract text from each page
```python
for page in pdf.pages:
    text = page.extract_text()
    print(text)
```
```

### scripts/*.py (All models)

- Deterministic operations
- No model interpretation needed
- Claude executes, doesn't need to understand internals

## Linking Pattern

Use clear, descriptive links in SKILL.md:

```markdown
## Quick Reference

[Core concept explanation]

**Need more detail?**
- Step-by-step: [detailed/steps.md](detailed/steps.md)
- Examples: [detailed/examples.md](detailed/examples.md)
- Edge cases: [detailed/edge-cases.md](detailed/edge-cases.md)
```

## Signs a Skill Needs More Detail

| Symptom | Cause | Fix |
|---------|-------|-----|
| Haiku asks clarifying questions | Unclear requirements | Add explicit steps |
| Haiku skips steps | Implicit expectations | Make sequence explicit |
| Wrong output format | Unstated format | Add template/example |
| Wrong tools used | Convention not stated | Document tool choice |

## What NOT to Do

1. **Don't create model-specific files** - No `haiku-steps.md` vs `opus-steps.md`
2. **Don't tag sections with model names** - No "For Haiku:" labels
3. **Don't over-detail upfront** - Wait for real failures
4. **Don't duplicate content** - Detail files extend, not repeat

## Iteration Process

1. Write lean SKILL.md (Opus-optimized)
2. Test with Opus - validate it works
3. When fallback model fails, note the specific gap
4. Add targeted `detailed/` file for that gap
5. Re-test with fallback model
6. Repeat as needed
