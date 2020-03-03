# .zshenv is sourced on all invocations of the shell, unless the -f option is set.
# It should contain commands to set the command search path, plus other important 
# environment variables. 
# .zshenv should not contain commands that produce output or assume the shell is
# attached to a tty.

typeset -U PATH path
path=("$HOME/.local/user_bin" "$path[@]")
export PATH
# $ZDOTDIR is specified in $HOME/.zprofile

export SHELL="/usr/bin/zsh"
export TERM="xterm-256color"

# better yaourt colors
export YAOURT_COLORS="nb=1:pkg=1:ver=1;32:lver=1;45:installed=1;42:grp=1;34:od=1;41;5:votes=1;44:dsc=0:other=1;35"

# less history
export LESSHISTFILE="$HOME/.config/less/history"
export LESSHISTSIZE=10000
