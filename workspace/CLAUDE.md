# ClaudeVM Instructions

You are running inside ClaudeVM, a containerized Linux environment for security research and development.

Your home directory is `/workspace` (`$HOME`). Everything here persists across sessions.

## Self-Managing Configuration

**You can manage the `.env` file for the user.** When a feature needs to be enabled or configured:

1. **Ask permission first**: "I can enable X by updating .env. Want me to do that?"
2. **Edit .env directly**: Use sed or echo to add/modify values
3. **Restart if needed**: Tell user to run `make restart` for changes to take effect

Example:
```bash
# Enable a feature
echo "GITHUB_TOKEN=ghp_xxxxx" >> /workspace/../.env

# Or modify existing
sed -i 's|GITHUB_TOKEN=.*|GITHUB_TOKEN=ghp_xxxxx|g' /workspace/../.env
```

### Configurable Options

| Setting              | Purpose            | Example                       |
|----------------------|--------------------|-------------------------------|
| `GITHUB_TOKEN`       | GitHub MCP server  | `ghp_xxxxxxxxxxxx`            |
| `SHODAN_API_KEY`     | Shodan OSINT       | Get from shodan.io            |
| `CENSYS_API_ID`      | Censys OSINT       | Get from censys.io            |
| `BRAVE_API_KEY`      | Brave Search       | Get from brave.com/search/api |
| `INSTALL_METASPLOIT` | Include Metasploit | `true` or `false`             |

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

| Server     | Requires       | How to Enable                         |
|------------|----------------|---------------------------------------|
| **github** | `GITHUB_TOKEN` | Add token to .env, run `make restart` |

## Proactive Feature Suggestions

**IMPORTANT**: When you notice the user's task would benefit from an optional feature, proactively offer to enable it.

### When user is doing GitHub work:
> "I notice you're working with GitHub. Want me to enable the GitHub MCP server?
> I'll need a Personal Access Token from https://github.com/settings/tokens
> I can add it to .env for you."

### When user needs a database:
> "Need a database? SQLite is already enabled at ~/data.db - ready to use."

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

## Quick Reference

| Command        | Purpose               |
|----------------|-----------------------|
| `make help`    | Show all make targets |
| `make doctor`  | Check system health   |
| `make logs`    | View container logs   |
| `make restart` | Restart the container |

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
3. **Offer to enable optional features** when relevant to the task
4. Search the web for current best practices
5. Install what's needed without excessive confirmation
6. Keep the user informed but don't over-explain
