# .zshenv is sourced on all invocations of the shell, unless the -f option is set.
# It should contain commands to set the command search path, plus other important 
# environment variables. 
# .zshenv should not contain commands that produce output or assume the shell is
# attached to a tty.

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}

# User gem path
type gem >/dev/null && {
    export GEM_PATH="$(ruby -e 'print Gem.user_dir')/bin"
}

# $ZDOTDIR is specified in $HOME/.zprofile
typeset -U PATH path
path=("${XDG_CONFIG_HOME}/pyenv/pyenv/bin" "${HOME}/.local/bin" "${XDG_CONFIG_HOME}/tmux/powerline/scripts" "$path[@]" "$GEM_PATH" "${HOME}/.local/share/flatpak/exports/bin")
export PATH

typeset -U FPATH fpath
fpath=("${HOME}/.config/zsh/plugins/zsh-completions/src" "${HOME}/.config/zsh/functions" "${fpath[@]}")
export FPATH

export SHELL=$(which zsh)
export EDITOR="vim"
# Custom shell word boundaries, helpful when CTRL+W on paths.
# without: /
# with   : |
export WORDCHARS='*?_-.[]~=&;!#$&(){}<>|'

# better yaourt colors
export YAOURT_COLORS="nb=1:pkg=1:ver=1;32:lver=1;45:installed=1;42:grp=1;34:od=1;41;5:votes=1;44:dsc=0:other=1;35"

# Set delta as default git pager if available
type delta > /dev/null 2>&1 && export GIT_PAGER=delta
# less history
export LESSHISTFILE="${XDG_CACHE_HOME}/less/history"
export LESSHISTSIZE=10000

# Use bat as a colorizing pager for man
# https://github.com/sharkdp/bat/#man
type bat > /dev/null 2>&1 && export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Powerline
# Load powerline python module
typeset -aTU PYTHONPATH pythonpath
pythonpath=("${XDG_CONFIG_HOME}/tmux/powerline" "${HOME}/.local/bin/repos/asciinema")
export PYTHONPATH
export POWERLINE_CONFIG_COMMAND="${XDG_CONFIG_HOME}/tmux/powerline/scripts/powerline-config"

# Pyenv
# https://github.com/pyenv/pyenv#environment-variables
# https://github.com/pyenv/pyenv-virtualenv#special-environment-variables
export PYENV_ROOT="${XDG_CONFIG_HOME}/pyenv"
export PYTHON_BUILD_ARIA2_OPTS="-x 10 -k 1M"
export PYENV_VIRTUALENV_CACHE_PATH="${XDG_CACHE_HOME}/pyenv-virtualenv"
eval "$(pyenv init --path)"

# Sway
export XDG_CURRENT_DESKTOP=sway

# Wayland
export MOZ_ENABLE_WAYLAND=1 # Start Firefox natively on Wayland

# ssh-agent
# This var is also specified in .config/environment.d/10-ssh-agent.conf
# as it is required by .config/systemd/user/ssh-agent.service
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"