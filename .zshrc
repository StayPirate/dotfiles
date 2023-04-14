# .zshrc is sourced in interactive shells.

if [[ -z "$TMUX" && -z $DISPLAY && "$(tty)" = "/dev/tty1" ]]; then
  exec sway --unsupported-gpu
fi

# Initialize dotfiles the first time zsh is ran from $USER
if [[ ! -f "${HOME}/.config/dotfiles/first_run" ]]; then
  _dotfiles_init_log=$(mktemp -t dotfiles-init-XXXX.log -p ${XDG_RUNTIME_DIR:-/tmp})
  echo "Inizialization dotfiles, log at ${_dotfiles_init_log}"
  ${HOME}/.config/dotfiles/initialize.sh 2>$_dotfiles_init_log
fi

# Powerline Daemon: Fast and lightweight, with daemon support for even better performance.
# https://powerline.readthedocs.io/en/latest/usage/shell-prompts.html?#shell-prompts
powerline-daemon -q
# Do not execute tmux in tty6, this could be a fallback tty in case tmux doesn't work anymore
if [[ -z "$TMUX" && "$(tty)" != "/dev/tty6" ]]; then
  exec tmux new-session -A -s workspace
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

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
# setopt GLOBDOTS
# Simple correction of commands
setopt CORRECT
# On an ambiguous completion insert the first match immediately.
setopt MENU_COMPLETE
# Turns on interactive comments
setopt INTERACTIVECOMMENTS
######

### GPG initialization for pinentry-tty and pinentry-curses
# https://www.gnupg.org/documentation/manuals/gnupg/Invoking-GPG_002dAGENT.html
# https://wiki.archlinux.org/title/GnuPG#Configure_pinentry_to_use_the_correct_TTY
# https://unix.stackexchange.com/a/608921 ($GPG_TTY = not a tty)
export GPG_TTY=$TTY

### KEY BINDING
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Movement
bindkey -e

bindkey '\e[1;5C' forward-word;     # CTRL+[right]
bindkey '\e[1;5D' backward-word;    # CTRL+[left]
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

### NVM - NODEJS VIRTUALENV ###
# https://github.com/nvm-sh/nvm
# zsh completion: https://github.com/nvm-sh/nvm/blob/a284af9228a62656e32eacfb0928faaeee8a124d/bash_completion#L83-L97
source $HOME/.local/bin/repos/nvm/nvm.sh
# zsh virtualenv autoload: https://github.com/nvm-sh/nvm#zsh
# I customized it a little bit to better keep the correct version while changing folders
autoload -Uz load-nvmrc
######

### ZSH STYLE ###
# Do menu-driven completion.
zstyle ':completion:*' menu select
# Show commands in groups
zstyle ':completion:*' group-name ''
zstyle ':completion:*' format '%B---- %d%b'
# tldr autocompletion
compctl -s "$(tldr 2>/dev/null --list)" tldr
######

# Load aliases
for f in `find ~/.config/zsh/alias.d -name "*.alias" | sort -n`; do
  source "$f"
done

### Hook Functions ###
# http://zsh.sourceforge.net/Doc/Release/Functions.html#Hook-Functions
# Executed whenever the current working directory is changed.
chpwd() { load-nvmrc }
######

### FZF ###
if type fzf >/dev/null ; then
  source ~/.config/zsh/plugins/fzf/shell/completion.zsh >/dev/null 2>&1
  source ~/.config/zsh/plugins/fzf/shell/key-bindings.zsh >/dev/null 2>&1
  # Override key-bindings with a custom one which uses `history` instead of `fc`
  source ~/.config/zsh/plugins/fzf-custom/history_widget.zsh >/dev/null 2>&1
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
autoload -Uz cert-fp
compinit -d "${XDG_CACHE_HOME}/zcompdump"
autoload -Uz custom_colors # load ~/.config/zsh/dir_colors
custom_colors
######

### hass-cli autocompletion ###
# https://github.com/home-assistant-ecosystem/home-assistant-cli#auto-completion
# Needs to be run after compinit is loaded
eval "$(_HASS_CLI_COMPLETE=zsh_source hass-cli)"
######

### LOAD PLUGINS ###
# zsh-syntax-highlighting
# https://github.com/zsh-users/zsh-syntax-highlighting
# source "${HOME}/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
# fast-syntax-highlighting
# https://github.com/zdharma/fast-syntax-highlighting
source "${HOME}/.config/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
# zsh-autosuggestions
# https://github.com/zsh-users/zsh-autosuggestions
source "${HOME}/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

### LOAD THEMES ###
# Powerlevel9k
# https://github.com/Powerlevel9k/powerlevel9k
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_LINUX_MANJARO_ICON='\uf303'
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon ssh root_indicator dir dir_writable vcs nvm virtualenv)
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
source "${HOME}/.config/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme"
