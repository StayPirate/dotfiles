# .zshrc is sourced in interactive shells.

# Loading variable shared with the instalation script
source $DOTFILES/vars

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

### FZF ###
if type fzf >/dev/null ; then

  # First, try to load system-wide zsh widgets. If not available, then load local repository ones.
  # Fuzzy completion
  declare -a completion_scripts=(
    "/usr/share/fzf/completion.zsh"           # Archlinux
    "/usr/share/zsh/site-functions/fzf"       # Fedora
    "/usr/share/zsh/vendor-completions/_fzf"  # Debian
  )
  local _fzf_completion=0
  for completion_script in "${completion_scripts[@]}"; do
      source $completion_script >/dev/null 2>&1 && _fzf_completion=1
  done
  if [ $_fzf_completion -eq 0 ]; then
    source $_dotfiles_link/zsh/plugins/fzf/completion.zsh >/dev/null 2>&1
  fi
  unset _fzf_completion

  # Key bindings
  declare -a keybindings_scripts=(
    "/usr/share/fzf/key-bindings.zsh"         # Archlinux
    "/usr/share/fzf/shell/key-bindings.zsh"   # Fedora
  )
  local _fzf_keybindings=0
  for keybindings_script in "${keybindings_scripts[@]}"; do
    source $keybindings_script >/dev/null 2>&1 && _fzf_keybindings=1
  done
  if [ $_fzf_keybindings -eq 0 ]; then
    source $_dotfiles_link/zsh/plugins/fzf/key-bindings.zsh >/dev/null 2>&1
  fi
  unset _fzf_keybindings

  # CTRL-R - Paste the selected command from history into the command line
  # Ensure to define this widget after you sourced `key-bindings.zsh`
  # It overrides the official history widget and substitute `fc` with `history` command.
  # It prints extra information while looping into the history.
  # `fc -rl 1` output:
  #     847  vim ~/.config/Code\ -\ OSS/User/settings.json
  # `history -Df 1` output:
  #     847  3/4/2020 12:35  0:15  vim ~/.config/Code\ -\ OSS/User/settings.json
  fzf-custom-history-widget() {
    local selected num
    setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
    selected=( $(history -Df 1 |
      FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd)) )
    local ret=$?
    if [ -n "$selected" ]; then
      num=$selected[1]
      if [ -n "$num" ]; then
        zle vi-fetch-history -n $num
      fi
    fi
    zle reset-prompt
    return $ret
  }
  zle     -N   fzf-custom-history-widget
  bindkey '^R' fzf-custom-history-widget

fi
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