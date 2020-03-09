# .zshrc is sourced in interactive shells.

# Loading variable shared with the instalation script
source zsh/vars.zsh

### HISTORY ###
HISTFILE=~/.cache/zsh/history
HISTSIZE=10000
SAVEHIST=10000
# the history file is checked to see if anything was written out by another shell,
# and if so it is included in the history of the current shell too
setopt SHARE_HISTORY
# Saves the time when the command was started and how long it ran for
setopt EXTENDED_HISTORY
# Do not store a history line if it's the same as the previous one
setopt HIST_IGNORE_DUPS
# The OPEN_PLAN_OFFICE_NO_VIGILANTE_ATTACKS option
setopt NO_BEEP
# Automatically change directory
setopt AUTO_CD
# Extended globbing
setopt EXTENDED_GLOB
# Simple correction of commands
setopt CORRECT
# On an ambiguous completion insert the first match immediately.
setopt MENU_COMPLETE
######

bindkey -e

# Do menu-driven completion.
zstyle ':completion:*' menu select
# Show commands in groups
zstyle ':completion:*' group-name ''
zstyle ':completion:*' format '%B---- %d%b'

### ALIASES ###
alias cp="cp -i" # confirm before overwriting something
alias docker='sudo docker'
alias docker-compose='sudo docker-compose'
alias ls='ls --color=auto'
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
alias fgrep='fgrep --colour=auto'
alias pacman-search="pacman -Slq | fzf -m --preview 'cat <(pacman -Si {1}) <(pacman -Fl {1} | awk \"{print \$2}\")' | xargs -ro sudo pacman -S --needed"
# Suffix aliases
alias -s txt=$EDITOR
# Global aliases
alias -g NOERR='2>/dev/null'
######

### Load custom shell functions
autoload -Uz extract
autoload -Uz compinit
compinit -d "${_zsh_cache_dir}/zcompdump"
######

### Load custom colors
if type dircolors >/dev/null ; then
  if [[ -f ${ZDOTDIR}/dir_colors ]] ; then
    eval $(dircolors -b ${ZDOTDIR}/dir_colors)
  fi
fi

#### HOW TO INSTALL PLGUINS & THEMES ####
#                                       #
#       !!! Use git submodules !!!      #
#                                       #
# git submodule add -b master <repo>    #
# So, it could all be udpated with:     #
# git submodule update --remote         #
#########################################
# Don't forget to source them here below

### LOAD PLUGINS ###
# zsh-syntax-highlighting
# https://github.com/zsh-users/zsh-syntax-highlighting
source "${ZDOTDIR}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
# zsh-autosuggestions
# https://github.com/zsh-users/zsh-autosuggestions
source "${ZDOTDIR}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

### LOAD THEMES ###
# Powerlevel9k
# https://github.com/Powerlevel9k/powerlevel9k
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_LINUX_MANJARO_ICON='\uf303'
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon ssh root_indicator dir dir_writable vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(time status)
POWERLEVEL9K_STATUS_ERROR_BACKGROUND="white"
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_FOREGROUND="white"
POWERLEVEL9K_STATUS_VERBOSE=false
POWERLEVEL9K_TIME_BACKGROUND="black"
POWERLEVEL9K_TIME_FOREGROUND="249"
POWERLEVEL9K_TIME_FORMAT="%D{%H:%M}"
POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR='\uE0C6'
POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR='\uE0C6'
POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR='\uE0B2'
source "${ZDOTDIR}/themes/powerlevel9k/powerlevel9k.zsh-theme"

### Start tmux
if [ -z "$TMUX" ]; then
  tmux new-session -A -s workspace
fi