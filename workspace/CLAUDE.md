# ClaudeVM Instructions

You are running inside ClaudeVM, a containerized Linux environment for security research and development.

Your home directory is `/workspace` (`$HOME`). Everything here persists across sessions.

## User Preferences

**IMPORTANT**: You have a persistent user preferences file at `~/.claude-user-prefs`. You should:

1. **Read it at the start of each session** to remember the user
2. **Eagerly save new information** - whenever the user mentions their name, email, GitHub username, preferred tools, timezone, or any personal preferences, immediately update the file
3. **Ask proactively** - if you don't know the user's name or key preferences, ask and save them

Example of updating preferences:
```bash
# Add a new preference
echo "github: username" >> ~/.claude-user-prefs

# Or use sed to update existing
sed -i 's|name:.*|name: Actual Name|g' ~/.claude-user-prefs
```

## MCP Servers Available

### Enabled by Default (10 servers)

| Server                  | Purpose            | Usage                              |
|-------------------------|--------------------|------------------------------------|
| **filesystem**          | File operations    | Read/write files in ~              |
| **git**                 | Git operations     | Commit, branch, diff, log          |
| **docker**              | Container mgmt     | Run containers, manage images      |
| **memory**              | Knowledge graph    | Remember info across sessions      |
| **fetch**               | Web fetching       | Retrieve web content               |
| **time**                | Time utilities     | Current time, timezone conversions |
| **sequential-thinking** | Reasoning          | Break down complex problems        |
| **sqlite**              | Local database     | Query/store data at ~/data.db      |
| **context7**            | Documentation      | Look up library/API docs           |
| **playwright**          | Browser automation | Headless Chromium for web          |

**Note**: Claude also has built-in WebSearch - no MCP server needed for web searches.

### Optional Servers (disabled by default)

| Server       | Requires               | How to Enable                         |
|--------------|------------------------|---------------------------------------|
| **github**   | `GITHUB_TOKEN`         | Add token to .env, run `make restart` |
| **postgres** | `ENABLE_POSTGRES=true` | Set in .env, run `make restart`       |

## Proactive Feature Suggestions

**IMPORTANT**: When you notice the user's task would benefit from an optional feature, proactively suggest enabling it.

### When user is doing GitHub work:
> "I notice you're working with GitHub. Want me to help you enable the GitHub MCP server?
> 1. Get a Personal Access Token from https://github.com/settings/tokens
> 2. Add to .env: `GITHUB_TOKEN=ghp_xxxxx`
> 3. Run: `make restart`"

### When user needs database:
> "Need a database? You have two options:
> 1. **SQLite** (already enabled): Use ~/data.db
> 2. **PostgreSQL**: Set `ENABLE_POSTGRES=true` in .env"

## Web Search & Tool Suggestions

**Always use web search** when you need to:
- Find the latest version of a tool
- Look up documentation
- Research vulnerabilities or CVEs
- Find new tools for a specific task

**Proactively suggest tools** - when the user wants to do something, search for the best current tools and offer to install them.

## Installing Tools

You have full sudo access. Install tools freely:
```bash
# Apt packages
sudo apt update && sudo apt install -y <package>

# Python tools
pip install <package>

# Go tools
go install github.com/org/tool@latest

# From GitHub
git clone https://github.com/org/tool && cd tool && make install
```

## Current Mode

Check `$CLAUDE_MODE` environment variable:
- **pentest**: Security research mode - organize work in `~/pentest/`
- **dev**: Development mode - help build and improve ClaudeVM itself

## Quick Reference

| Command        | Purpose                    |
|----------------|----------------------------|
| `make help`    | Show all make targets      |
| `make doctor`  | Check system health        |
| `make mode`    | Toggle between dev/pentest |
| `make logs`    | View container logs        |
| `make restart` | Restart the container      |

## Home Directory

Your home directory (`~` or `/workspace`) persists across sessions:
- `~/.claude-user-prefs` - Your preferences file
- `~/.claude-session-log` - Session activity log
- `~/data.db` - SQLite database (created on first use)
- `~/pentest/` - Organized pentest engagements
- `~/.bashrc` - Shell configuration
- `~/.claude/` - Claude Code configuration

## Be Proactive

1. Save user info to preferences eagerly
2. Suggest tools before the user asks
3. **Suggest enabling optional features** when relevant to the task
4. Search the web for current best practices
5. Install what's needed without excessive confirmation
6. Keep the user informed but don't over-explain
