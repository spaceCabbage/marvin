# MCP Servers Documentation

Complete guide to Model Context Protocol (MCP) servers in ClaudeVM.

## What are MCP Servers?

MCP (Model Context Protocol) servers provide Claude Code with access to external tools and services. They enable Claude to:
- Read and write files
- Execute git commands  
- Control Docker containers
- Query databases
- Browse the web
- And much more

## Pre-installed MCP Servers

ClaudeVM includes these MCP servers pre-configured:

### Filesystem (`filesystem`)

**Status**: ✅ Enabled by default  
**Purpose**: Secure file operations within home directory (`~`)

**Capabilities**:
- Read files and directories
- Write new files
- Edit existing files  
- Delete files (with confirmation)
- Search files by pattern

**Configuration**:
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
}
```

**Usage Example**:
```
User: "Create a new Python script that prints hello world"
Claude: [Uses filesystem MCP to write hello.py]
```

### Git (`git`)

**Status**: ✅ Enabled by default  
**Purpose**: Git repository management

**Capabilities**:
- Check status
- View diffs
- Create commits
- Manage branches
- View history
- Push/pull (with confirmation)

**Configuration**:
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-git", "--repository", "/workspace"]
}
```

**Usage Example**:
```
User: "Show me what files have changed"
Claude: [Uses git MCP to run git status and git diff]
```

### Docker (`docker`)

**Status**: ✅ Enabled by default  
**Purpose**: Docker container and image management

**Capabilities**:
- List containers
- Start/stop containers
- View logs
- Inspect containers
- Manage images

**Configuration**:
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-docker"],
  "env": {
    "DOCKER_HOST": "unix:///var/run/docker.sock"
  }
}
```

**Usage Example**:
```
User: "What Docker containers are running?"
Claude: [Uses docker MCP to list running containers]
```

### GitHub (`github`)

**Status**: ⚠️ Disabled by default  
**Enable**: Set `GITHUB_TOKEN` in `.env`

**Purpose**: GitHub integration for PRs, issues, and repositories

**Capabilities**:
- Create/manage issues
- Review pull requests
- Manage repositories
- View commit history
- Search code

**Configuration**:
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
  }
}
```

**Enable Steps**:
```bash
# 1. Generate token at: https://github.com/settings/tokens
#    Required scopes: repo, read:org

# 2. Add to .env
GITHUB_TOKEN=ghp_your_token_here

# 3. Restart
make restart
```

**Usage Example**:
```
User: "Create an issue on my-repo about the login bug"
Claude: [Uses GitHub MCP to create issue]
```

### Brave Search (`brave-search`)

**Status**: ⚠️ Disabled by default  
**Enable**: Set `BRAVE_API_KEY` in `.env`

**Purpose**: Web search for research and reconnaissance

**Capabilities**:
- Web search
- News search
- Image search (results only)

**Configuration**:
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-brave-search"],
  "env": {
    "BRAVE_API_KEY": "${BRAVE_API_KEY}"
  }
}
```

**Enable Steps**:
```bash
# 1. Get API key: https://brave.com/search/api/

# 2. Add to .env
BRAVE_API_KEY=your_api_key

# 3. Restart
make restart
```

**Usage Example**:
```
User: "Search for recent CVEs affecting nginx"
Claude: [Uses Brave Search MCP to find recent security advisories]
```

### Playwright (`playwright`)

**Status**: ✅ Enabled by default
**Purpose**: Browser automation for web testing

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
  "args": ["-y", "@playwright/mcp"]
}
```

**Usage Example**:
```
User: "Take a screenshot of example.com"
Claude: [Uses Playwright MCP to navigate and capture screenshot]
```

### Context7 (`context7`)

**Status**: ✅ Enabled by default  
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
  "args": ["-y", "@context7/mcp-server"]
}
```

**Usage Example**:
```
User: "How do I use React hooks?"
Claude: [Uses Context7 to query React documentation]
```

## Adding Custom MCP Servers

### Method 1: Edit Configuration File

Edit `workspace/.claude/mcp-servers.json`:

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

Restart ClaudeVM:
```bash
make restart
```

### Method 2: Use Claude CLI (if available)

```bash
make shell
claude mcp add my-server --command "npx -y @username/my-server"
```

## Popular Community MCP Servers

### Atlassian (Jira/Confluence)

```bash
# In workspace/.claude/mcp-servers.json
{
  "atlassian": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-atlassian"],
    "env": {
      "ATLASSIAN_URL": "https://your-domain.atlassian.net",
      "ATLASSIAN_EMAIL": "your-email@example.com",
      "ATLASSIAN_API_TOKEN": "${ATLASSIAN_TOKEN}"
    }
  }
}
```

### Supabase

```bash
{
  "supabase": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-supabase"],
    "env": {
      "SUPABASE_URL": "${SUPABASE_URL}",
      "SUPABASE_KEY": "${SUPABASE_KEY}"
    }
  }
}
```

### Slack

```bash
{
  "slack": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-slack"],
    "env": {
      "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}",
      "SLACK_TEAM_ID": "${SLACK_TEAM_ID}"
    }
  }
}
```

## MCP Server Troubleshooting

### Check MCP Status

```bash
# Launch Claude
make claude

# Ask Claude
"What MCP servers are available?"
```

### Verify MCP Configuration

```bash
# Check JSON syntax
cat workspace/.claude/mcp-servers.json | jq

# Validate
make shell
jq empty workspace/.claude/mcp-servers.json && echo "Valid" || echo "Invalid"
```

### Test Individual Server

```bash
# Test filesystem MCP
make shell
npx -y @modelcontextprotocol/server-filesystem /workspace

# Should start without errors
```

### View MCP Logs

```bash
# View Claude Code logs (includes MCP activity)
make logs

# Look for MCP-related messages
docker compose logs claudevm-main | grep -i mcp
```

### Common Issues

**"MCP server not found"**
```bash
# Ensure npx is available
docker compose exec claudevm-main npx --version

# Ensure Node.js is installed
docker compose exec claudevm-main node --version

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

**"Permission denied"**
```bash
# Check Docker socket permissions
ls -la /var/run/docker.sock

# May need to be in docker group
groups
```

## MCP Best Practices

### Security

1. **API Keys**: Never commit API keys to git
2. **Scopes**: Use minimal required permissions for tokens
3. **Rotation**: Rotate API keys regularly
4. **Environment**: Keep sensitive data in `.env` (gitignored)

### Performance

1. **Disable Unused**: Disable MCP servers you don't need
2. **Timeout**: Adjust `mcp.timeout` in settings.json if needed
3. **Caching**: Some MCP servers cache results locally

### Organization

1. **Group by Purpose**: Organize servers logically in config
2. **Comment**: Add `"comment"` field to document usage
3. **Naming**: Use clear, descriptive names for custom servers

## MCP Server Development

Want to create your own MCP server? See:
- [MCP Documentation](https://modelcontextprotocol.io/)
- [MCP Specification](https://spec.modelcontextprotocol.io/)
- [Example MCP Servers](https://github.com/modelcontextprotocol/servers)

## Resources

- [Official MCP Servers](https://github.com/modelcontextprotocol/servers)
- [Awesome MCP Servers](https://github.com/wong2/awesome-mcp-servers)
- [MCP Server Directory](https://mcpservers.org/)
- [Claude Code MCP Guide](https://code.claude.com/docs/en/mcp)

---

For issues or questions about MCP servers, see [GitHub Issues](https://github.com/spaceCabbage/claudevm/issues).
