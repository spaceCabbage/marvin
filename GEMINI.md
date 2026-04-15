# Marvin Development Instructions

You are working on the **Marvin project** - a containerized Gemini CLI environment for security research.

## IMPORTANT: Two GEMINI.md Files

This project has **TWO** `GEMINI.md` files with different purposes:

| File                     | Purpose                               | Audience                               |
|--------------------------|---------------------------------------|----------------------------------------|
| `/GEMINI.md` (this file) | Developing the Marvin project         | You (the developer's Gemini)           |
| `/workspace/GEMINI.md`   | Instructions for the containerized AI | The user's Gemini inside the container |

**DO NOT confuse them.** When making changes:
- Changes to container behavior → edit `workspace/GEMINI.md`
- Changes to project development → edit this file

## Project Structure

```
Marvin/
├── GEMINI.md              # THIS FILE - for developing Marvin
├── workspace/             # Gets mounted as /workspace in container
│   ├── GEMINI.md          # Instructions for the USER's Gemini (Persona & Workflow)
│   ├── .gemini/           # Gemini CLI config for container
│   │   ├── skills/        # OSINT, pentest, lead-qual, etc.
│   │   ├── templates/     # PDF themes (gruvbox-dark.css)
│   │   └── settings.json  # MCP and UI settings (Default ports: 7681, 8080)
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

### Web Access (Defaults)

The environment provides two web-based entry points. **Use these host ports from your .env:**

| Service        | Host Port (Default) | Container Port | Purpose                         |
|----------------|---------------------|----------------|---------------------------------|
| **Terminal**   | `4488`              | `7681`         | Web UI for the Gemini CLI       |
| **File Browser**| `5599`              | `8080`         | Browse/download files from `/workspace` |

### User Instructions (Persona)

The persona of **Marvin** (depressed, brilliant robot) is deeply baked into `workspace/GEMINI.md` and the `settings.json` witty phrases. All investigations must follow the **3-deliverable rule** (MD, PDF, TXT).

## Development Workflow

```bash
make setup      # Initial setup (generates .env)
make build      # Build Docker image
make up         # Start container stack
make marvin     # Launch Gemini CLI inside container
make shell      # Bash shell in container
make doctor     # Diagnose system health and configuration
```

## When Editing Skills

Skills are in `workspace/.gemini/skills/`.
- Every `SKILL.md` must have a **YAML frontmatter** (name & description).
- Skills are designed for **parallel sub-agent orchestration**.
- Use the `save_memory` tool for ALL persistence.

## When Editing Container Setup

- **Add tools**: Edit `docker/Dockerfile`.
- **Add MCP servers**: Edit `workspace/.gemini/settings.json`.
- **Change shell**: Edit `workspace/.bashrc`.
- **Add env vars**: Update `.env.example` and `docker-compose.yml`.

## Gitignore Notes

The `.gitignore` keeps:
- `workspace/GEMINI.md`
- `workspace/.bashrc`
- `workspace/.gemini/skills/**`
- `workspace/.gemini/templates/**`
- `workspace/.gemini/settings.json`
- `GEMINI.md`
- `Makefile`
- `scripts/`
- `docker/`
- `docs/`
- `config/`
- `.env.example`
- `.gitignore`
- `README.md`
- `.vscode/`

It ignores:
- `.env`
- `workspace/*` (user data/engagements)
- `config/caddy/data/`
- `config/caddy/config/`
