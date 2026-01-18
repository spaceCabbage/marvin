#!/bin/bash
# WiFi Monitor Mode Setup Script
# Enables monitor mode on USB WiFi adapters (AWUS036ACS with RTL8811AU chipset)

set -e

INTERFACE=${1:-wlan1}

echo "=========================================="
echo "WiFi Monitor Mode Setup"
echo "Interface: $INTERFACE"
echo "=========================================="

# Check if interface exists
if ! ip link show "$INTERFACE" &> /dev/null; then
    echo "ERROR: Interface $INTERFACE not found!"
    echo ""
    echo "Available wireless interfaces:"
    iw dev | grep Interface | awk '{print $2}'
    exit 1
fi

echo "✓ Interface $INTERFACE found"

# Kill interfering processes
echo "Stopping interfering processes..."
systemctl stop NetworkManager 2>/dev/null || echo "NetworkManager not running"
systemctl stop wpa_supplicant 2>/dev/null || echo "wpa_supplicant not running"
killall wpa_supplicant 2>/dev/null || echo "No wpa_supplicant processes"

# Bring interface down
echo "Bringing interface down..."
ip link set "$INTERFACE" down

# Set monitor mode
echo "Setting monitor mode..."
iw dev "$INTERFACE" set type monitor

# Bring interface up
echo "Bringing interface up..."
ip link set "$INTERFACE" up

# Verify monitor mode
echo ""
echo "Verifying monitor mode..."
if iwconfig "$INTERFACE" 2>/dev/null | grep -q "Mode:Monitor"; then
    echo "=========================================="
    echo "✓ SUCCESS: Monitor mode enabled on $INTERFACE"
    echo "=========================================="
    echo ""
    iwconfig "$INTERFACE" 2>/dev/null | grep -E "Mode|Frequency"
    echo ""
    echo "Ready for aircrack-ng suite:"
    echo "  airodump-ng $INTERFACE"
    echo "  aireplay-ng --test $INTERFACE"
    echo ""
else
    echo "=========================================="
    echo "✗ ERROR: Failed to enable monitor mode"
    echo "=========================================="
    echo ""
    echo "Troubleshooting:"
    echo "1. Check if driver supports monitor mode"
    echo "2. Verify USB adapter is properly connected"
    echo "3. Check dmesg for driver errors: dmesg | tail -20"
    echo "4. List wireless interfaces: iw dev"
    exit 1
fi
