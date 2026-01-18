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
make up        # Start containers
make connect   # tmux session
make down      # Stop
make mode      # Toggle dev/pentest
make logs      # View logs
make login     # Re-authenticate
```

### 2. User Preferences

Tell user about `~/.claude-user-prefs`:
- Claude remembers name, email, GitHub, preferences
- Just tell Claude your info and it saves automatically
- Persists across sessions

### 3. Tool Discovery

Claude proactively:
- Searches web for best tools
- Suggests installations
- Installs with permission

Example: "I want to enumerate subdomains" → Claude searches, suggests subfinder/amass, offers to install.

### 4. Modes

Toggle with `make mode`:
- **pentest**: Security research, organized in `~/pentest/`
- **dev**: Development assistance

### 5. Available Tools

Pre-installed:
- Network: nmap, masscan, netcat, tcpdump
- Web: sqlmap, nikto, wpscan
- OSINT: theHarvester, Sherlock, recon-ng
- Wireless: aircrack-ng (with monitor mode)
- Password: john, hashcat, hydra
- Metasploit (if enabled)

### 6. MCP Servers

- Filesystem, Git, Docker (always on)
- PostgreSQL, GitHub, Brave Search (optional)
- Context7 for documentation

### 7. Documentation

- `README.md` - Overview
- `docs/QUICKSTART.md` - Get running fast
- `docs/DEPLOYMENT.md` - VPS/RPi deployment
- `docs/MCP-SERVERS.md` - MCP configuration

## Example Response

---

**ClaudeVM Quick Guide**

**Commands:**
```bash
make up        # Start
make connect   # Connect (tmux)
make down      # Stop
make mode      # Toggle mode
```

**I Remember You:**
Tell me your name/email/GitHub and I'll save it to `~/.claude-user-prefs`. I'll remember across sessions.

**I Find Tools:**
Just tell me what you want to do. I'll search for the best tools, suggest them, and install with your permission.

**Current Mode:** Check `$CLAUDE_MODE` - pentest or dev

What would you like to do?

---
