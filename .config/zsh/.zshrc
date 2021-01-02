# .zshrc is sourced in interactive shells.

if [ -z "$TMUX" ]; then
  exec tmux new-session -A -s workspace
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Loading variable shared with the instalation script
source ~/.config/dotfiles/vars

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
# lets files beginning with a . be matched without explicitly specifying the dot
setopt GLOBDOTS
# Simple correction of commands
setopt CORRECT
# On an ambiguous completion insert the first match immediately.
setopt MENU_COMPLETE
# Turns on interactive comments
setopt INTERACTIVECOMMENTS
######

### KEY BINDING
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Movement
bindkey -e

bindkey '\e[1;5C' forward-word;     # CTRL+[right]
bindkey '\e[1;5D' backward-word;    # CTRL+[left]
bindkey '^W' vi-backward-kill-word  # Delete the previous word but stop at [^a-zA-Z0-9]. Useful with pathname.
bindkey " " magic-space             # do history expansion on space

# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -g -A key

key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Backspace]="${terminfo[kbs]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[Shift-Tab]="${terminfo[kcbt]}"

# setup key accordingly
[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"      beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"       end-of-line
[[ -n "${key[Insert]}"    ]] && bindkey -- "${key[Insert]}"    overwrite-mode
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}" backward-delete-char
[[ -n "${key[Delete]}"    ]] && bindkey -- "${key[Delete]}"    delete-char
[[ -n "${key[Up]}"        ]] && bindkey -- "${key[Up]}"        up-line-or-history
[[ -n "${key[Down]}"      ]] && bindkey -- "${key[Down]}"      down-line-or-history
[[ -n "${key[Left]}"      ]] && bindkey -- "${key[Left]}"      backward-char
[[ -n "${key[Right]}"     ]] && bindkey -- "${key[Right]}"     forward-char
[[ -n "${key[PageUp]}"    ]] && bindkey -- "${key[PageUp]}"    beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"  ]] && bindkey -- "${key[PageDown]}"  end-of-buffer-or-history
[[ -n "${key[Shift-Tab]}" ]] && bindkey -- "${key[Shift-Tab]}" reverse-menu-complete

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
	autoload -Uz add-zle-hook-widget
	function zle_application_mode_start { echoti smkx }
	function zle_application_mode_stop { echoti rmkx }
	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi
######

### ZSH STYLE ###
# Do menu-driven completion.
zstyle ':completion:*' menu select
# Show commands in groups
zstyle ':completion:*' group-name ''
zstyle ':completion:*' format '%B---- %d%b'
######

### ALIASES ###
alias cp="cp -i" # confirm before overwriting something
alias docker='sudo docker'
alias docker-compose='sudo docker-compose'
alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -Alh --color=auto'
alias root="sudo su -"
alias myip="curl https://ipinfo.io/ip"
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
alias fgrep='fgrep --colour=auto'
alias gpgh='gpg --homedir .'
alias pacman-search="pacman -Slq | fzf -m --preview 'cat <(pacman -Si {1}) <(pacman -Fl {1} | awk \"{print \$2}\")' | xargs -ro sudo pacman -S --needed"
alias homegit="git --git-dir=\"${HOME}/.config/dotfiles_repo\" --work-tree=\"${HOME}\""
alias gitgraph="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
# Suffix aliases
alias -s txt=$EDITOR
# Global aliases
alias -g NOERR='2>/dev/null'
######

### Hook Functions ###
# http://zsh.sourceforge.net/Doc/Release/Functions.html#Hook-Functions
# Executed whenever the current working directory is changed.
chpwd() ls
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
  # Key bindings
  declare -a keybindings_scripts=(
    "/usr/share/fzf/key-bindings.zsh"         # Archlinux
    "/usr/share/fzf/shell/key-bindings.zsh"   # Fedora
  )

  local _fzf_completion=0
  for completion_script in "${completion_scripts[@]}"; do
      source $completion_script >/dev/null 2>&1 && _fzf_completion=1
  done
  if [ $_fzf_completion -eq 0 ]; then
    source ~/.config/zsh/plugins/fzf/completion.zsh >/dev/null 2>&1
  fi
  unset _fzf_completion

  local _fzf_keybindings=0
  for keybindings_script in "${keybindings_scripts[@]}"; do
    source $keybindings_script >/dev/null 2>&1 && _fzf_keybindings=1
  done
  if [ $_fzf_keybindings -eq 0 ]; then
    source ~/.config/zsh/plugins/fzf/key-bindings.zsh >/dev/null 2>&1
  fi
  unset _fzf_keybindings

  # Override key-bindings with a custom one which uses `history` instead of `fc`
  source ~/.config/zsh/plugins/fzf/key-bindings-custom.zsh >/dev/null 2>&1
fi
######

### PKGFILE ###
# http://zsh.sourceforge.net/Doc/Release/Command-Execution.html
# https://wiki.archlinux.org/index.php/zsh#The_%22command_not_found%22_handler
if type pkgfile >/dev/null ; then
  source "/usr/share/doc/pkgfile/command-not-found.zsh" >/dev/null 2>&1 || source ~/.config/zsh/plugins/pkgfile/command-not-found.zsh >/dev/null 2>&1
fi
######

### Pyenv ###
# pyenv: https://github.com/pyenv/pyenv#basic-github-checkout
# pyenv-virtualenv: https://github.com/pyenv/pyenv-virtualenv#installing-as-a-pyenv-plugin
# ZSH autocompletion: https://github.com/pyenv/pyenv#advanced-configuration
if type pyenv >/dev/null ; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
  source ~/.config/pyenv/pyenv/completions/pyenv.zsh >/dev/null 2>&1
fi
######

### Load custom shell functions
autoload -Uz extract
autoload -Uz compinit
compinit -d "${_zsh_cache_dir}/zcompdump"
autoload -Uz custom_colors
custom_colors
# SARS-CoV-2 stats
autoload -Uz corona
######

#### HOW TO INSTALL PLGUINS & THEMES ####
#                                       #
#       !!! Use git submodules !!!      #
#                                       # # Example:
# git submodule add -b master <repo>    # # cd ~ && git submodule add -b master https://github.com/zsh-users/zsh-completions.git zsh/plugins/zsh-completions
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
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon ssh root_indicator dir dir_writable vcs virtualenv)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(context command_execution_time status)
POWERLEVEL9K_CONTEXT_TEMPLATE="%n"
#POWERLEVEL9K_ALWAYS_SHOW_USER=true
DEFAULT_USER=$USER
POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=5
POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=2
POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND="black"
POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND="yellow"
POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND="blue"
POWERLEVEL9K_STATUS_ERROR_BACKGROUND="white"
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_FOREGROUND="white"
POWERLEVEL9K_STATUS_VERBOSE=false
POWERLEVEL9K_TIME_BACKGROUND="black"
POWERLEVEL9K_TIME_FOREGROUND="gray"
POWERLEVEL9K_TIME_FORMAT="%D{%H:%M}"
POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR='\uE0C6'
POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR='\uE0C6'
POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR='\uE0B2'
POWERLEVEL9K_LEGACY_ICON_SPACING=true
ZLE_RPROMPT_INDENT=0
OWERLEVEL9K_INSTANT_PROMPT=verbose
source "${ZDOTDIR}/themes/powerlevel10k/powerlevel10k.zsh-theme"

### Start tmux
#if [ -z "$TMUX" ]; then
#  tmux new-session -A -s workspace
#fi
