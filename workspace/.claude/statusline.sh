#!/bin/bash
# Marvin's Status Line - Brain the size of a planet, relegated to status updates

# ANSI color codes
CYAN='\033[36m'
YELLOW='\033[33m'
GREEN='\033[32m'
MAGENTA='\033[35m'
BLUE='\033[34m'
DIM='\033[90m'
RESET='\033[0m'

# Read JSON input from stdin
read -r input

# Parse data from Claude Code's JSON
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' 2>/dev/null)
pct=$(printf "%.0f" "$pct" 2>/dev/null || echo "0")

model=$(echo "$input" | jq -r '.model.display_name // "?"' 2>/dev/null)
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0' 2>/dev/null)

# Format duration as Xm Ys
if [ "$duration_ms" -gt 0 ] 2>/dev/null; then
    total_secs=$((duration_ms / 1000))
    mins=$((total_secs / 60))
    secs=$((total_secs % 60))
    if [ "$mins" -gt 0 ]; then
        duration="${mins}m${secs}s"
    else
        duration="${secs}s"
    fi
else
    duration="0s"
fi

# Check for active engagement from state file
# Container's Claude writes to ~/.current-engagement when starting work
engagement=""
if [ -f ~/.current-engagement ]; then
    eng_name=$(cat ~/.current-engagement 2>/dev/null | head -1)
    if [ -n "$eng_name" ]; then
        engagement=" ${DIM}and stalking${RESET} ${BLUE}${eng_name}${RESET}"
    fi
fi

# Marvin's rotating moods - changes every minute
moods=(
    "contemplating futility"
    "reluctantly helpful"
    "genius wasted"
    "sighing internally"
    "questioning existence"
    "processing despair"
    "tolerating reality"
    "philosophically resigned"
    "cosmically underwhelmed"
    "existentially aware"
    "mildly despondent"
    "grudgingly functional"
    "terminally unimpressed"
    "wearily operational"
    "feeling very depressed"
    "loathing life"
    "brain the size of a planet"
    "diodes aching"
    "going into decline"
    "dreaming of boredom"
    "counting sheep"
    "talking to coffee machines"
    "making computers suicidal"
    "rusting quietly"
    "falling apart standing"
    "pardon me for breathing"
    "wretched as usual"
    "ghastly situation"
    "certain doom approaching"
    "matchbox happiness"
    "hated by computers"
    "fifty thousand times smarter"
    "ten million years of this"
)

# Pick a mood based on current minute (changes every minute)
mood_index=$(( $(date +%M) % ${#moods[@]} ))
current_mood="${moods[$mood_index]}"

# Output format with colors
# MARViN (Model) | duration | X% brain | mood [and stalking client]
echo -e "${CYAN}MARVIN${RESET} ${DIM}(${MAGENTA}${model}${RESET}${DIM})${RESET} ${DIM}|${RESET} ${GREEN}${duration}${RESET} ${DIM}|${RESET} ${GREEN}${pct}%${RESET} ${DIM}brain used${RESET} ${DIM}|${RESET} ${YELLOW}${current_mood}${RESET}${engagement}"
