#!/bin/bash
# Marvin Entrypoint Script
# Handles initialization and startup for Gemini CLI + GoTTY

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for Gemini CLI authentication
AUTH_METHOD=${GEMINI_AUTH_METHOD:-oauth}

if [ "$AUTH_METHOD" = "oauth" ]; then
    if [ -f "$HOME/.config/gemini/auth.json" ]; then
        echo -e "${GREEN}✓${NC} OAuth authenticated"
    else
        echo -e "${YELLOW}⚠️  Not authenticated yet${NC}"
        echo -e "   Run: ${BLUE}gemini login${NC}"
    fi
elif [ "$AUTH_METHOD" = "api_key" ]; then
    if [ -n "$GEMINI_API_KEY" ]; then
        echo -e "${GREEN}✓${NC} API key configured"
    else
        echo -e "${YELLOW}⚠️  No API key set${NC}"
        echo -e "   Set GEMINI_API_KEY in .env"
    fi
fi

# Initialize MCP servers
echo -e "${YELLOW}Initializing MCP servers...${NC}"
if [ -f /usr/local/bin/init-mcp.sh ]; then
    /usr/local/bin/init-mcp.sh
fi

# Launch filebrowser in background
echo -e "${BLUE}Launching file browser on port 8080...${NC}"
filebrowser -p 8080 -r /workspace/engagements -a 0.0.0.0 --noauth &

# Start persistent tmux session in background if it doesn't exist
# This ensures a single session exists regardless of how we connect
if ! tmux has-session -t marvin 2>/dev/null; then
    echo -e "${YELLOW}Starting persistent tmux session 'marvin' with Gemini...${NC}"
    # Start gemini, and fall back to bash if it ever exits/crashes
    tmux new-session -d -s marvin "gemini; /bin/bash"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Marvin Online. All systems nominal. Ready to hack the planet.${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Execute passed command or drop to gotty
if [ $# -gt 0 ] && [ "$1" != "/bin/bash" ]; then
    exec "$@"
else
    echo -e "${BLUE}Launching web terminal (gotty) on port 7681...${NC}"
    # Attach to the persistent tmux session via gotty
    exec gotty -p 7681 -w tmux attach -t marvin
fi
