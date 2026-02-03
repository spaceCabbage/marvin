# MCP Servers Documentation

Complete guide to Model Context Protocol (MCP) servers in Marvin.

## What are MCP Servers?

MCP (Model Context Protocol) servers provide Claude Code with access to external tools and services. They enable Claude to:
- Persist memory across sessions
- Break down complex problems
- Query databases
- Browse the web with a real browser
- Look up library documentation
- And much more

## Pre-installed MCP Servers

Marvin includes these MCP servers pre-configured:

### Memory (`memory`)

**Status**: ✅ Enabled by default
**Package**: `@modelcontextprotocol/server-memory`
**Purpose**: Persistent knowledge graph for remembering information across sessions

**CRITICAL**: This is Marvin's primary storage for user preferences, installed tools, and session history.

**Capabilities**:
- Create entities (users, tools, configs)
- Add observations to entities
- Search knowledge graph
- Persist across container restarts

**Configuration**:
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-memory"]
}
```

**Usage Example**:
```
# Create user profile
memory.create_entities([{name: "user_profile", entityType: "user", observations: ["name: John"]}])

# Add observations
memory.add_observations([{entityName: "user_profile", contents: ["prefers: dark theme"]}])

# Search
memory.search_nodes("user preferences")
```

### Sequential Thinking (`sequential-thinking`)

**Status**: ✅ Enabled by default
**Package**: `@modelcontextprotocol/server-sequential-thinking`
**Purpose**: Break down complex problems into structured reasoning steps

**Capabilities**:
- Problem decomposition
- Step-by-step reasoning
- Thought branching and revision
- Complex task planning

**Configuration**:
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
}
```

**Usage Example**:
```
User: "Plan a penetration test for example.com"
Claude: [Uses sequential-thinking to break down into phases: recon, scanning, enumeration, exploitation, reporting]
```

### SQLite (`sqlite`)

**Status**: ✅ Enabled by default
**Package**: `@berthojoris/mcp-sqlite-server`
**Purpose**: Local SQLite database for structured data storage

**Capabilities**:
- Create/modify tables
- Run SQL queries
- Store and retrieve data
- Database at `~/data.db`

**Configuration**:
```json
{
  "command": "npx",
  "args": ["-y", "@berthojoris/mcp-sqlite-server", "/workspace/data.db"]
}
```

**Usage Example**:
```
User: "Store this lead information in the database"
Claude: [Uses sqlite MCP to INSERT into companies table]
```

### Context7 (`context7`)

**Status**: ✅ Enabled by default
**Package**: `@upstash/context7-mcp`
**Purpose**: Query documentation for programming libraries

**Capabilities**:
- Search library documentation
- Find code examples
- Get API references
- Best practices

**Configuration**:
```json
{
  "command": "npx",
  "args": ["-y", "@upstash/context7-mcp"]
}
```

**Usage Example**:
```
User: "How do I use React hooks?"
Claude: [Uses Context7 to query React documentation]
```

### Playwright (`playwright`)

**Status**: ✅ Enabled by default
**Package**: `@playwright/mcp`
**Purpose**: Browser automation for web scraping and testing

**Capabilities**:
- Navigate to URLs
- Take screenshots
- Fill forms
- Click elements
- Execute JavaScript
- Extract data
- Headless Chromium browser

**Configuration**:
```json
{
  "command": "npx",
  "args": ["-y", "@playwright/mcp@latest"]
}
```

**Usage Example**:
```
User: "Scrape the company website for contact info"
Claude: [Uses Playwright MCP to navigate and extract data]
```

### HubSpot (`hubspot`)

**Status**: ⚠️ Disabled by default
**Package**: `@hubspot/mcp-server`
**Enable**: Set `HUBSPOT_ACCESS_TOKEN` in `.env`

**Purpose**: CRM integration for pushing qualified leads

**Capabilities**:
- Create companies
- Create contacts
- Add notes
- Associate records

**Configuration**:
```json
{
  "command": "npx",
  "args": ["-y", "@hubspot/mcp-server"],
  "env": {
    "HUBSPOT_ACCESS_TOKEN": "${HUBSPOT_ACCESS_TOKEN}"
  }
}
```

**Enable Steps**:
1. Go to https://developers.hubspot.com/docs/api/private-apps
2. Create a private app with CRM scopes
3. Add to `.env`: `HUBSPOT_ACCESS_TOKEN=pat-na1-xxxxx`
4. Run `make restart`

## Built-in Claude Code Tools (No MCP Needed)

These capabilities are built into Claude Code - no MCP server required:

| Capability     | Tool           | Notes                  |
|----------------|----------------|------------------------|
| Read files     | `Read`         | Built-in file reader   |
| Write files    | `Write`        | Built-in file writer   |
| Edit files     | `Edit`         | Built-in editor        |
| Web fetch      | `WebFetch`     | Fetch web content      |
| Web search     | `WebSearch`    | Search the web         |
| Run commands   | `Bash`         | Execute shell commands |
| Git operations | `git` via Bash | Use git CLI directly   |

## Adding Custom MCP Servers

Edit `workspace/.mcp.json`:

```json
{
  "mcpServers": {
    "my-custom-server": {
      "command": "npx",
      "args": ["-y", "@username/my-mcp-server"],
      "env": {
        "API_KEY": "${MY_API_KEY}"
      },
      "disabled": false
    }
  }
}
```

Add required environment variables to `.env`:
```bash
MY_API_KEY=your-key-here
```

Restart Marvin:
```bash
make restart
```

## MCP Server Troubleshooting

### Check MCP Status

```bash
# Launch Claude
make claude

# Ask Claude
"What MCP servers are available?"
```

### Test Individual Server

```bash
make shell

# Test memory MCP
npx -y @modelcontextprotocol/server-memory

# Test sequential-thinking MCP
npx -y @modelcontextprotocol/server-sequential-thinking

# Test sqlite MCP
npx -y @berthojoris/mcp-sqlite-server /workspace/data.db

# Test context7 MCP
npx -y @upstash/context7-mcp

# Test playwright MCP
npx -y @playwright/mcp
```

### Common Issues

**"MCP server not found"**
```bash
# Ensure npx is available
docker compose exec marvin-vm npx --version

# Reinstall if needed
make build
```

**"Environment variable not set"**
```bash
# Check .env file
cat .env | grep YOUR_VAR

# Restart after editing .env
make restart
```

## MCP Best Practices

### When to Use MCPs vs Built-ins

| Task                | Use                      | Why                                   |
|---------------------|--------------------------|---------------------------------------|
| Persist information | Memory MCP               | Survives restarts, structured storage |
| Complex planning    | Sequential-thinking MCP  | Better reasoning structure            |
| Database storage    | SQLite MCP               | Structured queries, relationships     |
| Library docs        | Context7 MCP             | Up-to-date docs, code examples        |
| Web scraping        | Playwright MCP           | Real browser, JavaScript execution    |
| Simple file ops     | Built-in Read/Write/Edit | Faster, simpler                       |
| Web content         | Built-in WebFetch        | Sufficient for most cases             |
| Git commands        | Built-in Bash            | git CLI works fine                    |

### Security

1. **API Keys**: Never commit API keys to git
2. **Scopes**: Use minimal required permissions for tokens
3. **Environment**: Keep sensitive data in `.env` (gitignored)

## Resources

- [Official MCP Servers](https://github.com/modelcontextprotocol/servers)
- [MCP Registry](https://registry.modelcontextprotocol.io/)
- [Awesome MCP Servers](https://github.com/wong2/awesome-mcp-servers)
- [MCP Server Directory](https://mcpservers.org/)

---

For issues or questions about MCP servers, see [GitHub Issues](https://github.com/spaceCabbage/Marvin/issues).
