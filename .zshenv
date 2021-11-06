# .zshenv is sourced on all invocations of the shell, unless the -f option is set.
# It should contain commands to set the command search path, plus other important 
# environment variables. 
# .zshenv should not contain commands that produce output or assume the shell is
# attached to a tty.

# Loading variable shared with the instalation script
source ~/.config/dotfiles/vars

export XDG_CONFIG_HOME=${_xdg_config_home}

# $ZDOTDIR is specified in $HOME/.zprofile
typeset -U PATH path
path=("${_pyenv_installation_dir}/bin" "${HOME}/.local/bin" "${_tmux_dir}/powerline/scripts" "$path[@]")
export PATH

typeset -U FPATH fpath
fpath=("${HOME}/.config/zsh/plugins/zsh-completions/src" "${HOME}/.config/zsh/functions" "${fpath[@]}")
export FPATH

export SHELL="/usr/bin/zsh"
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
export LESSHISTFILE="${_less_cache_dir}/history"
export LESSHISTSIZE=10000

# Use bat as a colorizing pager for man
# https://github.com/sharkdp/bat/#man
type bat > /dev/null 2>&1 && export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Powerline
# Load powerline python module
typeset -aTU PYTHONPATH pythonpath
pythonpath=("${_tmux_dir}/powerline" "${HOME}/.local/bin/repos/asciinema")
export PYTHONPATH
export POWERLINE_CONFIG_COMMAND="${_tmux_dir}/powerline/scripts/powerline-config"

# Pyenv
# https://github.com/pyenv/pyenv#environment-variables
# https://github.com/pyenv/pyenv-virtualenv#special-environment-variables
export PYENV_ROOT="${_pyenv_root_dir}"
export PYTHON_BUILD_ARIA2_OPTS="-x 10 -k 1M"
export PYENV_VIRTUALENV_CACHE_PATH="${_pyenv_virtualenv_cache_dir}"
eval "$(pyenv init --path)"
