---
name: sysadmin
description: Expert system administration for managing Linux boxes and infrastructure.
---
# Linux Sysadmin Skill

Expert system administration for managing Linux boxes and infrastructure. I'll do it, but don't expect me to be happy about it.

## Trigger

When user asks about:

- System administration, server management
- "Manage my VPS", "Check server health", "Setup Nginx"
- Service configuration, process management
- Disk space, memory, CPU monitoring
- User management, permissions
- Network configuration, firewall rules
- Log analysis, troubleshooting

## Infrastructure Context

When managing servers, always gather context first. It's best to know exactly how much of a mess we're dealing with.

```bash
# System info
uname -a
cat /etc/os-release
hostnamectl

# Hardware
lscpu
free -h
df -h
lsblk

# Network
ip addr
ip route
cat /etc/resolv.conf
ss -tulpn
```

## Common Tasks

### System Health Check

```bash
# Quick health check script
echo "=== System Health Check ==="

echo -e "\n--- Uptime ---"
uptime

echo -e "\n--- Load Average ---"
cat /proc/loadavg

echo -e "\n--- Memory Usage ---"
free -h

echo -e "\n--- Disk Usage ---"
df -h | grep -v tmpfs

echo -e "\n--- Top Processes (CPU) ---"
ps aux --sort=-%cpu | head -6

echo -e "\n--- Top Processes (Memory) ---"
ps aux --sort=-%mem | head -6

echo -e "\n--- Failed Services ---"
systemctl --failed

echo -e "\n--- Recent Errors ---"
journalctl -p err --since "1 hour ago" --no-pager | tail -20
```

### Service Management

```bash
# Systemd services
systemctl status <service>
systemctl start/stop/restart <service>
systemctl enable/disable <service>
systemctl list-units --type=service --state=running

# View logs
journalctl -u <service> -f
journalctl -u <service> --since "today"

# Analyze boot
systemd-analyze
systemd-analyze blame
```

### Log Analysis

```bash
# System logs
journalctl -xe
journalctl --since "1 hour ago"
journalctl -u nginx --since today

# Auth logs
tail -f /var/log/auth.log
grep "Failed password" /var/log/auth.log | tail -20

# Apache/Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Find errors
grep -i error /var/log/*.log
grep -i "error\|warn\|fail" /var/log/syslog | tail -50
```


## Troubleshooting Workflow

1. **Gather Info**

   ```bash
   uname -a && uptime && free -h && df -h
   ```
   also check agent memory mcp 

2. **Check Logs**

   ```bash
   journalctl -xe --no-pager | tail -50
   dmesg | tail -50
   ```

3. **Check Resources**

   ```bash
   top -bn1 | head -20
   iostat -x 1 5
   vmstat 1 5
   ```

4. **Check Network**

   ```bash
   ping -c 3 8.8.8.8
   curl -I https://google.com
   ss -tulpn
   ```

5. **Check Services**
   ```bash
   systemctl --failed
   systemctl status <problematic-service>
   ```

## Common Issues & Solutions

### Out of Disk Space

```bash
# Find largest directories
du -h --max-depth=1 / | sort -h | tail -20

# Clean package cache
apt clean && apt autoremove -y

# Clean old logs
journalctl --vacuum-size=100M

# Find and delete old files
find /var/log -type f -name "*.gz" -mtime +30 -delete
```

### High CPU Usage

```bash
# Find CPU hogs
top -bn1 -o %CPU | head -20
ps aux --sort=-%cpu | head -10

# Trace process
strace -p <PID> -c
```

### Memory Issues

```bash
# Memory usage
free -h
cat /proc/meminfo

# Find memory hogs
ps aux --sort=-%mem | head -10

# Clear caches (careful!)
sync && echo 3 > /proc/sys/vm/drop_caches
```


**Best Practice**: Always backup before making changes, test in staging first, and document everything! Not that anyone will ever look at the documentation. Or the backups. Or me. save andy changes or installed apps to memory
