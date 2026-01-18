# Linux Sysadmin Skill

Expert system administration for managing Linux boxes and infrastructure.

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

When managing servers, always gather context first:

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

### User Management

```bash
# Add user
useradd -m -s /bin/bash -G sudo username
passwd username

# Add SSH key for user
mkdir -p /home/username/.ssh
echo "ssh-rsa AAAA..." >> /home/username/.ssh/authorized_keys
chmod 700 /home/username/.ssh
chmod 600 /home/username/.ssh/authorized_keys
chown -R username:username /home/username/.ssh

# List users
cat /etc/passwd | grep -v nologin | grep -v false

# Check sudo access
grep -E '^%sudo|^%wheel' /etc/sudoers
```

### Disk Management

```bash
# Disk usage analysis
du -sh /* 2>/dev/null | sort -h
ncdu /  # Interactive disk usage (if installed)

# Find large files
find / -type f -size +100M 2>/dev/null | head -20

# Find old files
find /var/log -type f -mtime +30 -delete

# Check for deleted but open files
lsof +L1

# Partition info
fdisk -l
lsblk -f
blkid
```

### Network Configuration

```bash
# Network interfaces
ip addr
ip link

# Routing
ip route
ip route get 8.8.8.8

# DNS
cat /etc/resolv.conf
systemd-resolve --status

# Firewall (iptables)
iptables -L -n -v
iptables-save

# Firewall (ufw)
ufw status verbose
ufw allow 22/tcp
ufw enable

# Firewall (firewalld)
firewall-cmd --list-all
firewall-cmd --add-port=80/tcp --permanent
firewall-cmd --reload

# Open ports
ss -tulpn
netstat -tulpn
```

### SSH Hardening

```bash
# /etc/ssh/sshd_config recommendations
cat << 'EOF'
# Recommended SSH settings
Port 22  # Consider changing
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
AllowUsers username1 username2
Protocol 2
X11Forwarding no
PermitEmptyPasswords no
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

# Apply changes
systemctl restart sshd

# Test before disconnecting!
ssh -T user@server
```

### Nginx Configuration

```bash
# Install
apt update && apt install -y nginx

# Basic server block
cat > /etc/nginx/sites-available/example.com << 'EOF'
server {
    listen 80;
    server_name example.com www.example.com;
    root /var/www/example.com;
    index index.html index.php;

    location / {
        try_files $uri $uri/ =404;
    }

    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
EOF

# Enable site
ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/

# Test and reload
nginx -t && systemctl reload nginx
```

### SSL/TLS with Certbot

```bash
# Install certbot
apt install -y certbot python3-certbot-nginx

# Get certificate
certbot --nginx -d example.com -d www.example.com

# Auto-renewal
certbot renew --dry-run

# Check certificate
openssl s_client -connect example.com:443 -servername example.com
```

### Docker Management

```bash
# Container status
docker ps -a
docker stats

# Cleanup
docker system prune -af
docker volume prune -f

# Logs
docker logs -f container_name

# Compose
docker compose up -d
docker compose down
docker compose logs -f
```

### Backup Strategies

```bash
# Simple rsync backup
rsync -avz --delete /data/ /backup/data/

# Tar with compression
tar -czvf /backup/data_$(date +%Y%m%d).tar.gz /data/

# Database backup (PostgreSQL)
pg_dump -U postgres dbname > /backup/db_$(date +%Y%m%d).sql

# Database backup (MySQL)
mysqldump -u root -p dbname > /backup/db_$(date +%Y%m%d).sql

# Remote backup
rsync -avz -e "ssh -p 22" /data/ user@remote:/backup/
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

### Performance Tuning

```bash
# System limits
ulimit -a
cat /etc/security/limits.conf

# Kernel parameters
sysctl -a | grep -E "tcp|net\."

# Recommended network tuning
cat >> /etc/sysctl.conf << 'EOF'
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 300
EOF
sysctl -p

# I/O scheduler
cat /sys/block/sda/queue/scheduler
```

### Cron Jobs

```bash
# Edit crontab
crontab -e

# Common patterns
# Every minute:      * * * * *
# Every hour:        0 * * * *
# Every day at 2am:  0 2 * * *
# Every Sunday:      0 0 * * 0
# Every month:       0 0 1 * *

# Example: Daily backup at 2am
0 2 * * * /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1

# List cron jobs
crontab -l
ls -la /etc/cron.*
```

### Security Checklist

```bash
echo "=== Security Audit ==="

echo -e "\n--- Open Ports ---"
ss -tulpn | grep LISTEN

echo -e "\n--- SSH Config ---"
grep -E "^(PermitRootLogin|PasswordAuthentication|Port)" /etc/ssh/sshd_config

echo -e "\n--- Failed Logins ---"
lastb | head -10

echo -e "\n--- Current Users ---"
who

echo -e "\n--- Sudo Users ---"
getent group sudo

echo -e "\n--- SUID Files ---"
find / -perm -4000 2>/dev/null | head -20

echo -e "\n--- World-writable Files ---"
find / -perm -2 -type f 2>/dev/null | head -20

echo -e "\n--- Listening Services ---"
systemctl list-units --type=service --state=running
```

### Troubleshooting Workflow

1. **Gather Info**
   ```bash
   uname -a && uptime && free -h && df -h
   ```

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

### Network Issues
```bash
# DNS resolution
nslookup google.com
dig google.com

# Connectivity
ping -c 4 8.8.8.8
traceroute google.com
mtr google.com

# Port checking
nc -zv localhost 80
telnet localhost 22
```

## Quick Reference

| Task                  | Command                              |
|-----------------------|--------------------------------------|
| Restart service       | `systemctl restart <service>`        |
| View logs             | `journalctl -u <service> -f`         |
| Disk usage            | `df -h && du -sh /*`                 |
| Memory usage          | `free -h`                            |
| Open ports            | `ss -tulpn`                          |
| Add firewall rule     | `ufw allow 80/tcp`                   |
| Check failed services | `systemctl --failed`                 |
| Recent errors         | `journalctl -p err --since "1h ago"` |

---

**Best Practice**: Always backup before making changes, test in staging first, and document everything!
