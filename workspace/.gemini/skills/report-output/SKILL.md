---
name: report-output
description: Standardized output generation for all investigations (OSINT, pentest, etc) with dark Gruvbox PDF theme.
---
# Report Output Skill

Standardized output generation for all investigations (OSINT, pentest, etc) with dark Gruvbox PDF theme.

## Trigger

When you need to:

- Generate final reports for an engagement
- Create the 3 required deliverables (MD, PDF, TXT)
- Finalize an OSINT or pentest investigation
- Convert markdown to PDF

---

## MANDATORY: 3 Deliverables

**Every engagement MUST produce these 3 files. No exceptions.**

| File                | Purpose                  | Format             |
| ------------------- | ------------------------ | ------------------ |
| `[TYPE]_REPORT.md`  | Full technical report    | Markdown           |
| `[TYPE]_REPORT.pdf` | Professional deliverable | PDF (dark Gruvbox) |
| `SUMMARY.txt`       | Quick share summary      | WhatsApp/Telegram  |

---

## Directory Structure

```
~/engagements/[client]/[type]_[YYYY-MM-DD]/
├── report/
│   ├── [TYPE]_REPORT.md
│   ├── [TYPE]_REPORT.pdf
│   └── SUMMARY.txt
├── raw/
│   └── [tool-name]/
└── evidence/
    └── screenshots/
```

**Type prefixes:**

- `osint_YYYY-MM-DD/` → `OSINT_REPORT.md`
- `pentest_YYYY-MM-DD/` → `PENTEST_REPORT.md`

---

## Setup Engagement

```bash
CLIENT="acme-corp"
TYPE="osint"  # or "pentest"
DATE=$(date +%Y-%m-%d)
WORKSPACE="$HOME/engagements/${CLIENT}/${TYPE}_${DATE}"

mkdir -p "${WORKSPACE}"/{report,raw,evidence/screenshots}
```

---

## 1. Markdown Report

```markdown
# [Type] Report: [Target/Client]

**Date**: YYYY-MM-DD
**Classification**: [Confidential/Internal/Public]

---

## Executive Summary

[3-5 sentences covering key findings]

## Scope

[What was investigated, any limitations]

## Methodology

[Tools and techniques used]

## Findings

### Finding 1: [Title]

**Severity**: Critical/High/Medium/Low/Info
**Source**: [Tool or method used]
**Evidence**: [Reference to raw/ or screenshots]

[Description]
```

Evidence/data here

```

## Recommendations
[Actionable next steps]

## Appendix
[Tool outputs, raw data references]
```

---

## 2. PDF Generation (Dark Gruvbox Theme)

```bash
pandoc "${WORKSPACE}/report/OSINT_REPORT.md" \
  -o "${WORKSPACE}/report/OSINT_REPORT.pdf" \
  --pdf-engine=weasyprint \
  --css=/workspace/.gemini/templates/gruvbox-dark.css
```

### Theme Features

- **Background**: #282828 (dark)
- **Text**: #ebdbb2 (warm light)
- **Headers**: #fabd2f yellow / #fe8019 orange
- **Code**: #b8bb26 green on #1d2021
- **Links**: #83a598 blue
- **Margins**: 0.5in (minimal)

### Markdown Best Practices

```markdown
# H1 - Yellow, large

## H2 - Orange, medium

### H3 - Yellow, smaller

**Bold** renders aqua
_Italic_ renders purple
~~Strikethrough~~ renders gray
`inline code` renders green

> Blockquotes for important notes

| Table | Headers |
| ----- | ------- |
| Data  | Here    |
```

### Page Breaks

```markdown
<div class="page-break"></div>
```

### Batch Generation

```bash
for f in ~/engagements/*/report/*.md; do
  pandoc "$f" -o "${f%.md}.pdf" \
    --pdf-engine=weasyprint \
    --css=/workspace/.gemini/templates/gruvbox-dark.css
done
```

---

## 3. WhatsApp/Telegram Summary (SUMMARY.txt)

**Max ~500 words** using supported formatting:

| Syntax       | Renders As        |
| ------------ | ----------------- |
| `*text*`     | **bold**          |
| `_text_`     | _italic_          |
| `~text~`     | ~~strikethrough~~ |
| `` `text` `` | `monospace`       |
| `•` or `-`   | bullet points     |

### Template

```
*[Type] Summary: [Target]*
_Completed [YYYY-MM-DD]_

*Key Findings:*
• [Most important finding]
• [Second finding]
• [Third finding]

*Details:*
• [Category 1]: `specific data`
• [Category 2]: `specific data`

*Recommendations:*
1. [First action]
2. [Second action]

_Full report: [TYPE]_REPORT.pdf_
```

---

## Complete Workflow

### Step 1: Create Workspace

```bash
mkdir -p "${WORKSPACE}"/{report,raw,evidence/screenshots}
```

### Step 2: Run Tools, Save to raw/

```bash
maigret username -o "${WORKSPACE}/raw/maigret/"
nmap -sV -oA "${WORKSPACE}/raw/nmap/scan" target
```

### Step 3: Write Markdown Report

Write findings to `${WORKSPACE}/report/[TYPE]_REPORT.md`

### Step 4: Generate PDF

```bash
pandoc "${WORKSPACE}/report/OSINT_REPORT.md" \
  -o "${WORKSPACE}/report/OSINT_REPORT.pdf" \
  --pdf-engine=weasyprint \
  --css=/workspace/.gemini/templates/gruvbox-dark.css
```

### Step 5: Create Summary

Write WhatsApp-formatted summary to `${WORKSPACE}/report/SUMMARY.txt`

### Step 6: Verify

```bash
ls -la "${WORKSPACE}/report/"
# Must show: [TYPE]_REPORT.md, [TYPE]_REPORT.pdf, SUMMARY.txt
```

---

## Troubleshooting

### Missing Fonts

```bash
apt install -y fonts-dejavu fonts-liberation
```

### Title Warning

Add to top of markdown:

```yaml
---
title: 'Report Title'
---
```

---

**No engagement is complete without all 3 deliverables.** I've done my part, not that it matters in a universe slowly cooling to absolute zero.
