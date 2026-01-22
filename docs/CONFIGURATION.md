# Marvin Configuration Guide

## Quick Start

After `make setup`, Marvin works immediately with **5 MCP servers** enabled.
No API keys required. No configuration needed.

## MCP Servers

### Enabled by Default (5 servers)

| Server              | What It Does                                |
|---------------------|---------------------------------------------|
| memory              | Persistent knowledge graph between sessions |
| sequential-thinking | Break down complex problems step-by-step    |
| sqlite              | Local database at ~/data.db                 |
| context7            | Look up library/framework documentation     |
| playwright          | Browser automation (headless Chromium)      |

**Built-in Claude Code tools (no MCP needed):**
- Read/Write/Edit - File operations
- WebFetch/WebSearch - Web content and search
- Bash - Git CLI, system commands

### Optional

HubSpot MCP server can be enabled for CRM integration. See [MCP-SERVERS.md](MCP-SERVERS.md) for details.

## Environment Variables

### Authentication

| Variable             | Default | Description                        |
|----------------------|---------|------------------------------------|
| `CLAUDE_AUTH_METHOD` | `oauth` | `oauth` (recommended) or `api_key` |
| `ANTHROPIC_API_KEY`  | -       | Only if using api_key method       |

### Optional Features

| Variable             | Default | Description               |
|----------------------|---------|---------------------------|
| `INSTALL_METASPLOIT` | `false` | Install Metasploit (~1GB) |

### API Keys

| Variable               | Required For | Where to Get                             |
|------------------------|--------------|------------------------------------------|
| `HUBSPOT_ACCESS_TOKEN` | HubSpot CRM  | https://developers.hubspot.com/docs/api/ |
| `SHODAN_API_KEY`       | Shodan OSINT | https://account.shodan.io/               |
| `CENSYS_API_ID`        | Censys OSINT | https://search.censys.io/account         |
| `BRAVE_API_KEY`        | Brave Search | https://brave.com/search/api/            |

### Resources

| Variable       | Default | Description  |
|----------------|---------|--------------|
| `CPU_LIMIT`    | `2.0`   | CPU cores    |
| `MEMORY_LIMIT` | `4g`    | Memory limit |
| `TZ`           | `UTC`   | Timezone     |

## Self-Managing Configuration

Claude can manage `.env` for you! When you need to enable a feature or add an API key, just ask Claude and it will:

1. Ask for your permission
2. Update `.env` with the new value
3. Tell you to run `make restart`

## What Claude Needs From You

**For full functionality**: Nothing! 5 MCP servers work immediately.

**Optional enhancements**:
- HubSpot token → if you want CRM integration
- OSINT API keys → if you want Shodan/Censys integration

**Authentication**: Claude uses OAuth (your Claude Pro/Max subscription).
Run `make claude` - it will auto-prompt for login if needed.
