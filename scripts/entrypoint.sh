#!/bin/bash
# Marvin Entrypoint Script
# Handles initialization and startup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


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

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Marvin Online. All systems nominal. Ready to hack the planet.${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
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
