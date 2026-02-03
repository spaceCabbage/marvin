# Marvin Shell Configuration
# Optimized for AI-assisted workflows

# Minimal, parseable prompt: "marvin:/path$ "
export PS1='marvin:\w\$ '

# History - comprehensive for context
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T '
shopt -s histappend
PROMPT_COMMAND='history -a'

# Shell options
shopt -s checkwinsize
shopt -s globstar 2>/dev/null
shopt -s nocaseglob
set -o pipefail 2>/dev/null

# Modern CLI tools (better structured output for AI parsing)
alias ls='eza --color=auto'
alias ll='eza -la --git'
alias la='eza -a'
alias l='eza -l'
alias tree='eza --tree'
alias cat='bat --paging=never --plain'
alias grep='rg'
alias find='fd'

# Git shortcuts
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline -20'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Paths - use $HOME for portability
export PATH="$HOME/go/bin:/opt/go/bin:/usr/local/bin:$PATH"
export GOPATH="$HOME/go"

# Node.js - make global packages (like zod) available to require()
export NODE_PATH="/usr/local/lib/node_modules"

# Python
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# FZF integration (installed to /opt)
[ -f /opt/fzf/shell/key-bindings.bash ] && source /opt/fzf/shell/key-bindings.bash
[ -f /opt/fzf/shell/completion.bash ] && source /opt/fzf/shell/completion.bash

# Editor
export EDITOR=vim
export VISUAL=vim

# Less - better pager settings
export LESS='-R --mouse --wheel-lines=3'

# Load local customizations if present
[ -f "$HOME/.bashrc.local" ] && source "$HOME/.bashrc.local"
