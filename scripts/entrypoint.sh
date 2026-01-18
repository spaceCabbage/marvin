#!/bin/bash
# ClaudeVM Entrypoint Script
# Handles mode selection and initialization

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                      ClaudeVM Starting...                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get mode from environment
MODE=${CLAUDE_MODE:-pentest}
echo -e "${YELLOW}Mode:${NC} $MODE"

# Initialize user preferences file (Claude can read/write this)
USER_PREFS_FILE="$HOME/.claude-user-prefs"
if [ ! -f "$USER_PREFS_FILE" ]; then
    cat > "$USER_PREFS_FILE" << 'EOF'
# ClaudeVM User Preferences
# Claude can read and write to this file to remember your preferences.
# Add any personal info you want Claude to remember across sessions.

# Example:
# name: Your Name
# email: your@email.com
# github: yourusername
# preferred_editor: vim
# timezone: America/Chicago

EOF
    echo -e "${GREEN}✓${NC} Created user preferences file: $USER_PREFS_FILE"
else
    echo -e "${GREEN}✓${NC} User preferences loaded from: $USER_PREFS_FILE"
fi

# Check for Claude Code authentication
AUTH_METHOD=${CLAUDE_AUTH_METHOD:-oauth}

if [ "$AUTH_METHOD" = "oauth" ]; then
    if [ -f "$HOME/.config/claude/auth.json" ]; then
        echo -e "${GREEN}✓${NC} OAuth authenticated"
    else
        echo -e "${YELLOW}⚠️  Not authenticated yet${NC}"
        echo -e "   Run: ${BLUE}claude login${NC}"
        # Continue - don't exit
    fi
elif [ "$AUTH_METHOD" = "api_key" ]; then
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo -e "${GREEN}✓${NC} API key configured"
    else
        echo -e "${YELLOW}⚠️  No API key set${NC}"
        echo -e "   Set ANTHROPIC_API_KEY in .env"
        # Continue - don't exit
    fi
else
    echo -e "${YELLOW}⚠️  Unknown auth method: $AUTH_METHOD${NC}"
    echo -e "   Valid options: oauth, api_key"
    # Continue - don't exit
fi

# Initialize MCP servers
echo -e "${YELLOW}Initializing MCP servers...${NC}"
if [ -f /usr/local/bin/init-mcp.sh ]; then
    /usr/local/bin/init-mcp.sh
else
    echo -e "${YELLOW}⚠️  MCP initialization script not found, skipping${NC}"
fi

# Load mode-specific configuration
case "$MODE" in
    pentest)
        echo -e "${GREEN}Loading pentesting mode...${NC}"
        if [ -f /usr/local/bin/pentest-mode.sh ]; then
            /usr/local/bin/pentest-mode.sh
        else
            echo -e "${YELLOW}⚠️  Pentesting mode script not found, continuing${NC}"
        fi
        ;;
    dev)
        echo -e "${BLUE}Loading development mode...${NC}"
        if [ -f /usr/local/bin/dev-mode.sh ]; then
            /usr/local/bin/dev-mode.sh
        else
            echo -e "${YELLOW}⚠️  Development mode script not found, continuing${NC}"
        fi
        ;;
    *)
        echo -e "${YELLOW}⚠️  Unknown mode: $MODE, using defaults${NC}"
        ;;
esac

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                       ClaudeVM Ready!                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Quick commands:${NC}"
echo -e "  Start Claude: ${BLUE}claude${NC}"
echo -e "  Get help:     ${BLUE}claude --help${NC}"
echo -e "  Exit:         ${BLUE}exit${NC} or ${BLUE}Ctrl+D${NC}"
echo ""

# Execute passed command or drop to shell
if [ $# -gt 0 ]; then
    exec "$@"
else
    exec /bin/bash
fi
