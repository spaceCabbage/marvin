# Marvin


A containerized Linux environment that gives Claude Code full system access with security, pentesting, research and OSINT tools.


## Quick Start

```bash
git clone https://github.com/spaceCabbage/marvin.git
cd marvin
make setup      # Creates .env and builds image
make up         # Start container
make claude     # Launch Claude (auto-prompts login on first run)
```


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

## How it Works

Marvin runs Claude Code inside a Docker container loaded with security research tools. Everything you do persists between sessions - your files, settings, and Claude's memory of you all stay put when you restart.

### What Claude Can Do

Marvin comes with built-in **skills** that guide Claude through complex workflows:

- **OSINT Investigations** - Hunt down usernames across 2000+ sites, find email addresses, check data breaches, dig through public records, and piece together digital footprints
- **Penetration Testing** - Network scanning, web app testing, vulnerability assessment, and exploitation (with your permission)
- **Professional Reports** - Every investigation ends with 3 deliverables: a full technical report, a dark-themed PDF, and a quick summary you can paste into chat apps

### Where Your Work Lives

All your investigations get organized under `~/engagements/`:

```
~/engagements/
└── acme-corp/                      # Client folder
    └── osint_2026-01-21/           # Investigation (type + date)
        ├── report/                 # Your deliverables
        │   ├── OSINT_REPORT.md     # Full technical writeup
        │   ├── OSINT_REPORT.pdf    # Dark Gruvbox-themed PDF
        │   └── SUMMARY.txt         # Quick share version
        ├── raw/                    # Tool outputs (maigret, domains, etc.)
        └── evidence/               # Screenshots and proof
```

Start a new investigation for the same client? Claude creates a new dated folder automatically.

### How Claude Remembers You

Tell Claude your name, email, or preferences once - it saves them to the **Memory MCP** knowledge graph and remembers across sessions.

Your Claude auth, shell config, and all settings persist in the workspace, so you only need to log in once.


## Documentation

- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) - Deployment scenarios
- [docs/MCP-SERVERS.md](docs/MCP-SERVERS.md) - MCP configuration
- [docs/CONFIGURATION.md](docs/CONFIGURATION.md) - Configuration options

