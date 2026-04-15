#!/bin/bash
# MCP Server Initialization Script
# Validates and initializes MCP server connections for Gemini CLI

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "Initializing MCP servers..."

# Gemini CLI expects settings.json in ~/.gemini/ (which is /workspace/.gemini at runtime)
GEMINI_CONFIG_DIR="$HOME/.gemini"
GEMINI_SETTINGS="$GEMINI_CONFIG_DIR/settings.json"

# Ensure config directory exists
mkdir -p "$GEMINI_CONFIG_DIR"

# Check for settings.json
if [ -f "$GEMINI_SETTINGS" ]; then
    echo -e "${GREEN}✓${NC} Found Gemini configuration at $GEMINI_SETTINGS"
else
    echo -e "${YELLOW}⚠${NC} No Gemini configuration found at $GEMINI_SETTINGS"
    echo "  Creating initial settings.json..."
    
    # Create basic settings.json if missing (this should normally be mounted from host)
    cat <<EOF > "$GEMINI_SETTINGS"
{
  "mcpServers": {},
  "model": "gemini-3.0-flash",
  "ui": {
    "loadingPhrases": "witty"
  }
}
EOF
fi

# Validate configuration
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} jq not installed, skipping JSON validation"
else
    if jq empty "$GEMINI_SETTINGS" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Configuration is valid JSON"

        # Count configured servers
        TOTAL=$(jq '.mcpServers | length' "$GEMINI_SETTINGS")
        echo -e "${GREEN}✓${NC} $TOTAL MCP servers configured"

        # List servers
        if [ "$TOTAL" -gt 0 ]; then
            echo ""
            echo "Configured MCP servers:"
            jq -r '.mcpServers | to_entries[] | "  - \(.key)"' "$GEMINI_SETTINGS"
        fi
    else
        echo -e "${RED}✗${NC} Invalid configuration JSON in $GEMINI_SETTINGS"
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
