# .zshenv is sourced on all invocations of the shell, unless the -f option is set.
# It should contain commands to set the command search path, plus other important 
# environment variables. 
# .zshenv should not contain commands that produce output or assume the shell is
# attached to a tty.

# Loading variable shared with the instalation script
source $DOTFILES/vars

export XDG_CONFIG_HOME=${_xdg_config_home}

# $ZDOTDIR is specified in $HOME/.zprofile
typeset -U PATH path
path=("${_pyenv_dir}/bin" "${_pyenv_dir}/shims" "${_bin_dir}" "${HOME}/.local/bin" "${DOTFILES}/tmux/powerline/scripts" "$path[@]")
export PATH

typeset -U FPATH fpath
fpath=("${_zsh_dir}/plugins/zsh-completions/src" "${_zsh_dir}/functions" "${fpath[@]}")
export FPATH

export SHELL="/usr/bin/zsh"
export TERM="xterm-256color"
export EDITOR="vim"

# better yaourt colors
export YAOURT_COLORS="nb=1:pkg=1:ver=1;32:lver=1;45:installed=1;42:grp=1;34:od=1;41;5:votes=1;44:dsc=0:other=1;35"

# less history
export LESSHISTFILE="${_less_cache_dir}/history"
export LESSHISTSIZE=10000

# Powerline
# Load powerline python module
typeset -aTU PYTHONPATH pythonpath
pythonpath=("${DOTFILES}/tmux/powerline")
export PYTHONPATH
export POWERLINE_CONFIG_COMMAND="${DOTFILES}/tmux/powerline/scripts/powerline-config"

# Pyenv
# https://github.com/pyenv/pyenv#environment-variables
# https://github.com/pyenv/pyenv-virtualenv#special-environment-variables
export PYENV_ROOT="${_pyenv_dir}"
export PYTHON_BUILD_ARIA2_OPTS="-x 10 -k 1M"
export PYENV_VIRTUALENV_CACHE_PATH="${_pyenv_virtualenv_cache_dir}"