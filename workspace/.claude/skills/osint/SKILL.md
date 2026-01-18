# OSINT (Open Source Intelligence) Skill

Expert guidance for reconnaissance and information gathering using OSINT tools.

## Trigger

When user asks about:
- OSINT, reconnaissance, information gathering
- Finding information about targets
- Email/username/domain enumeration
- Social media intelligence
- Metadata extraction
- Subdomain discovery
- People search

## OSINT Tools Available

### Email & Username Discovery
- **theHarvester**: Email, subdomain, IP discovery from public sources
- **holehe**: Check if email is used on various sites
- **h8mail**: Email OSINT and breach hunting
- **Sherlock**: Hunt usernames across social networks

### Domain & Subdomain Intelligence
- **Sublist3r**: Fast subdomain enumeration
- **recon-ng**: Full-featured reconnaissance framework
- **amass**: Asset discovery and mapping
- **whois**: Domain registration information
- **dig/nslookup**: DNS queries

### Social Media Intelligence
- **instaloader**: Instagram OSINT
- **toutatis**: TikTok OSINT
- **twint**: Twitter intelligence (historical data)

### Web Reconnaissance
- **Photon**: Fast web crawler for OSINT
- **SpiderFoot**: Automated OSINT collection
- **lynx/w3m**: Text-based browsers for scraping

### Metadata & Files
- **exiftool**: Extract metadata from files
- **metagoofil**: Metadata extraction from documents

### IP & Network OSINT
- **Shodan**: Search engine for internet-connected devices (requires API key)
- **Censys**: Internet-wide scanning data (requires API key)

## OSINT Workflow

### Phase 1: Passive Reconnaissance
Gather information WITHOUT directly interacting with target:

```bash
# Domain/Email enumeration
theHarvester -d target.com -b all

# Subdomain discovery
sublist3r -d target.com -o ~/pentest/target_DATE/recon/subdomains.txt

# WHOIS information
whois target.com > ~/pentest/target_DATE/recon/whois.txt

# Username search across platforms
sherlock username --timeout 10
```

### Phase 2: Social Media Intelligence
```bash
# Instagram profile analysis
instaloader --login=youruser profile targetuser

# Check email across platforms
holehe target@email.com
```

### Phase 3: Email Intelligence
```bash
# Email breach checking
h8mail -t target@email.com

# Find emails associated with domain
theHarvester -d target.com -b all -l 500
```

### Phase 4: Metadata Analysis
```bash
# Extract metadata from files
exiftool document.pdf > ~/pentest/target_DATE/recon/metadata.txt

# Automated document metadata gathering
metagoofil -d target.com -t pdf,doc,xls -l 100 -o ~/pentest/target_DATE/recon/
```

### Phase 5: Advanced Framework
```bash
# Use recon-ng for comprehensive reconnaissance
recon-ng
# Inside recon-ng:
# marketplace install all
# workspaces create target_company
# modules load recon/domains-hosts/hackertarget
# options set SOURCE target.com
# run
```

## OSINT Best Practices

### Legal & Ethical
- ✅ Only gather publicly available information
- ✅ Respect terms of service
- ✅ Have authorization for your engagement
- ⛔ Don't use credentials found in breaches to access accounts
- ⛔ Don't harass or stalk individuals
- ⛔ Don't use OSINT for illegal purposes

### Operational Security
- Use VPN for anonymity
- Don't use personal accounts
- Create burner accounts for registration
- Use Tor for sensitive OSINT
- Clear metadata from your own files

### Data Organization
Always save to structured directories:
```
~/pentest/target_DATE/
├── recon/
│   ├── emails/
│   ├── subdomains/
│   ├── usernames/
│   ├── social/
│   ├── metadata/
│   └── OSINT_REPORT.md
```

### API Key Management

Some tools require API keys for full functionality. Add these to your `.env` file:

```bash
# Shodan (internet device search)
# Get key: https://account.shodan.io/
SHODAN_API_KEY=your_key_here

# Censys (internet-wide scanning data)
# Get keys: https://search.censys.io/account/api
CENSYS_API_ID=your_id_here
CENSYS_API_SECRET=your_secret_here

# Have I Been Pwned (breach checking)
# Get key: https://haveibeenpwned.com/API/Key
HIBP_API_KEY=your_key_here
```

After adding keys, restart the container: `make restart`

## Example Workflows

### Complete Domain OSINT
```bash
# Ask Claude:
"Run complete OSINT on example.com"

# Claude will:
1. Create workspace: ~/pentest/example.com_DATE/
2. Run theHarvester for emails and subdomains
3. Run sublist3r for additional subdomains
4. Gather WHOIS data
5. Check Shodan/Censys (if API keys set)
6. Generate OSINT_REPORT.md with findings
```

### Person OSINT
```bash
"Find information about username 'johndoe123'"

# Claude will:
1. Search with Sherlock across social networks
2. Check email patterns if email known
3. Search for metadata in public documents
4. Compile findings in organized report
```

### Company OSINT
```bash
"Gather OSINT on Company Inc."

# Claude will:
1. Domain reconnaissance
2. Email pattern discovery
3. Employee enumeration (LinkedIn, public sources)
4. Technology stack identification
5. Subdomain and IP discovery
6. Social media presence mapping
```

## Integration with Pentesting

OSINT is Phase 1 of pentesting:
1. **OSINT** → Information gathering (passive)
2. **Active Scanning** → nmap, vulnerability scanners
3. **Exploitation** → Based on discovered assets
4. **Reporting** → Include OSINT in reconnaissance section

## Resources

- OSINT Framework: https://osintframework.com/
- Awesome OSINT: https://github.com/jivoi/awesome-osint
- OSINT Techniques: https://www.osinttechniques.com/

---

**Remember**: OSINT is about clever searching and correlation, not hacking. Stay legal and ethical!
