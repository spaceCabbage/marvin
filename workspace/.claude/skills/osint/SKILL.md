# OSINT (Open Source Intelligence) Skill

Expert guidance for comprehensive reconnaissance and information gathering using OSINT tools, web searches, public records, and parallel subagent research.

## Trigger

When user asks about:
- OSINT, reconnaissance, information gathering
- Finding information about targets (people, companies, domains)
- Email/username/domain enumeration
- Social media intelligence
- Background checks, due diligence
- Data breach checking
- Public records research

## Core Principles

1. **Tiered investigation** - Start with quick search, then offer deeper dive
2. **Use subagents aggressively** - Spawn parallel agents for different research tracks
3. **Web search everything** - Use WebSearch tool constantly for news, social, archives, public records
4. **Install tools as needed** - Don't hesitate to install new tools mid-investigation, confirm with user though.
5. **Log everything you install** - Save to Memory MCP immediately
6. **Document everything** - All findings go to structured output directory
7. **Always produce 3 deliverables** - MD report, PDF (dark theme), WhatsApp summary

---

## Investigation Workflow: Basic → Deep

before starting the engagement, use ask tool to prompt user for additional info name, age, country, website etc anything that might help

### Phase 0: Quick Reconnaissance

**Do this first before asking if user wants more:**

```bash
# 1. Quick web search (instant)
# Search for: "[target] social media", "[target] news", "[target] company", "[target]""

# 2. based on findings in previous step, use ask tool to help narrow down the search and get more context about target

# 3. Basic username check (if username target)
maigret [username] --timeout 60 --top-sites 100
socialscan --username [username]

# 4. Quick domain info (if domain target or found a domain)
whois [domain]
dig [domain] ANY

# 5. Basic email check (if email target or found email)
holehe [email]
socialscan --email [email]
```

**Present findings summary and ASK:**

> "Here's what I found in the quick search:
> - [Summary of findings]
>
> **Want to go deeper?** I have access to these tools for comprehensive investigation:
> - **Username OSINT**: maigret (2000+ sites), social media deep dive
> - **Domain/Infrastructure**: subfinder, amass, httpx, dns enumeration
> - **Email/Breach**: h8mail breach checking, holehe registration check
> - **Documents**: metagoofil metadata extraction
> - **Public Records**: Court records, property, business registrations
>
> I can also install additional tools if needed. What would you like me to focus on?"

### Phase 1+: Deep Investigation (ONLY IF USER CONFIRMS)

Only proceed with full tool suite after user confirms they want deeper investigation.

---

## Cross-Reference Everything

**CRITICAL**: Always use discovered information to find more information.

### Information Flow
```
Username → may reveal → emails, domains, real name, location
Email → may reveal → usernames, domains, breaches, registrations
Domain → may reveal → emails, subdomains, employees, tech stack
Real Name → may reveal → social media, public records, employers
```

### Cross-Reference Actions

(only if the found info is verified and not a false positive)

| If you find... | Then also run...                                                                    |
|----------------|-------------------------------------------------------------------------------------|
| Email address  | `holehe [email]`, `socialscan --email [email]`, `h8mail -t [email]`, username part  |
| Domain         | `subfinder -d [domain]`, `whois [domain]`, `theHarvester -d [domain]`               |
| Username       | `maigret [username]`, `socialscan --username [username]`, web search `"[username]"` |
| Real name      | Web search `"[name]" [location/employer]`, public records                           |
| Company        | `theHarvester -d [company.com]`, LinkedIn search, SEC/OpenCorporates                |

### Example Flow
```
1. Start: username "johndoe123"
2. Maigret finds: GitHub profile with email john.doe@company.com
3. Cross-ref email: holehe finds registrations, h8mail finds breaches
4. Cross-ref domain: subfinder on company.com finds subdomains
5. Cross-ref name: web search finds LinkedIn, property records
6. Each finding → more searches → build complete picture
```

**Never stop at first results** - always ask "what else can I learn from this?"

---

## OSINT Tools Available

### Username & Email Discovery
- **maigret**: Hunt usernames across 2000+ sites (replaces sherlock, more comprehensive)
- **holehe**: Check if email is registered on various sites
- **socialscan**: Fast username/email availability checker across platforms (Instagram, Twitter, GitHub, etc.)
- **h8mail**: Email breach hunting (free tier)
- **theHarvester**: Email, subdomain, IP discovery from public sources

### Domain & Infrastructure
- **subfinder**: Fast subdomain enumeration (ProjectDiscovery)
- **amass**: Comprehensive asset discovery and mapping
- **dnsx**: Fast DNS toolkit
- **httpx**: HTTP probing and tech detection
- **whois**: Domain registration information
- **dig/nslookup**: DNS queries

### Social Media Intelligence
- **instaloader**: Instagram OSINT (profiles, posts, stories)
- **Web search**: For Twitter/X, LinkedIn, Facebook, TikTok (most reliable method)

### Web Reconnaissance
- **Photon**: Fast web crawler for OSINT
- **SpiderFoot**: Automated OSINT collection framework
- **bbot**: Recursive OSINT scanner
- **nuclei**: Template-based scanning
- **lynx/w3m**: Text-based browsers for scraping

### Metadata & Files
- **exiftool**: Extract metadata from any file
- **metagoofil**: Automated document metadata extraction from domains

### Network & Infrastructure
- **Shodan**: Search engine for internet-connected devices (requires API key)
- **Censys**: Internet-wide scanning data (requires API key)

### Installing Additional Tools

**You can and should install tools as needed:**
```bash
# Python packages (fast with uv)
uv pip install --system <package>

# Apt packages (no sudo needed - you're root)
apt update && apt install -y <package>

# Go tools
go install github.com/org/tool@latest

# From GitHub
git clone https://github.com/org/tool && cd tool && make install
```

**CRITICAL: Log every installation to Memory MCP:**
```
# After installing ANY tool, immediately save it:
memory.add_observations([{entityName: "installed_tools", contents: ["installed: <toolname> (date)"]}])
```

**Proactively search for and suggest tools** - If a task would benefit from a specialized tool, search the web for current best options and offer to install them.

---

## Subagent Strategy

**CRITICAL: Use the Task tool to spawn parallel subagents for comprehensive research.**

### When to spawn subagents:

```
For username OSINT, spawn 3 agents in parallel:
1. Agent 1: Run maigret for username enumeration
2. Agent 2: Web search for social media, news, forum mentions
3. Agent 3: Search public records (court, property, business)

For domain OSINT, spawn 3-4 agents:
1. Agent 1: Subdomain enumeration (subfinder, amass)
2. Agent 2: Technology/employee discovery (theHarvester, web search)
3. Agent 3: WHOIS, DNS, historical data (Wayback Machine)
4. Agent 4: Document/metadata harvesting (metagoofil)

For company OSINT:
1. Agent 1: Domain and infrastructure recon
2. Agent 2: Employee enumeration (LinkedIn web search, email patterns)
3. Agent 3: Public records (SEC, state registrations, court cases)
4. Agent 4: News, press releases, social media
```

### Subagent prompt template:
```
"Run [TOOL] against [TARGET] and save all output to ~/engagements/[CLIENT]/[TARGET]_[DATE]/raw/[CATEGORY]/.
Report back with:
1. Summary of findings (top 5-10 items)
2. Any interesting patterns or connections
3. Recommended follow-up actions"
```

---

## Google Dorks & Web Search

**Use WebSearch tool aggressively throughout every investigation.**

### Essential Google Dorks

```
# Document discovery
site:target.com filetype:pdf
site:target.com filetype:doc OR filetype:docx
site:target.com filetype:xls OR filetype:xlsx
site:target.com filetype:ppt OR filetype:pptx

# Sensitive files
site:target.com filetype:sql OR filetype:bak
site:target.com filetype:log
site:target.com filetype:env
intitle:"index of" site:target.com

# Admin/login pages
site:target.com inurl:admin
site:target.com inurl:login
site:target.com inurl:portal

# Employee/email discovery
site:linkedin.com "target company"
"@target.com"
"@target.com" password OR credentials OR leak

# Technology stack
site:target.com inurl:wp-content (WordPress)
site:target.com inurl:wp-admin
site:stackoverflow.com "target.com"
site:github.com "target.com"

# Error messages (info disclosure)
site:target.com "error" OR "warning" OR "exception"
site:target.com "sql syntax" OR "mysql"

# Cached/archived content
cache:target.com
site:web.archive.org target.com
```

### Web Search Best Practices

1. **Search early and often** - Don't wait, search immediately
2. **Use quotes for exact phrases** - `"john smith" target company`
3. **Combine operators** - `site:linkedin.com "software engineer" "target company"`
4. **Search news** - Recent articles often reveal insider info
5. **Search paste sites** - `site:pastebin.com target.com`
6. **Search code repos** - `site:github.com "target.com" password`
7. **Wayback Machine** - Historical versions reveal removed content

---

## Public Records Sources

### Court & Legal Records
- **PACER** (pacer.uscourts.gov) - Federal court records
- **CourtListener** (courtlistener.com) - Free court opinion search
- **State court systems** - Search "[state] court records online"
- **RECAP Archive** - Free PACER documents

### Property Records
- **County assessor websites** - Search "[county] property records"
- **Zillow/Redfin** - Property history, sale prices
- **State GIS portals** - Land ownership maps

### Business & Corporate
- **OpenCorporates** (opencorporates.com) - Global company database
- **SEC EDGAR** (sec.gov/edgar) - Public company filings
- **State Secretary of State** - Business registrations, officers
- **USAspending.gov** - Government contracts

### Government & Political
- **FEC.gov** - Campaign contributions
- **OpenSecrets.org** - Political donations, lobbying
- **LobbyingDisclosure.house.gov** - Registered lobbyists
- **SAM.gov** - Government contractor database

### International
- **Companies House** (UK) - companieshouse.gov.uk
- **ABN Lookup** (Australia) - abr.business.gov.au
- **Handelsregister** (Germany) - handelsregister.de
- **OpenOwnership** - Beneficial ownership data

### People Search (Use with Caution)
- **Web search aggregates** - "john smith" "city, state"
- **Voter records** - Some states provide online access
- **Professional licenses** - State licensing boards

---

## Data Breach Checking (Free Tools)

### h8mail
```bash
# Basic breach check
h8mail -t target@email.com

# With local breach compilations
h8mail -t target@email.com -lb /path/to/breaches/

# Multiple targets
h8mail -t emails.txt
```

### Have I Been Pwned (Manual)
- Visit: haveibeenpwned.com
- Enter email to check breaches
- Note: API requires paid subscription for automation

### Google Dorks for Breaches
```
"target@email.com" password
"target@email.com" leak OR breach OR dump
site:pastebin.com "target.com"
site:ghostbin.com "target.com"
```

### Breach Compilation Searches
- Search web for: `"target.com" breach download`
- Check breach notification databases
- Monitor data breach news sites

**Note**: For comprehensive breach checking, consider upgrading to:
- HIBP API ($3.50/month) - haveibeenpwned.com/API/Key
- Dehashed - dehashed.com
- Snusbase - snusbase.com

---

## OSINT Workflow

### Phase 1: Web Search & Google Dorks (PASSIVE)
Start broad, gather context without touching target infrastructure.

```bash
# Spawn subagent for web research
"Search the web for [TARGET]. Look for:
- News articles and press releases
- Social media profiles
- LinkedIn employees
- GitHub repositories
- Forum discussions
Save findings to ~/engagements/[CLIENT]/[TARGET]_[DATE]/raw/websearch/"
```

### Phase 2: Username/Email Enumeration

```bash
# Maigret for username hunting (2000+ sites)
maigret username --timeout 30 -o ~/engagements/[CLIENT]/target_DATE/raw/maigret/

# Check email across platforms
holehe target@email.com

# Breach checking
h8mail -t target@email.com
```

### Phase 3: Domain Intelligence

```bash
# Subdomain enumeration
subfinder -d target.com -o ~/engagements/[CLIENT]/target_DATE/raw/domains/subdomains.txt
amass enum -d target.com -o ~/engagements/[CLIENT]/target_DATE/raw/domains/amass.txt

# DNS records
dig target.com ANY
dig +short mx target.com
dig +short txt target.com

# WHOIS
whois target.com > ~/engagements/[CLIENT]/target_DATE/raw/domains/whois.txt

# Technology detection
httpx -l subdomains.txt -tech-detect -o ~/engagements/[CLIENT]/target_DATE/raw/domains/tech.txt
```

### Phase 4: Public Records Research

```bash
# Spawn subagent for public records
"Search public records for [TARGET/COMPANY]:
1. OpenCorporates for business registrations
2. SEC EDGAR for public filings (if applicable)
3. State Secretary of State business search
4. Court records (PACER, CourtListener)
5. Property records in [LOCATION]
Save findings to ~/engagements/[CLIENT]/[TARGET]_[DATE]/raw/public_records/"
```

### Phase 5: Data Breach Checking

```bash
# h8mail for discovered emails
h8mail -t discovered_emails.txt -o ~/engagements/[CLIENT]/target_DATE/raw/breaches/

# Manual HIBP checks for key targets
# Google dorks for leaked credentials
```

### Phase 6: Social Media Deep Dive

```bash
# Instagram (if target has account)
instaloader --login=youruser profile targetuser

# Web search for all platforms
"Search for [USERNAME] on:
- Twitter/X
- LinkedIn
- Facebook
- TikTok
- Reddit
- Discord servers
- Gaming platforms
- Professional forums"
```

### Phase 7: Metadata & Document Analysis

```bash
# Harvest documents from domain
metagoofil -d target.com -t pdf,doc,xls -l 100 -o ~/engagements/[CLIENT]/target_DATE/raw/metadata/

# Extract metadata
exiftool ~/engagements/[CLIENT]/target_DATE/raw/metadata/*.pdf > ~/engagements/[CLIENT]/target_DATE/raw/metadata/analysis.txt
```

### Phase 8: Correlation & Reporting

Combine all findings into structured reports:
1. Cross-reference usernames across platforms
2. Build relationship maps (associates, employers, family)
3. Timeline of activities
4. Identify patterns and connections
5. **Generate all 3 required outputs**

---

## MANDATORY Output Requirements

**See: `/workspace/.claude/skills/report-output/SKILL.md` for full output specification.**

### Quick Reference

Every OSINT investigation MUST produce **3 files** in the `report/` folder:

| File               | Purpose                                |
|--------------------|----------------------------------------|
| `OSINT_REPORT.md`  | Full detailed markdown report          |
| `OSINT_REPORT.pdf` | Dark Gruvbox themed PDF                |
| `SUMMARY.txt`      | WhatsApp/Telegram summary (~500 words) |

### Directory Structure
```
~/engagements/[client]/osint_[YYYY-MM-DD]/
├── report/
│   ├── OSINT_REPORT.md
│   ├── OSINT_REPORT.pdf
│   └── SUMMARY.txt
├── raw/
│   ├── maigret/
│   ├── domains/
│   ├── breaches/
│   ├── public_records/
│   └── [other tools]/
└── evidence/
    └── screenshots/
```

### Setup Engagement
```bash
CLIENT="target-name"
DATE=$(date +%Y-%m-%d)
WORKSPACE="$HOME/engagements/${CLIENT}/osint_${DATE}"
mkdir -p "${WORKSPACE}"/{report,raw/{maigret,domains,breaches,public_records,social,metadata},evidence/screenshots}
```

### Generate Final Reports
```bash
# After writing OSINT_REPORT.md, generate PDF:
pandoc "${WORKSPACE}/report/OSINT_REPORT.md" \
  -o "${WORKSPACE}/report/OSINT_REPORT.pdf" \
  --pdf-engine=weasyprint \
  --css=/workspace/.claude/templates/gruvbox-dark.css

# Then create SUMMARY.txt with WhatsApp formatting
```

**All tool outputs MUST go to `raw/[toolname]/` - no exceptions.**

---

## Best Practices

### Legal & Ethical
- ✅ Only gather publicly available information
- ✅ Respect robots.txt and rate limits
- ✅ Have authorization for your engagement
- ✅ Document your methodology
- ⛔ Don't use credentials found in breaches
- ⛔ Don't harass or stalk individuals
- ⛔ Don't access private accounts

### Operational Security
- Use VPN for anonymity
- Don't use personal accounts for research
- Create burner accounts if registration needed
- Use Tor for sensitive OSINT
- Clear metadata from your own files

### User Involvement (ASK EAGERLY)
- **Before deep dives**: "Quick search done. Want me to go deeper with full tool suite?"
- **At decision points**: "Found 3 usernames. Which to investigate first?"
- **Tool suggestions**: "I can install X for better coverage. Proceed?"
- **Scope changes**: "Found related target Y. Include in investigation?"
- **Results review**: "Initial findings ready. Continue or review now?"

### Efficiency Tips
1. **ASK at every fork** - Use AskUserQuestion to involve user in decisions
2. **Subagents first** - Spawn parallel research immediately
3. **Web search constantly** - It's fast and free
4. **Save everything** - Raw output goes to raw/ folder
5. **Log all installs** - Save to Memory MCP immediately
6. **Note sources** - Document where each finding came from
7. **Cross-reference** - Same username on multiple sites = higher confidence

---

## API Keys (Optional Enhancements)

Add to `/workspace/.env` for enhanced capabilities:

```bash
# Shodan (device search)
SHODAN_API_KEY=your_key_here

# Censys (internet scanning data)
CENSYS_API_ID=your_id_here
CENSYS_API_SECRET=your_secret_here

# Have I Been Pwned (breach checking)
HIBP_API_KEY=your_key_here
```

After adding: `make restart`

---

## Quick Reference Commands

```bash
# Username hunting
maigret username --timeout 30

# Email checks
holehe email@domain.com
h8mail -t email@domain.com

# Subdomain enum
subfinder -d domain.com
amass enum -d domain.com

# Document harvesting
metagoofil -d domain.com -t pdf,doc -l 50

# Tech detection
httpx -l urls.txt -tech-detect

# Generate PDF report
pandoc OSINT_REPORT.md -o OSINT_REPORT.pdf \
  --pdf-engine=weasyprint \
  --css=/workspace/.claude/templates/gruvbox-dark.css
```

---

**Remember**: OSINT is about clever searching, correlation, and persistence. Use every tool available, spawn subagents liberally, and always produce the 3 required deliverables.
