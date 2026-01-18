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

# MCP config locations
MCP_CONFIG="/root/.claude/mcp-servers.json"
MCP_DEFAULT="/root/.claude/mcp-servers.json.default"

# If no config exists, copy from default (shipped with image)
if [ ! -f "$MCP_CONFIG" ]; then
    if [ -f "$MCP_DEFAULT" ]; then
        cp "$MCP_DEFAULT" "$MCP_CONFIG"
        echo -e "${GREEN}✓${NC} Copied default MCP configuration"
    elif [ -f "/root/.claude/mcp-servers.json" ]; then
        # Config already exists in .claude directory from Dockerfile
        MCP_CONFIG="/root/.claude/mcp-servers.json"
        echo -e "${GREEN}✓${NC} Using shipped MCP configuration"
    else
        echo -e "${RED}✗${NC} No MCP configuration found!"
        echo "  Expected at: $MCP_CONFIG or $MCP_DEFAULT"
        exit 1
    fi
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
