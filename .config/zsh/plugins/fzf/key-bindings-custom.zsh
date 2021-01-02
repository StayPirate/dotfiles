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
    FZF_DEFAULT_OPTS="--tac --height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd)) )
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