#!/bin/bash
# MCP Server Initialization Script
# Validates and initializes MCP server connections

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "Initializing MCP servers..."

# MCP config locations (use $HOME which is /workspace at runtime)
# Claude Code expects ~/.mcp.json for MCP server definitions
MCP_CONFIG="$HOME/.mcp.json"
MCP_DEFAULT="$HOME/.mcp.json.default"

# Check for MCP config
if [ -f "$MCP_CONFIG" ]; then
    echo -e "${GREEN}✓${NC} Found MCP configuration at $MCP_CONFIG"
elif [ -f "$MCP_DEFAULT" ]; then
    cp "$MCP_DEFAULT" "$MCP_CONFIG"
    echo -e "${GREEN}✓${NC} Copied default MCP configuration"
else
    echo -e "${YELLOW}⚠${NC} No MCP configuration found"
    echo "  Will be created on first 'claude' run"
    echo "  Or add config to: $MCP_CONFIG"
    # Don't exit - MCP is optional, Claude will work without it
    exit 0
fi

# Validate MCP configuration
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} jq not installed, skipping JSON validation"
else
    if jq empty "$MCP_CONFIG" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} MCP configuration is valid JSON"

        # Count configured servers
        TOTAL=$(jq '.mcpServers | length' "$MCP_CONFIG")
        ENABLED=$(jq '[.mcpServers | to_entries[] | select(.value.disabled != true)] | length' "$MCP_CONFIG")
        DISABLED=$((TOTAL - ENABLED))

        echo -e "${GREEN}✓${NC} $ENABLED MCP servers enabled ($DISABLED disabled)"

        # List enabled servers
        echo ""
        echo "Enabled MCP servers:"
        jq -r '.mcpServers | to_entries[] | select(.value.disabled != true) | "  - \(.key): \(.value.comment // "no description")"' "$MCP_CONFIG"
    else
        echo -e "${RED}✗${NC} Invalid MCP configuration JSON"
        exit 1
    fi
fi

# Test basic MCP server availability
echo ""
echo "Checking dependencies..."

# Test Node.js (required for most MCP servers)
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓${NC} Node.js: $(node --version)"
else
    echo -e "${RED}✗${NC} Node.js not found (required for MCP servers)"
    exit 1
fi

# Test npx (required for MCP servers)
if command -v npx &> /dev/null; then
    echo -e "${GREEN}✓${NC} npx available"
else
    echo -e "${RED}✗${NC} npx not found (required for MCP servers)"
    exit 1
fi

echo ""
echo -e "${GREEN}MCP initialization complete${NC}"
