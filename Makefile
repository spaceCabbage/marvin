# Marvin Makefile
# Intelligent build and deployment automation

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Platform detection
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),x86_64)
    DETECTED_PLATFORM := amd64
else ifeq ($(UNAME_M),aarch64)
    DETECTED_PLATFORM := arm64
else ifeq ($(UNAME_M),arm64)
    DETECTED_PLATFORM := arm64
else
    DETECTED_PLATFORM := unknown
endif

# Load .env if it exists
ifneq (,$(wildcard .env))
    include .env
    export
endif

# Default values if not defined in .env
TTYD_PORT ?= 4488
FILEBROWSER_PORT ?= 5599

# Default platform from .env or detected
PLATFORM ?= $(DETECTED_PLATFORM)

# Compose file selection
COMPOSE_FILES := -f docker/docker-compose.yml

# Automatically add platform-specific compose file
ifeq ($(PLATFORM),arm64)
    ifneq (,$(wildcard docker/docker-compose.rpi.yml))
        COMPOSE_FILES += -f docker/docker-compose.rpi.yml
        DEPLOYMENT_TYPE := RPi/ARM64
    endif
else ifeq ($(PLATFORM),amd64)
    DEPLOYMENT_TYPE := x86_64
endif

# VPS mode override (with Caddy/HTTPS)
ifdef VPS
    COMPOSE_FILES += -f docker/docker-compose.vps.yml
    DEPLOYMENT_TYPE := VPS
endif

# VPS simple mode (without Caddy, IP-based access)
ifdef VPS_SIMPLE
    COMPOSE_FILES += -f docker/docker-compose.vps-simple.yml
    DEPLOYMENT_TYPE := VPS-Simple
endif

# Docker Compose command
COMPOSE := docker compose $(COMPOSE_FILES)

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@echo -e "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo -e "$(BLUE)║              Marvin - Build & Deployment System             ║$(NC)"
	@echo -e "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo -e ""
	@echo -e "$(YELLOW)Detected Platform:$(NC) $(DETECTED_PLATFORM)"
	@echo -e "$(YELLOW)Current Platform:$(NC)  $(PLATFORM)"
	@echo -e "$(YELLOW)Deployment Type:$(NC)   $(DEPLOYMENT_TYPE)"
	@echo -e "$(YELLOW)Compose Files:$(NC)     $(COMPOSE_FILES)"
	@echo -e ""
	@echo -e "$(GREEN)Available targets:$(NC)"
	@echo -e ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[0;34m%-18s\033[0m %s\n", $$1, $$2}'
	@echo -e ""

# =============================================================================
# Core Workflow (run these in order for first-time setup)
# =============================================================================

.PHONY: setup
setup: ## First-time setup: generate .env, build, start, authenticate
	@echo -e "$(BLUE)╔══════════════════════════════════════╗$(NC)"
	@echo -e "$(BLUE)║         Marvin Setup               ║$(NC)"
	@echo -e "$(BLUE)╚══════════════════════════════════════╝$(NC)"
	@echo ""
	@if [ ! -f .env ]; then \
		cp .env.example .env && \
		echo -e "$(GREEN)✓$(NC) Created .env with defaults"; \
	else \
		echo -e "$(YELLOW)⚠$(NC) .env exists, keeping current config"; \
	fi
	@echo ""
	@echo -e "$(YELLOW)Building image (first time takes 10-15 min)...$(NC)"
	@$(MAKE) build
	@echo ""
	@echo -e "$(YELLOW)Starting container...$(NC)"
	@$(COMPOSE) up -d
	@echo ""
	@echo -e "$(GREEN)╔══════════════════════════════════════╗$(NC)"
	@echo -e "$(GREEN)║         Setup Complete!              ║$(NC)"
	@echo -e "$(GREEN)╚══════════════════════════════════════╝$(NC)"
	@echo ""
	@echo -e "  Web Terminal: $(BLUE)http://localhost:$(TTYD_PORT)$(NC)"
	@echo -e "  File Browser: $(BLUE)http://localhost:$(FILEBROWSER_PORT)$(NC)"
	@echo ""

.PHONY: build
build: ## Build Docker image for current platform
	@echo -e "$(BLUE)Building Marvin for $(PLATFORM)...$(NC)"
	docker build \
		--build-arg INSTALL_METASPLOIT=$(INSTALL_METASPLOIT) \
		-t marvin:latest \
		-f docker/Dockerfile \
		.
	@echo -e "$(GREEN)✓$(NC) Build complete"

.PHONY: build-clean
build-clean: ## Build Docker image without cache (fresh build)
	@echo -e "$(BLUE)Building Marvin from scratch (no cache)...$(NC)"
	@echo -e "$(YELLOW)This will take longer than a cached build$(NC)"
	docker build \
		--no-cache \
		--build-arg INSTALL_METASPLOIT=$(INSTALL_METASPLOIT) \
		-t marvin:latest \
		-f docker/Dockerfile \
		.
	@echo -e "$(GREEN)✓$(NC) Clean build complete"

.PHONY: up
up: ## Start containers in background
	@$(COMPOSE) up -d
	@echo -e "$(GREEN)✓$(NC) Marvin running"
	@echo -e "  Web Terminal: $(BLUE)http://localhost:$(TTYD_PORT)$(NC)"
	@echo -e "  File Browser: $(BLUE)http://localhost:$(FILEBROWSER_PORT)$(NC)"
	@echo -e "  Open shell:    $(BLUE)make shell$(NC)"

.PHONY: marvin
marvin: ## Attach to the single persistent Gemini session (tmux)
	@if ! docker info >/dev/null 2>&1; then \
		echo -e "$(RED)ERROR: Docker not running$(NC)"; \
		exit 1; \
	fi
	@if ! $(COMPOSE) ps | grep -q "marvin-vm.*Up"; then \
		echo -e "$(RED)ERROR: Marvin is not running$(NC)"; \
		echo -e "$(YELLOW)Start with:$(NC) make up"; \
		exit 1; \
	fi
	@# Ensure tmux session exists, create if missing (failsafe)
	@$(COMPOSE) exec marvin-vm bash -c "tmux has-session -t marvin 2>/dev/null || tmux new-session -d -s marvin"
	$(COMPOSE) exec marvin-vm tmux attach -t marvin

.PHONY: shell
shell: ## Open bash shell in Marvin
	@if ! docker info >/dev/null 2>&1; then \
		echo -e "$(RED)ERROR: Docker not running$(NC)"; \
		exit 1; \
	fi
	@if ! $(COMPOSE) ps | grep -q "marvin-vm.*Up"; then \
		echo -e "$(RED)ERROR: Marvin is not running$(NC)"; \
		echo -e "$(YELLOW)Start with:$(NC) make up"; \
		exit 1; \
	fi
	$(COMPOSE) exec marvin-vm bash

.PHONY: connect
connect: shell ## Alias for shell (backwards compat)

.PHONY: down
down: ## Stop containers
	@$(COMPOSE) down
	@echo -e "$(GREEN)✓$(NC) Marvin stopped"

.PHONY: logs
logs: ## Follow container logs
	@$(COMPOSE) logs -f

.PHONY: restart
restart: ## Restart containers
	make down && make up
	@echo -e "$(GREEN)✓$(NC) Restarted"

# =============================================================================
# Additional Commands
# =============================================================================

.PHONY: attach
attach: connect ## Alias for connect

.PHONY: login
login: ## Re-authenticate Gemini CLI (if needed)
	@echo -e "$(BLUE)Authenticating Gemini CLI...$(NC)"
	@echo -e "$(YELLOW)This will open a browser for OAuth login$(NC)"
	@echo ""
	$(COMPOSE) exec marvin-vm gemini login
	@echo ""
	@echo -e "$(GREEN)✓$(NC) Authentication complete!"

.PHONY: status
status: ## Show container status
	@$(COMPOSE) ps

.PHONY: install
install: ## Install 'marvin' command globally (~/.local/bin)
	@mkdir -p ~/.local/bin
	@chmod +x "$(CURDIR)/scripts/marvin"
	@ln -sf "$(CURDIR)/scripts/marvin" ~/.local/bin/marvin
	@echo -e "$(GREEN)✓$(NC) Installed 'marvin' to ~/.local/bin/"
	@if echo "$$PATH" | grep -q "$$HOME/.local/bin"; then \
		echo -e "  You can now run $(BLUE)marvin$(NC) from anywhere"; \
	else \
		echo -e "  $(YELLOW)Add ~/.local/bin to your PATH:$(NC)"; \
		echo -e "    echo 'export PATH=\"\$$HOME/.local/bin:\$$PATH\"' >> ~/.bashrc"; \
	fi

.PHONY: uninstall
uninstall: ## Remove 'marvin' command from ~/.local/bin
	@rm -f ~/.local/bin/marvin
	@echo -e "$(GREEN)✓$(NC) Removed 'marvin' from ~/.local/bin/"

# =============================================================================
# VPS Deployment
# =============================================================================

.PHONY: vps-simple-up
vps-simple-up: ## Start on VPS without domain (SSH tunnel access)
	@echo -e "$(BLUE)Starting Marvin for VPS (no domain)...$(NC)"
	@echo -e "$(YELLOW)Access via SSH tunnel:$(NC)"
	@echo -e "  ssh -L $(TTYD_PORT):localhost:$(TTYD_PORT) user@your-vps"
	@echo ""
	VPS_SIMPLE=1 $(COMPOSE) up -d
	@echo -e "$(GREEN)✓$(NC) Marvin running (VPS simple mode)"

.PHONY: vps-up
vps-up: ## Start on VPS with domain (Caddy/HTTPS)
	@echo -e "$(BLUE)Starting Marvin for VPS (with Caddy)...$(NC)"
	VPS=1 $(COMPOSE) up -d
	@echo -e "$(GREEN)✓$(NC) Marvin running (VPS mode)"

# =============================================================================
# Cleanup
# =============================================================================

.PHONY: clean
clean: ## Remove containers and volumes
	@$(COMPOSE) down -v
	@echo -e "$(GREEN)✓$(NC) Cleaned up containers and volumes"

.PHONY: clean-all
clean-all: clean ## Remove everything including images
	@docker rmi marvin:latest 2>/dev/null || true
	@echo -e "$(GREEN)✓$(NC) Removed Marvin image"

.PHONY: purge
purge: ## Reset to fresh clone state (DESTRUCTIVE - removes all data)
	@echo -e "$(RED)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo -e "$(RED)║                    ⚠️  WARNING: PURGE  ⚠️                        ║$(NC)"
	@echo -e "$(RED)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo -e "$(YELLOW)This will permanently delete:$(NC)"
	@echo -e "  • User data (engagements/, data.db, preferences)"
	@echo -e "  • Gemini auth (requires re-login)"
	@echo -e "  • Docker images and build cache"
	@echo -e "  • Your .env configuration"
	@echo -e ""
	@echo -e "$(GREEN)Preserved:$(NC) workspace/GEMINI.md, workspace/.gemini/ config"
	@echo ""
	@echo -e "$(RED)This cannot be undone!$(NC)"
	@echo ""
	@read -p "Type 'PURGE' to confirm: " confirm && \
	if [ "$$confirm" = "PURGE" ]; then \
		echo ""; \
		echo -e "$(YELLOW)Stopping containers...$(NC)"; \
		$(COMPOSE) down -v 2>/dev/null || true; \
		echo -e "$(YELLOW)Removing Docker image...$(NC)"; \
		docker rmi marvin:latest 2>/dev/null || true; \
		echo -e "$(YELLOW)Pruning build cache...$(NC)"; \
		docker builder prune -f 2>/dev/null || true; \
		echo -e "$(YELLOW)Removing user data (preserving config)...$(NC)"; \
		rm -rf workspace/pentest 2>/dev/null || true; \
		rm -f workspace/data.db 2>/dev/null || true; \
		rm -f workspace/.gemini-session-log 2>/dev/null || true; \
		echo -e "$(YELLOW)Removing Gemini auth (preserving MCP config)...$(NC)"; \
		rm -f workspace/.gemini/auth.json 2>/dev/null || true; \
		rm -rf workspace/.gemini/projects 2>/dev/null || true; \
		echo -e "$(YELLOW)Removing .env...$(NC)"; \
		rm -f .env 2>/dev/null || true; \
		echo ""; \
		echo -e "$(GREEN)╔══════════════════════════════════════╗$(NC)"; \
		echo -e "$(GREEN)║         Purge Complete!              ║$(NC)"; \
		echo -e "$(GREEN)╚══════════════════════════════════════╝$(NC)"; \
		echo ""; \
		echo -e "Run $(BLUE)make setup$(NC) to start fresh."; \
	else \
		echo ""; \
		echo -e "$(YELLOW)Purge cancelled.$(NC)"; \
	fi

# =============================================================================
# Diagnostics
# =============================================================================

.PHONY: doctor
doctor: ## Check system health and diagnose issues
	@echo -e "$(BLUE)╔══════════════════════════════════════╗$(NC)"
	@echo -e "$(BLUE)║       Marvin Diagnostics           ║$(NC)"
	@echo -e "$(BLUE)╚══════════════════════════════════════╝$(NC)"
	@echo ""
	@# Check Docker
	@echo -n "Docker daemon: "
	@docker info >/dev/null 2>&1 && echo -e "$(GREEN)✓ Running$(NC)" || echo -e "$(RED)✗ Not running$(NC)"
	@echo -n "Docker Compose: "
	@docker compose version >/dev/null 2>&1 && echo -e "$(GREEN)✓ $(shell docker compose version --short 2>/dev/null)$(NC)" || echo -e "$(RED)✗ Not found$(NC)"
	@# Check .env
	@echo -n ".env file: "
	@if [ -f .env ]; then echo -e "$(GREEN)✓ Present$(NC)"; else echo -e "$(YELLOW)⚠ Missing (run make setup)$(NC)"; fi
	@# Check image
	@echo -n "Docker image: "
	@if docker images marvin:latest --format "{{.ID}}" 2>/dev/null | grep -q .; then echo -e "$(GREEN)✓ Built$(NC)"; else echo -e "$(YELLOW)⚠ Not built (run make build)$(NC)"; fi
	@# Check container
	@echo -n "Container: "
	@if $(COMPOSE) ps 2>/dev/null | grep -q "marvin-vm.*Up"; then echo -e "$(GREEN)✓ Running$(NC)"; else echo -e "$(YELLOW)⚠ Not running (run make up)$(NC)"; fi
	@# Check auth (if container running)
	@echo -n "Gemini auth: "
	@if $(COMPOSE) exec -T marvin-vm test -f /root/.config/gemini/auth.json 2>/dev/null; then echo -e "$(GREEN)✓ Authenticated$(NC)"; else echo -e "$(YELLOW)⚠ Not authenticated (run make login)$(NC)"; fi
	@# Check settings config
	@echo -n "Gemini settings: "
	@if [ -f workspace/.gemini/settings.json ]; then \
		servers=$$(jq '.mcpServers | length' workspace/.gemini/settings.json 2>/dev/null || echo 0); \
		echo -e "$(GREEN)✓ $$servers MCP servers configured$(NC)"; \
	else \
		echo -e "$(YELLOW)⚠ Missing$(NC)"; \
	fi
	@echo ""
	@echo -e "$(BLUE)Diagnostics complete$(NC)"
