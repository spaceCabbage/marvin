# ClaudeVM Configuration Guide

## Quick Start

After `make setup`, ClaudeVM works immediately with **10 MCP servers** enabled.
No API keys required. No configuration needed.

## MCP Servers

### Enabled by Default (10 servers)

| Server              | What It Does                                |
|---------------------|---------------------------------------------|
| filesystem          | Read/write files in ~ (home directory)      |
| git                 | Git operations (commit, diff, branch, log)  |
| docker              | Manage containers via Docker socket         |
| memory              | Persistent knowledge graph between sessions |
| fetch               | Fetch web pages and content                 |
| time                | Get current time, convert timezones         |
| sequential-thinking | Break down complex problems step-by-step    |
| sqlite              | Local database at ~/data.db                 |
| context7            | Look up library/framework documentation     |
| playwright          | Browser automation (headless Chromium)      |

**Note**: Claude also has built-in WebSearch - no MCP server needed for web searches.

### Optional

#### GitHub MCP Server

Access GitHub repos, issues, PRs programmatically.

**Setup:**
1. Create a Personal Access Token at https://github.com/settings/tokens
2. Add to `.env`: `GITHUB_TOKEN=ghp_your_token_here`
3. Run: `make restart`

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

| Variable         | Required For | Where to Get                       |
|------------------|--------------|------------------------------------|
| `GITHUB_TOKEN`   | GitHub MCP   | https://github.com/settings/tokens |
| `SHODAN_API_KEY` | Shodan OSINT | https://account.shodan.io/         |
| `CENSYS_API_ID`  | Censys OSINT | https://search.censys.io/account   |
| `BRAVE_API_KEY`  | Brave Search | https://brave.com/search/api/      |

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

**For full functionality**: Nothing! 10 MCP servers work immediately.

**Optional enhancements**:
- GitHub token → if you want GitHub API integration
- OSINT API keys → if you want Shodan/Censys integration

**Authentication**: Claude uses OAuth (your Claude Pro/Max subscription).
Run `make claude` - it will auto-prompt for login if needed.
