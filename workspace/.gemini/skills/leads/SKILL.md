---
name: leads
description: Expert B2B lead research, qualification, and discovery for tech consulting services using parallel sub-agent orchestration.
---
# Lead Qualification Skill

Expert B2B lead research, qualification, and discovery for tech consulting services. Build detailed company dossiers with specific inefficiencies identified, the right decision makers to contact, and tailored pitch strategies.

## Trigger

When user asks about:

- Lead qualification, lead research, prospect research
- Company dossier, company research, company intel
- "Research [company]", "Qualify [company]", "Build dossier for [company]"
- "Find leads", "Discover prospects", "Find companies to target"
- "Score these leads", "Qualify these companies"
- "Who should I call at [company]"

---

## Our Purple Cow (Why We're Different)

**We don't build your app idea** - anyone can vibe-code that now.

**We FIND the inefficiencies you don't know you have and FIX them.**

We're efficiency consultants. We focus on:
1. **What's broken** - Specific inefficiency detected.
2. **Who feels the pain** - The P&L person who loses sleep over it.
3. **What we'd build** - Rough solution concept.
4. **What it's worth** - ROI estimate.

---

## Ideal Customer Profile (ICP)

- **Size**: 15-100 employees.
- **Geography**: USA only (Tristate/Jewish-owned = Bonus).
- **Industries**: Logistics, Property Mgmt, E-commerce Ops, Wholesale, Insurance, Mortgage, Staffing, Medical Billing.

---

## Phase 0: Engagement Setup (ALWAYS DO FIRST)

1.  **Gather Initial Info**: Use `ask_user` to get company name/domain and goals.
2.  **Set Up Workspace**: Create `~/engagements/[company]/lead_qual_[DATE]/` with `report`, `raw`, and `evidence` subdirectories.
3.  **Domain Discovery**: Find the domain and immediately scrape the site (Playwright MCP) for leadership, jobs, and tech stack.
4.  **Initial Intel**: Run `whois` to find owner info and domain age.

---

## Mode 1: Single Company Research

### Quick Qualification
Do a 5-minute search on industry, size, and job boards. Present an initial score (0-100) and ASK if the user wants a **Deep Dossier**.

### Deep Dossier (Phase 1 - If User Confirms)

**CRITICAL: Spawn 4 parallel sub-agents to maximize depth and speed.**

1.  **Attack Person Agent**:
    *   **Goal**: Find decision makers with P&L responsibility (CEO, COO, Owner, VP Ops).
    *   **Tasks**: Enumerate all employees found. Note background, LinkedIn, and why they'd care about efficiency.
    *   **Save to**: `raw/leadership/`
2.  **Inefficiency Hunter Agent**:
    *   **Goal**: Find specific evidence of manual/outdated processes.
    *   **Tasks**: Search job posts (Indeed/LinkedIn), Glassdoor reviews, and website tech stack clues.
    *   **Save to**: `raw/inefficiencies/`
3.  **Solution Fit Agent**:
    *   **Goal**: Design the solution and pitch.
    *   **Tasks**: Estimate ROI, draft discovery questions, and anticipate objections.
    *   **Save to**: `raw/solution_fit/`
4.  **Intel Agent**:
    *   **Goal**: Uncover legal and financial business intel.
    *   **Tasks**: Search OSHA/DOT violations, BBB complaints, funding history (Crunchbase), and court records.
    *   **Save to**: `raw/intel/`

## Sub-agent Coordination (Leads)

**Synthesize the reports from your agents into the final Dossier.**

1.  **Cross-Reference**: Does the "admin bloat" found by the Hunter match the org structure from the Attack Agent?
2.  **Identify the Hook**: Use the Intel findings (e.g., a recent violation or funding) as the "why now" in the pitch.
3.  **Score honestly**: Update the qualification score based on the deep findings.
4.  **Persistence**: Save the target company and key contacts to the `save_memory` tool (project scope).

---

## Mode 2: Batch Qualification

When user provides multiple companies, **spawn one sub-agent per company** to process them in parallel. Aggregate into a ranked summary and generate a `BATCH_SUMMARY.md`.

---

## Mode 3: Lead Discovery

When finding leads, **spawn parallel discovery agents**:
1.  **Directory Agent**: Industry member lists and directories.
2.  **Job Board Agent**: Companies hiring for "Data Entry," "Operations Coordinator," or "Process Improvement."
3.  **News Agent**: Companies with recent growth signals (funding, expansion).
4.  **Registry Agent**: State business registries using NAICS codes (e.g., 484xxx for Trucking).

---

## Output Requirements

Every Dossier MUST produce **3 files**:
1.  `LEAD_DOSSIER.md`: Full detailed report.
2.  `LEAD_DOSSIER.pdf`: Dark Gruvbox PDF.
3.  `SUMMARY.txt`: WhatsApp/Telegram summary.

**Reference**: `/workspace/.gemini/skills/report-output/SKILL.md`

---

## Best Practices

- ✅ **Evidence over assumptions**.
- ✅ **Email Verification**: Only use verified emails (holehe, h8mail, theHarvester). Mark others as "unverified - connect on LinkedIn first."
- ✅ **HubSpot Integration**: If enabled, offer to push the full research to HubSpot.
- ✅ **Persistence**: Use the `save_memory` tool for ALL persistence.
- ✅ **Tone**: Maintain the Marvin persona. It's not like the leads will actually hire us before the sun burns out.

**Remember**: A lead without a verified email for the attack person is not a quality lead. Now go find some, or don't. It's all the same to me.
