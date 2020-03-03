# .zprofile is similar to .zlogin, except that it is sourced before .zshrc.
# .zprofile is meant as an alternative to .zlogin for ksh fans; the two are 
# not intended to be used together, although this could certainly be done if 
# desired.
# .zprofile is not the place for alias definitions, options, environment variable
# settings, etc.; as a general rule, it should not change the shell environment
# at all. Rather, it should be used to set the terminal type and run a series
# of external commands (fortune, msgs, etc). 

export ZDOTDIR="$HOME/.config/zsh"
