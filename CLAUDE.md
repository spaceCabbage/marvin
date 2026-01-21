# Marvin Development Instructions

You are working on the **Marvin project** - a containerized Claude Code environment for security research.

## IMPORTANT: Two CLAUDE.md Files

This project has **TWO** CLAUDE.md files with different purposes:

| File                     | Purpose                               | Audience                               |
|--------------------------|---------------------------------------|----------------------------------------|
| `/CLAUDE.md` (this file) | Developing the Marvin project         | You (the developer's Claude)           |
| `/workspace/CLAUDE.md`   | Instructions for the containerized AI | The user's Claude inside the container |

**DO NOT confuse them.** When making changes:
- Changes to container behavior → edit `workspace/CLAUDE.md`
- Changes to project development → edit this file

## Project Structure

```
Marvin/
├── CLAUDE.md              # THIS FILE - for developing Marvin
├── workspace/             # Gets mounted as /workspace in container
│   ├── CLAUDE.md          # Instructions for the USER's Claude
│   ├── .claude/           # Claude Code config for container
│   │   ├── skills/        # OSINT, pentest, report-output skills
│   │   ├── templates/     # PDF themes (gruvbox-dark.css)
│   │   ├── settings.json
│   │   └── mcp-servers.json
│   └── .bashrc            # Shell config for container
├── docker/                # Docker configuration
│   ├── Dockerfile
│   └── docker-compose*.yml
├── scripts/               # Setup and utility scripts
├── docs/                  # Documentation
├── config/                # Caddy config for VPS deployment
└── .env                   # Environment variables (gitignored)
```

## Key Concepts

### User-Facing vs Development

| What                    | Where                                | Notes                       |
|-------------------------|--------------------------------------|-----------------------------|
| Skills (OSINT, pentest) | `workspace/.claude/skills/`          | User's Claude reads these   |
| PDF templates           | `workspace/.claude/templates/`       | Gruvbox dark theme          |
| Container tools         | `docker/Dockerfile`                  | What gets installed         |
| MCP servers             | `workspace/.claude/mcp-servers.json` | For container Claude        |
| User instructions       | `workspace/CLAUDE.md`                | Container Claude reads this |

### Engagement Structure

The container organizes work in:
```
~/engagements/[client]/[type]_[YYYY-MM-DD]/
├── report/          # 3 deliverables: MD, PDF, TXT
├── raw/             # Tool outputs by category
└── evidence/        # Screenshots
```

## Development Workflow

```bash
make setup      # Initial setup wizard
make build      # Build container
make up         # Start container
make claude     # Launch Claude inside container
make shell      # Bash shell in container
make logs       # View logs
make restart    # Restart after changes
```

## When Editing Skills

Skills are in `workspace/.claude/skills/`. Each skill has:
- `SKILL.md` - Instructions the container Claude follows
- Trigger conditions (when to activate)
- Tool references and workflows

**Key skills:**
- `osint/` - OSINT investigation (maigret, web search, public records)
- `pentest/` - Penetration testing workflow
- `report-output/` - 3 mandatory deliverables (MD, PDF, TXT)

## When Editing Container Setup

- **Add tools**: Edit `docker/Dockerfile`
- **Add MCP servers**: Edit `workspace/.claude/mcp-servers.json`
- **Change shell**: Edit `workspace/.bashrc`
- **Add env vars**: Document in `docs/CONFIGURATION.md`

## Testing Changes

1. Edit files in `workspace/` or `docker/`
2. Run `make build` if Dockerfile changed
3. Run `make restart` to pick up workspace changes
4. Run `make claude` to test

## Common Tasks

### Add a new skill
1. Create `workspace/.claude/skills/[name]/SKILL.md`
2. Document trigger conditions
3. Reference from other skills if needed

### Add a new tool to container
1. Add to `docker/Dockerfile` (apt, pip, or go install)
2. Update `workspace/CLAUDE.md` pre-installed tools list
3. Rebuild with `make build`

### Update user instructions
1. Edit `workspace/CLAUDE.md`
2. Changes take effect on next `make restart`

## Gitignore Notes

The `.gitignore` is configured to:
- Ignore `workspace/*` (user data)
- Ignore .env and credentials
- BUT keep
  - `workspace/CLAUDE.md`
  - `workspace/.bashrc`
  - `workspace/.claude/skills/**`
  - `workspace/.claude/templates/**`
  - `workspace/.claude/settings.json`
  - `workspace/.claude/mcp-servers.json`

This ensures skills and templates are tracked while user engagements are not.
