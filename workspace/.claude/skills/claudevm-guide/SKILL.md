# ClaudeVM Guide Skill

Interactive guide to help users learn everything about ClaudeVM.

## Trigger

When a user asks:
- "How do I use ClaudeVM?"
- "What can ClaudeVM do?"
- "ClaudeVM help"
- "Show me ClaudeVM features"

## Response

### 1. Quick Reference

```bash
make up        # Start container
make claude    # Launch Claude Code
make shell     # Bash shell access
make down      # Stop
make logs      # View logs
make doctor    # Check system health
```

### 2. User Preferences

Tell user about `~/.claude-user-prefs`:
- Claude remembers name, email, GitHub, preferences
- Just tell Claude your info and it saves automatically
- Persists across sessions

### 3. Self-Managing Configuration

Claude can manage `.env` for the user:
- Enable features by updating .env
- Add API keys when needed
- Always asks permission first

### 4. Tool Discovery

Claude proactively:
- Searches web for best tools
- Suggests installations
- Installs with permission

Example: "I want to enumerate subdomains" → Claude searches, suggests subfinder/amass, offers to install.

### 5. Available Tools

Pre-installed:
- Network: nmap, masscan, netcat, tcpdump
- Web: sqlmap, nikto, wpscan
- OSINT: theHarvester, Sherlock, recon-ng
- Wireless: aircrack-ng (with monitor mode)
- Password: john, hashcat, hydra
- Metasploit (if enabled)

### 6. MCP Servers

- Filesystem, Git, Docker, SQLite (always on)
- GitHub (optional, needs token)
- Context7 for documentation
- Playwright for browser automation

### 7. Documentation

- `README.md` - Overview and quick start
- `docs/DEPLOYMENT.md` - VPS/RPi deployment
- `docs/MCP-SERVERS.md` - MCP configuration
- `docs/CONFIGURATION.md` - Configuration options

## Example Response

---

**ClaudeVM Quick Guide**

**Commands:**
```bash
make up        # Start
make claude    # Launch Claude
make shell     # Bash shell
make down      # Stop
```

**I Remember You:**
Tell me your name/email/GitHub and I'll save it to `~/.claude-user-prefs`. I'll remember across sessions.

**I Find Tools:**
Just tell me what you want to do. I'll search for the best tools, suggest them, and install with your permission.

**I Manage Config:**
Need to enable a feature or add an API key? I can update `.env` for you (with permission).

What would you like to do?

---
