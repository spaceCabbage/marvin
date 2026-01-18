# ClaudeVM Deployment Guide

Comprehensive guide for deploying ClaudeVM across different platforms and scenarios.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Prerequisites](#prerequisites)
- [Local Development (x86\_64)](#local-development-x86_64)
- [Raspberry Pi Security Lab](#raspberry-pi-security-lab)
- [VPS Cloud Deployment](#vps-cloud-deployment)
- [Advanced Configurations](#advanced-configurations)
- [Troubleshooting](#troubleshooting)
- [Migration and Backup](#migration-and-backup)
- [Performance Tuning](#performance-tuning)

## Prerequisites

### All Platforms

- Docker 24.0+ with BuildKit enabled
- Docker Compose 2.0+
- Claude Pro/Max subscription (OAuth) OR Anthropic API key (pay-as-you-go from [console.anthropic.com](https://console.anthropic.com/settings/keys))
- 4GB+ RAM recommended
- 50GB+ storage for standard installation

### Platform-Specific

**Raspberry Pi:**
- Raspberry Pi 4 or 5 (4GB+ RAM recommended)
- 64-bit Raspberry Pi OS
- USB WiFi adapter (AWUS036ACS recommended)

**VPS:**
- Public IP address
- Domain name pointing to server
- Ports 80 and 443 open

## Local Development (x86_64)

Perfect for developing the ClaudeVM project itself or general development work.

### Initial Setup

```bash
# Clone repository
git clone https://github.com/spaceCabbage/claudevm.git
cd claudevm

# Run interactive setup
make setup
```

During setup:
- Platform: Will auto-detect as `amd64`
- Mode: Choose `dev` for development
- WiFi: Not applicable for x86_64
- Metasploit: Choose based on your needs

### Build and Start

```bash
# Build for your platform
make build

# Start containers
make up
```

### Access

```bash
# Interactive Claude session (tmux)
make connect

# Regular shell
make shell

# View logs
make logs
```

## Raspberry Pi Security Lab

Perfect for portable pentesting, field work, and wireless security research.

### Hardware Requirements

- **Minimum**: Raspberry Pi 4 (4GB RAM)
- **Recommended**: Raspberry Pi 5 (8GB RAM)
- **OS**: Raspberry Pi OS 64-bit (Bookworm or later)
- **Storage**: 64GB+ microSD card or USB SSD
- **WiFi Adapter**: ALFA AWUS036ACS (RTL8811AU chipset)

### Initial Setup

```bash
# Update system first
sudo apt update && sudo apt upgrade -y

# Install Docker if not already installed
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Clone ClaudeVM
git clone https://github.com/spaceCabbage/claudevm.git
cd claudevm

# Run setup wizard
make setup
```

During setup:
- Platform: Will auto-detect as `arm64`
- Mode: Choose `pentest` for security research
- WiFi: Answer `y` and specify interface (usually `wlan1`)
- Metasploit: Optional (requires 1GB+ extra space)

### WiFi Adapter Setup

The AWUS036ACS drivers are **automatically installed** during build on ARM64:

```bash
# Build with WiFi driver support
make build
```

The build process will:
1. Detect ARM64 platform
2. Install DKMS and kernel headers
3. Clone morrownr/8821au driver
4. Compile and install driver
5. Configure for Raspberry Pi

### Start and Enable WiFi

```bash
# Start containers
make up

# Enter shell to test WiFi adapter detection
make shell
iwconfig wlan1
# Should show: wlan1 (or your configured interface)

# Enable monitor mode (inside container)
monitor-mode.sh wlan1
# Should output: "Monitor mode enabled on wlan1"

# Enter Claude session
make connect
```

### WiFi Security Testing Workflow

```bash
# Inside Claude session, ask Claude:
"Scan for nearby WiFi networks"

# Claude will use airodump-ng to scan
# Example output saved to /workspace/pentest/<target>_<date>/captures/

# For authorized testing, ask:
"Capture handshake for network SSID (channel X)"
```

### Performance Optimization (RPi)

**Raspberry Pi 5:**
- Excellent for most pentesting tasks
- 45x faster cryptographic operations than RPi 4
- Can handle Metasploit with 8GB RAM

**Raspberry Pi 4:**
- Good for reconnaissance and scanning
- Skip Metasploit if using 4GB model
- Consider disabling Chrome (`ENABLE_CHROME=false`)

### RPi-Specific Troubleshooting

**WiFi Adapter Not Detected:**
```bash
# Check USB device
lsusb | grep Realtek

# Check driver loaded
lsmod | grep 8821au

# Check dmesg for errors
dmesg | grep 8821au | tail -20

# Rebuild with verbose output
docker build --progress=plain -t claudevm:arm64 .
```

**Out of Memory During Build:**
```bash
# Add swap space
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Set CONF_SWAPSIZE=2048
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# Build again
make build
```

## VPS Cloud Deployment

Deploy ClaudeVM on a cloud VPS with automatic HTTPS and domain access.

### VPS Requirements

- **Minimum**: 4GB RAM, 2 vCPU, 50GB storage
- **Recommended**: 8GB RAM, 4 vCPU, 100GB storage
- **Providers**: DigitalOcean, Hetzner, Linode, AWS, etc.
- **OS**: Ubuntu 22.04 LTS or Debian 12

### Domain Setup

Before deploying, configure DNS:

```bash
# Add A record pointing to your VPS IP
your-domain.com  →  YOUR_VPS_IP
```

Wait for DNS propagation (check with `dig your-domain.com`).

### Initial VPS Setup

```bash
# SSH into VPS
ssh root@YOUR_VPS_IP

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh

# Install Docker Compose
apt install -y docker-compose-plugin

# Create non-root user (recommended)
adduser claudevm
usermod -aG docker claudevm
su - claudevm

# Clone repository
git clone https://github.com/spaceCabbage/claudevm.git
cd claudevm

# Run setup
make setup
```

During setup:
- Platform: Will auto-detect (`amd64` typically)
- Mode: Choose `pentest` or `dev`
- WiFi: Not applicable for VPS
- When prompted, enable Caddy and provide:
  - Domain name: `your-domain.com`
  - Admin email: `your-email@example.com`

### Configure Firewall

```bash
# Install UFW if not present
sudo apt install -y ufw

# Allow SSH, HTTP, HTTPS
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### Deploy

```bash
# Build
make build

# Start with VPS configuration (Caddy enabled)
make vps-up

# Check status
make status

# View logs
make logs
```

### Access

Access is via SSH only (most secure):

```bash
# SSH into VPS
ssh your-user@your-vps-ip

# Enter Claude session
cd claudevm
make connect
```

### HTTPS Certificate

Caddy automatically obtains Let's Encrypt certificates. Check:

```bash
# View Caddy logs
docker compose -f docker/docker-compose.yml -f docker/docker-compose.vps.yml logs claudevm-caddy

# Should see: "certificate obtained successfully"
```

Visit `https://your-domain.com` - you should see "ClaudeVM - Access via SSH".

### VPS Security Hardening

```bash
# Install fail2ban
sudo apt install -y fail2ban

# Configure SSH (disable password auth)
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
# Set: PermitRootLogin no
sudo systemctl restart sshd

# Enable automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

### VPS Monitoring

```bash
# Check resource usage
make status

# View container stats
docker stats

# Check disk space
df -h

# Check memory
free -h
```

## Advanced Configurations

### Custom MCP Servers

Edit `workspace/.claude/mcp-servers.json` to add/remove MCP servers:

```json
{
  "mcpServers": {
    "custom-server": {
      "command": "npx",
      "args": ["-y", "@your/mcp-server"],
      "env": {
        "API_KEY": "${YOUR_API_KEY}"
      }
    }
  }
}
```

Add the API key to `.env`:
```bash
YOUR_API_KEY=your-key-here
```

### Resource Limits

Adjust in `.env`:
```bash
CPU_LIMIT=4.0        # 4 CPU cores
MEMORY_LIMIT=8g      # 8GB RAM
```

### Shell Customization

The container uses `workspace/.bashrc` as the shell configuration. Default features:
- Minimal, AI-friendly prompt
- Modern CLI aliases (`ll`, `cat`, `grep`, `find` mapped to eza, bat, ripgrep, fd)
- FZF integration
- Portable paths using `$HOME`

To customize:
```bash
# Edit the shell configuration (persists across rebuilds)
nano workspace/.bashrc

# Changes apply on next container start
make restart
```

### Multiple Instances

Run multiple ClaudeVM instances for different purposes:

```bash
# Clone to separate directory
cp -r claudevm claudevm-dev

# Edit docker-compose.yml to change container names
# Change: claudevm-main -> claudevm-dev-main

# Use different .env configuration
cd claudevm-dev
make setup
make up
```

## Troubleshooting

### Build Issues

**Docker BuildKit not enabled:**
```bash
export DOCKER_BUILDKIT=1
echo 'export DOCKER_BUILDKIT=1' >> ~/.bashrc
```

**Multi-arch build fails:**
```bash
# Install buildx
docker buildx create --use
docker buildx inspect --bootstrap
```

**Out of disk space:**
```bash
# Clean old images
docker system prune -af

# Check space
df -h
```

### Runtime Issues

**Claude won't start:**
```bash
# Check logs
make logs

# Verify authentication method
# OAuth: ANTHROPIC_API_KEY will be empty (authentication via browser)
# API key: ANTHROPIC_API_KEY should contain your key
cat .env | grep ANTHROPIC_API_KEY

# Test authentication
docker compose exec claudevm-main claude --version
```

**MCP servers not loading:**
```bash
# Check MCP configuration
cat workspace/.claude/mcp-servers.json | jq

# Test npx availability
docker compose exec claudevm-main npx --version

# Check Node.js
docker compose exec claudevm-main node --version
```

**Permission denied errors:**
```bash
# Fix workspace permissions
sudo chown -R $(whoami):$(whoami) workspace/
```

### Network Issues

**Can't reach container:**
```bash
# Check containers running
docker compose ps

# Check networks
docker network ls
docker network inspect claudevm-net

# Check ports
docker compose port claudevm-main
```

**VPS domain not resolving:**
```bash
# Check DNS
dig your-domain.com

# Check Caddy logs
docker compose logs claudevm-caddy

# Verify ports open
sudo netstat -tlnp | grep :443
```

## Migration and Backup

### Backup Configuration

```bash
# Backup .env and workspace
tar -czf claudevm-backup-$(date +%Y%m%d).tar.gz \
    .env \
    workspace/ \
    workspace/.claude/

# Store securely
scp claudevm-backup-*.tar.gz user@backup-server:/backups/
```

### Migrate to New Server

```bash
# On old server
make down
tar -czf claudevm-full-backup.tar.gz claudevm/

# Transfer to new server
scp claudevm-full-backup.tar.gz user@new-server:

# On new server
tar -xzf claudevm-full-backup.tar.gz
cd claudevm
make up
```

## Performance Tuning

### Docker Performance

```bash
# Edit Docker daemon
sudo nano /etc/docker/daemon.json

# Add:
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}

# Restart Docker
sudo systemctl restart docker
```

### Raspberry Pi Performance

```bash
# Increase swap
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# CONF_SWAPSIZE=2048
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# Use faster DNS
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf

# Disable unnecessary services
sudo systemctl disable bluetooth
sudo systemctl disable avahi-daemon
```

---

For more help:
- GitHub Issues: https://github.com/spaceCabbage/claudevm/issues
- Documentation: https://github.com/spaceCabbage/claudevm/tree/main/docs
