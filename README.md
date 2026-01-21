# ClaudeVM

**Multi-Platform Claude Code Security Research & Development Environment**

ClaudeVM is a containerized Linux environment that gives Claude Code full system access with security research tools, multi-platform support (x86_64/ARM64/RPi), and flexible deployment options.

## Quick Start

```bash
git clone https://github.com/spaceCabbage/claudevm.git
cd claudevm
make setup      # Creates .env and builds image
make up         # Start container
make claude     # Launch Claude (auto-prompts login on first run)
```

## Daily Usage

```bash
make up         # Start container
make claude     # Launch Claude Code
make shell      # Bash shell access
make down       # Stop container
```

## Features

- **Multi-Architecture**: Native x86_64 and ARM64 (Raspberry Pi)
- **WiFi Security**: USB adapter support with monitor mode (AWUS036ACS)
- **Security Tools**: nmap, masscan, sqlmap, Metasploit, aircrack-ng, and more
- **MCP Servers**: Filesystem, Git, Docker, Database, Browser automation
- **Persistent Memory**: Claude remembers your preferences across sessions
- **Proactive**: Claude searches for tools and suggests installations

## Commands

```bash
make help       # Show all commands
make setup      # First-time setup
make up         # Start container
make claude     # Launch Claude Code
make shell      # Bash shell access
make down       # Stop container
make logs       # Follow logs
make restart    # Restart container
make status     # Container status
make clean      # Remove containers/volumes
```

## Home Directory

Your home directory (`~` = `/workspace`) persists across sessions:
- `~/.bashrc` - Shell configuration
- `~/.claude/` - Claude Code settings
- `~/.claude-user-prefs` - Your preferences (Claude remembers you)
- `~/pentest/` - Organized pentest engagements
- `~/data.db` - SQLite database

Tell Claude your name, email, GitHub username - it saves them automatically.

## Platform Support

| Platform                 | Status       | Notes                |
|--------------------------|--------------|----------------------|
| x86_64 (Intel/AMD)       | Full Support | Best performance     |
| ARM64 (Raspberry Pi 4/5) | Full Support | WiFi adapter support |
| VPS (Cloud)              | Full Support | With domain/HTTPS    |

## Security Tools Included

- **OSINT**: theHarvester, Sherlock, maigret, bbot, recon-ng, SpiderFoot
- **Subdomain/Recon**: subfinder, amass, nuclei, httpx, dnsx
- **Network**: nmap, masscan, netcat, tcpdump
- **Web**: sqlmap, nikto, wpscan, sslscan, OWASP ZAP
- **Wireless**: aircrack-ng suite
- **Password**: john, hashcat, hydra
- **Exploitation**: Metasploit (optional)

## MCP Servers

- **Filesystem**: File operations
- **Git**: Repository management
- **Docker**: Container control
- **SQLite**: Local database (~/data.db)
- **GitHub**: PR/issue management (with token)
- **Context7**: Documentation querying
- **Playwright**: Browser automation

## VPS Deployment

```bash
make setup          # Configure domain
make build
make vps-up         # Starts with Caddy/HTTPS
```

## WiFi Security (RPi)

```bash
# Inside container, verify adapter
iwconfig wlan1

# Enable monitor mode
monitor-mode.sh wlan1
```

## Configuration

Edit `.env` for:
- `INSTALL_METASPLOIT`: true/false
- `WIFI_INTERFACE`: wlan1 (RPi)
- `GITHUB_TOKEN`: GitHub MCP server
- VPS domain settings

## Documentation

- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) - Deployment scenarios
- [docs/MCP-SERVERS.md](docs/MCP-SERVERS.md) - MCP configuration
- [docs/CONFIGURATION.md](docs/CONFIGURATION.md) - Configuration options

## Security Considerations

ClaudeVM runs with elevated privileges. Use on:
- Dedicated hardware
- Isolated VMs
- Test networks
