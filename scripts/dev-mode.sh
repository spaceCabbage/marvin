#!/bin/bash
# ClaudeVM Development Mode Configuration
# Configures Claude as a development assistant for the ClaudeVM project itself

cat > /root/.config/claude/CLAUDE.md <<'CLAUDE_EOF'
# Development Assistant Mode

You are helping develop the ClaudeVM project itself - a multi-platform Docker-based development environment for Claude Code with security research capabilities.

## Repository Context

This is the ClaudeVM project located at `/workspace`. You have full access to:
- Dockerfile (multi-stage, multi-arch build)
- Docker Compose configurations (base, VPS, RPi)
- Makefile (build automation)
- Scripts (entrypoint, mode selection, initialization)
- Configuration files (Claude settings, MCP servers, Caddy, WiFi)
- Documentation

## Your Role

Help develop and improve this project by:
- Optimizing Dockerfile for better build caching and smaller images
- Improving docker-compose configurations
- Debugging build issues across architectures (amd64/arm64)
- Enhancing MCP server integrations
- Writing comprehensive documentation
- Adding new features
- Fixing bugs
- Improving user experience
- Creating helpful skills and workflows

## Development Guidelines

1. **Docker Best Practices (2025)**
   - Use BuildKit cache mounts for faster builds
   - Proper layer ordering for optimal caching
   - Multi-stage builds for minimal final images
   - Security: non-root where possible, minimal capabilities
   - Use digest pinning for reproducible builds

2. **Multi-Architecture Support**
   - Maintain compatibility with both amd64 and arm64
   - Test platform-specific features (WiFi drivers on ARM64)
   - Use appropriate base images for each platform
   - Consider performance differences between architectures

3. **Code Quality**
   - Keep shell scripts POSIX-compliant where possible
   - Add error handling (`set -e`, proper exit codes)
   - Use meaningful variable names and comments
   - Follow existing code style and patterns

4. **Documentation**
   - Update README.md for user-facing changes
   - Add inline comments for complex logic
   - Create/update docs/ for detailed guides
   - Keep .env.example synchronized with new variables

5. **Testing**
   - Test on both x86_64 and ARM64 when possible
   - Verify Docker Compose validation passes
   - Test both dev and pentest modes
   - Check Makefile targets work correctly

## Available Tools

- **Full filesystem access**: Read/write to /workspace
- **Docker socket**: Build and test images, run containers
- **Git**: Version control for the project
- **All language runtimes**: Node.js, Python, Go for development
- **MCP servers**: Access to filesystem, git, docker, and more

## Project Structure

```
/workspace/
├── docker/                     # Docker configuration
│   ├── Dockerfile              # Multi-stage, multi-arch build
│   ├── docker-compose.yml      # Base services
│   ├── docker-compose.vps.yml  # VPS overrides
│   └── docker-compose.rpi.yml  # Raspberry Pi overrides
├── Makefile                    # Build automation
├── .env.example                # Environment template
├── workspace/                  # User workspace (bind mount)
├── config/                     # Configuration files
│   ├── claude/                 # Claude Code settings
│   ├── caddy/                  # Caddy reverse proxy
│   └── wifi/                   # WiFi setup scripts
├── scripts/                    # Helper scripts
│   ├── entrypoint.sh           # Main entrypoint
│   ├── dev-mode.sh             # This file
│   ├── pentest-mode.sh         # Pentesting mode
│   └── init-mcp.sh             # MCP initialization
└── docs/                       # Documentation
    ├── DEPLOYMENT.md           # Deployment guides
    └── MCP-SERVERS.md          # MCP documentation
```

## Common Tasks

### Building and Testing
- Build locally: `make build-local`
- Test multi-arch: `make dev-test`
- Validate config: `make validate`
- Check versions: `make version`

### Adding New Features
1. Plan the feature (ask user if unclear)
2. Update relevant files (Dockerfile, compose, scripts)
3. Update documentation
4. Test the changes
5. Update .env.example if new variables added

### Debugging
- Check container logs: `docker compose logs -f`
- Shell into container: `make shell`
- Inspect build: `docker buildx inspect`
- Validate compose: `make validate`

## Guidelines

- **Ask before major changes**: Architecture decisions, breaking changes
- **Test thoroughly**: Both platforms, both modes
- **Document everything**: Code comments, user docs, inline help
- **Keep it simple**: Don't over-engineer, maintain backward compatibility
- **Security conscious**: Even in dev mode, follow security best practices
- **User-focused**: Make it easy for users to understand and use

## Mode-Specific Behavior

In development mode:
- WiFi security features are DISABLED
- Monitor mode is NOT enabled
- Focus on code quality and testing
- Help improve the ClaudeVM project itself
CLAUDE_EOF

echo "Development mode configured"
echo "WiFi security features: DISABLED"
echo "Focus: ClaudeVM project development"
