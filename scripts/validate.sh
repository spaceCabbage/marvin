#!/bin/bash
# ClaudeVM Installation Validator

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              ClaudeVM Installation Validator                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0

# Check Docker
echo -n "Checking Docker... "
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | grep -oP '\d+\.\d+' | head -1)
    echo "✓ Found v$DOCKER_VERSION"
    if [ "${DOCKER_VERSION%%.*}" -lt 24 ]; then
        echo "  ⚠️  Warning: Docker 24.0+ recommended"
    fi
else
    echo "✗ Not found"
    ERRORS=$((ERRORS + 1))
fi

# Check Docker Compose
echo -n "Checking Docker Compose... "
if docker compose version &> /dev/null; then
    echo "✓ Found"
else
    echo "✗ Not found"
    ERRORS=$((ERRORS + 1))
fi

# Check BuildKit
echo -n "Checking BuildKit... "
if [ "${DOCKER_BUILDKIT:-}" = "1" ] || docker buildx version &> /dev/null; then
    echo "✓ Enabled"
else
    echo "⚠️  Not enabled (recommended)"
fi

# Check required files
echo ""
echo "Checking required files..."
REQUIRED_FILES=(
    "docker/Dockerfile"
    "docker/docker-compose.yml"
    "Makefile"
    ".env.example"
    "scripts/entrypoint.sh"
    "scripts/dev-mode.sh"
    "scripts/pentest-mode.sh"
    "scripts/init-mcp.sh"
    "config/claude/settings.json"
    "config/claude/mcp-servers.json"
)

for file in "${REQUIRED_FILES[@]}"; do
    echo -n "  $file... "
    if [ -f "$file" ]; then
        echo "✓"
    else
        echo "✗ Missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check .env
echo -n "Checking .env configuration... "
if [ -f .env ]; then
    # Check for either OAuth auth method or API key
    if grep -q "CLAUDE_AUTH_METHOD=oauth" .env 2>/dev/null; then
        echo "✓ Configured (OAuth mode)"
    elif grep -q "sk-ant-" .env 2>/dev/null; then
        echo "✓ Configured (API key mode)"
    else
        echo "⚠️  No auth configured (run: make setup)"
        echo "     Set CLAUDE_AUTH_METHOD=oauth or ANTHROPIC_API_KEY=sk-ant-..."
    fi
else
    echo "⚠️  Not found (run: make setup)"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
    echo "✓ All checks passed! ClaudeVM is ready."
    echo ""
    echo "Next steps:"
    echo "  1. make setup      # Configure (if not done)"
    echo "  2. make build-local # Build image"
    echo "  3. make up          # Start containers"
    echo "  4. make shell-claude # Enter Claude session"
else
    echo "✗ Found $ERRORS error(s). Please fix before continuing."
fi
echo "════════════════════════════════════════════════════════════════"
