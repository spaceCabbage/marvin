# syntax=docker/dockerfile:1
# Marvin: Multi-Platform Security Research & Development Environment
# Supports: linux/amd64, linux/arm64

# Build arguments
ARG DEBIAN_VERSION=bookworm-20250113-slim
ARG NODE_VERSION=24
ARG PYTHON_VERSION=3.12
ARG GO_VERSION=1.25.6
ARG BUN_VERSION=latest
ARG INSTALL_METASPLOIT=false
ARG ENABLE_CHROME=true

# =============================================================================
# Stage 1: Base System
# =============================================================================
FROM debian:${DEBIAN_VERSION} AS base

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

# Environment
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=UTC

# Install base system packages with cache mount
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        git \
        gnupg \
        lsb-release \
        apt-transport-https \
        software-properties-common \
        build-essential \
        pkg-config \
        procps \
        vim \
        nano \
        sudo \
        locales \
        unzip && \
    echo "Building for: ${TARGETPLATFORM} on ${BUILDPLATFORM}"

# =============================================================================
# Stage 2: Language Runtimes
# =============================================================================
FROM base AS languages

ARG NODE_VERSION
ARG PYTHON_VERSION
ARG GO_VERSION
ARG BUN_VERSION
ARG TARGETARCH

# Install Node.js from NodeSource
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
    gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" | \
    tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    npm install -g npm@latest && \
    node --version && npm --version

# Install Bun to /opt for sharing
RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/opt/bun bash && \
    ln -s /opt/bun/bin/bun /usr/local/bin/bun && \
    bun --version

# Install Python 3.12+
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev && \
    ln -sf /usr/bin/python3 /usr/local/bin/python && \
    python --version && pip --version

# Install uv for fast Python package management (10-100x faster than pip)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    ln -s /root/.local/bin/uv /usr/local/bin/uv && \
    uv --version

# Install Go
RUN GOARCH=${TARGETARCH} && \
    if [ "${GOARCH}" = "amd64" ]; then GOARCH="amd64"; fi && \
    if [ "${GOARCH}" = "arm64" ]; then GOARCH="arm64"; fi && \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GOARCH}.tar.gz" | \
    tar -C /usr/local -xzf - && \
    ln -s /usr/local/go/bin/go /usr/local/bin/go && \
    ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt && \
    go version

# Install Go-based security/OSINT tools (ProjectDiscovery suite + Amass)
# Note: GOPATH/PATH use /opt/go for build-time, runtime uses $HOME/go
ENV GOPATH=/opt/go
ENV PATH="${PATH}:/opt/go/bin"
RUN go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest && \
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest && \
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest && \
    go install -v github.com/owasp-amass/amass/v4/...@master && \
    subfinder -version && nuclei -version

# =============================================================================
# Stage 3: Security Tools
# =============================================================================
FROM languages AS security-tools

# Install network and security tools
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get install -y --no-install-recommends \
        nmap \
        masscan \
        netcat-openbsd \
        tcpdump \
        traceroute \
        dnsutils \
        whois \
        iputils-ping \
        iproute2 \
        iptables \
        net-tools \
        wireless-tools \
        aircrack-ng \
        wireshark-common \
        tshark \
        binwalk \
        john \
        hashcat \
        hydra \
        sslscan \
        testssl.sh && \
    nmap --version

# Install nikto from git (not in Debian repos)
RUN git clone https://github.com/sullo/nikto.git /opt/nikto && \
    ln -s /opt/nikto/program/nikto.pl /usr/local/bin/nikto && \
    chmod +x /opt/nikto/program/nikto.pl

# Install sslyze via uv (not in Debian repos)
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --break-system-packages sslyze

# Install wpscan via Ruby gem (not in Debian repos)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get install -y --no-install-recommends ruby ruby-dev && \
    gem install wpscan

# Install Python-based security tools
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --break-system-packages \
        sqlmap \
        impacket \
        scapy \
        requests \
        beautifulsoup4 \
        lxml \
        pwntools \
        volatility3 \
        yara-python && \
    sqlmap --version

# Install OSINT tools
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --break-system-packages \
        theHarvester \
        Photon \
        dnspython \
        phonenumbers \
        censys \
        shodan \
        googlesearch-python \
        instaloader \
        spiderfoot \
        bbot \
        maigret \
        metagoofil \
        h8mail \
        holehe \
        socialscan && \
    theHarvester --version || echo "theHarvester installed"

# Install lead qualification / company research tools
RUN --mount=type=cache,target=/root/.cache/uv \
    git clone https://github.com/m8sec/CrossLinked.git /opt/crosslinked && \
    cd /opt/crosslinked && \
    uv pip install --system --break-system-packages -r requirements.txt && \
    ln -s /opt/crosslinked/crosslinked.py /usr/local/bin/crosslinked && \
    chmod +x /opt/crosslinked/crosslinked.py

# Install recon-ng framework
# Note: recon-ng has limited maintenance (creator stopped active development)
# but remains functional for basic reconnaissance tasks
RUN --mount=type=cache,target=/root/.cache/uv \
    git clone https://github.com/lanmaster53/recon-ng.git /opt/recon-ng && \
    cd /opt/recon-ng && \
    uv pip install --system --break-system-packages -r REQUIREMENTS && \
    ln -s /opt/recon-ng/recon-ng /usr/local/bin/recon-ng

# Install additional OSINT tools via apt
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get install -y --no-install-recommends \
        exiftool \
        curl \
        jq \
        lynx \
        w3m \
        pandoc

# Install weasyprint for PDF generation with dark theme support
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --break-system-packages weasyprint && \
    weasyprint --version

# Install OWASP ZAP (headless)
RUN wget -q https://github.com/zaproxy/zaproxy/releases/download/v2.17.0/ZAP_2.17.0_Linux.tar.gz -O /tmp/zap.tar.gz && \
    tar -xzf /tmp/zap.tar.gz -C /opt && \
    ln -s /opt/ZAP_*/zap.sh /usr/local/bin/zap && \
    rm /tmp/zap.tar.gz

# =============================================================================
# Stage 4: Metasploit (Conditional)
# =============================================================================
FROM security-tools AS metasploit-stage

ARG INSTALL_METASPLOIT
ARG TARGETPLATFORM

# Install Metasploit Framework (if enabled)
RUN if [ "${INSTALL_METASPLOIT}" = "true" ]; then \
        echo "Installing Metasploit Framework for ${TARGETPLATFORM}..."; \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            postgresql \
            postgresql-contrib \
            ruby \
            ruby-dev \
            libpq-dev \
            libssl-dev \
            libreadline-dev \
            zlib1g-dev && \
        git clone --depth=1 https://github.com/rapid7/metasploit-framework.git /opt/metasploit && \
        cd /opt/metasploit && \
        gem install bundler && \
        bundle install && \
        ln -s /opt/metasploit/msfconsole /usr/local/bin/msfconsole && \
        ln -s /opt/metasploit/msfvenom /usr/local/bin/msfvenom && \
        echo "Metasploit installed successfully"; \
    else \
        echo "Skipping Metasploit installation"; \
    fi

# =============================================================================
# Stage 5: Modern CLI Tools
# =============================================================================
FROM security-tools AS cli-tools

ARG TARGETARCH

# Install modern shell utilities
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get install -y --no-install-recommends \
        ripgrep \
        fd-find \
        jq \
        htop \
        tmux \
        unzip \
        zip \
        p7zip-full \
        tree \
        file \
        strace \
        ltrace && \
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then GOTTY_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then GOTTY_ARCH="arm64"; \
    else GOTTY_ARCH="amd64"; fi && \
    curl -fsSL "https://github.com/sorenisanerd/gotty/releases/download/v1.6.0/gotty_v1.6.0_linux_${GOTTY_ARCH}.tar.gz" | \
    tar -xzf - -C /usr/local/bin ./gotty && \
    chmod +x /usr/local/bin/gotty && \
    ln -s /usr/bin/fdfind /usr/local/bin/fd

# Install bat (better cat)
RUN BATARCH=${TARGETARCH} && \
    if [ "${BATARCH}" = "amd64" ]; then BATARCH="x86_64"; fi && \
    if [ "${BATARCH}" = "arm64" ]; then BATARCH="aarch64"; fi && \
    curl -fsSL "https://github.com/sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-${BATARCH}-unknown-linux-gnu.tar.gz" | \
    tar -xzf - -C /tmp && \
    mv /tmp/bat-*/bat /usr/local/bin/ && \
    rm -rf /tmp/bat-*

# Install eza (better ls)
RUN EZAARCH=${TARGETARCH} && \
    if [ "${EZAARCH}" = "amd64" ]; then EZAARCH="x86_64"; fi && \
    if [ "${EZAARCH}" = "arm64" ]; then EZAARCH="aarch64"; fi && \
    curl -fsSL "https://github.com/eza-community/eza/releases/download/v0.23.4/eza_${EZAARCH}-unknown-linux-gnu.tar.gz" | \
    tar -xzf - -C /tmp && \
    mv /tmp/eza /usr/local/bin/ && \
    rm -rf /tmp/eza*

# Install fzf (fuzzy finder) - pinned to release, installed to /opt for sharing
RUN git clone --depth 1 --branch v0.67.0 https://github.com/junegunn/fzf.git /opt/fzf && \
    /opt/fzf/install --bin && \
    ln -s /opt/fzf/bin/fzf /usr/local/bin/fzf

# Install yq (YAML processor)
RUN YQARCH=${TARGETARCH} && \
    curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${YQARCH}" -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

# =============================================================================
# Stage 6: WiFi Drivers (ARM64 and x86_64)
# =============================================================================
FROM cli-tools AS wifi-drivers

ARG TARGETPLATFORM

# Install RTL8811AU driver for AWUS036ACS
# Supports both ARM64 (Raspberry Pi) and x86_64 (local dev machines)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dkms \
        bc \
        kmod \
        iw && \
    if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
        echo "Installing WiFi drivers for ARM64..."; \
        apt-get install -y --no-install-recommends linux-headers-generic || true && \
        git clone https://github.com/morrownr/8821au-20210708.git /tmp/8821au && \
        cd /tmp/8821au && \
        ./ARM64_RPI.sh && \
        make && make install && \
        rm -rf /tmp/8821au && \
        echo "WiFi drivers installed for ARM64"; \
    elif [ "${TARGETPLATFORM}" = "linux/amd64" ]; then \
        echo "Installing WiFi drivers for x86_64..."; \
        apt-get install -y --no-install-recommends linux-headers-generic || true && \
        git clone https://github.com/morrownr/8821au-20210708.git /tmp/8821au && \
        cd /tmp/8821au && \
        make && make install || echo "Driver build may require host kernel headers" && \
        rm -rf /tmp/8821au && \
        echo "WiFi drivers installed for x86_64"; \
    else \
        echo "Skipping WiFi drivers (unknown platform: ${TARGETPLATFORM})"; \
    fi

# =============================================================================
# Stage 7: Gemini CLI & MCP Servers
# =============================================================================
FROM wifi-drivers AS gemini-cli

ARG ENABLE_CHROME

# Install Gemini CLI (no sudo!)
RUN npm install -g @google/gemini-cli && \
    gemini --version

# Pre-install MCP SDK and verified servers (zod is a peer dependency of the SDK)
RUN npm install -g \
    zod \
    @modelcontextprotocol/sdk \
    mcp-server-sqlite-npx \
    @upstash/context7-mcp \
    @playwright/mcp@0.0.56 \
    @hubspot/mcp-server

# Set NODE_PATH so globally installed packages (like zod) are found by require()
# This is critical for MCP servers that have zod as a peer dependency
ENV NODE_PATH=/usr/local/lib/node_modules

# Install Playwright browsers (headless Chromium) - conditional on ENABLE_CHROME
# Browsers go to /opt/playwright, cache metadata copied to /opt/playwright-cache
# At runtime, XDG_CACHE_HOME points here so Playwright can find its browsers
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright
RUN if [ "${ENABLE_CHROME}" = "true" ]; then \
      npx playwright@1.58.0-alpha-2026-01-16 install --with-deps chromium && \
      mkdir -p /opt/playwright-cache/ms-playwright && \
      cp -r /root/.cache/ms-playwright/* /opt/playwright-cache/ms-playwright/ 2>/dev/null || true && \
      echo "Playwright Chrome installed (cache preserved to /opt/playwright-cache)"; \
    else \
      echo "Skipping Playwright browser installation (ENABLE_CHROME=false)"; \
    fi

# Create workspace directory (will be $HOME at runtime)
RUN mkdir -p /workspace

# =============================================================================
# Final Stage: Production Image
# =============================================================================
FROM gemini-cli AS final

ARG INSTALL_METASPLOIT

# Copy Metasploit from conditional stage if it was built
# Note: Metasploit installation is conditional in metasploit-stage
# These directories may be empty if INSTALL_METASPLOIT=false
RUN --mount=type=bind,from=metasploit-stage,source=/opt,target=/mnt/msf-opt \
    --mount=type=bind,from=metasploit-stage,source=/usr/local/bin,target=/mnt/msf-bin \
    if [ -d /mnt/msf-opt/metasploit ]; then \
        cp -r /mnt/msf-opt/metasploit /opt/metasploit && \
        echo "Metasploit copied from build stage"; \
    fi && \
    for f in /mnt/msf-bin/msf*; do \
        if [ -f "$f" ]; then \
            cp "$f" /usr/local/bin/ && \
            echo "Copied $(basename $f)"; \
        fi; \
    done || true

# Copy entrypoint and helper scripts
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY scripts/init-mcp.sh /usr/local/bin/init-mcp.sh
COPY scripts/monitor-mode.sh /usr/local/bin/monitor-mode.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/*.sh

# Gemini config comes from mounted workspace/.gemini/
# No COPY needed - workspace is mounted and $HOME=/workspace

# Set working directory to workspace (will be $HOME at runtime)
WORKDIR /workspace

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD gemini --version || exit 1

# Expose ports (for GoTTY and MCP servers)
EXPOSE 7681 3000 5432 8080

# Default to bash, but entrypoint can override
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]

# Labels for multi-arch
LABEL org.opencontainers.image.title="Marvin"
LABEL org.opencontainers.image.description="Multi-platform Gemini CLI security research and development environment"
LABEL org.opencontainers.image.authors="Marvin Project"
LABEL org.opencontainers.image.source="https://github.com/spaceCabbage/Marvin"

