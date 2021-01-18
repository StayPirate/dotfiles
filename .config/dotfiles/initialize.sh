#!/bin/bash

# Create a lock file to show the first run has been executed
touch $HOME/.config/dotfiles/first_run

dotfiles() { git --git-dir="${HOME}/.config/dotfiles/public" --work-tree="${HOME}" "${@}"; }
export -f dotfiles

# A HTTPS pull url is useful to fetch new commits without authentication (it's a public repo),
# while a SSH push url is useful to push new commits via authentication
dotfiles remote set-url --push origin git@github.com:StayPirate/dotfiles.git

# Stop dotfiles to show untracked files in $HOME
dotfiles config --local status.showUntrackedFiles no

# Enabling pyenv-virtualenv plugin in pyenv
if [[ -d "${HOME}/.config/pyenv/pyenv/plugins" && ! -L "${HOME}/.config/pyenv/pyenv/plugins/pyenv-virtualenv" ]]; then
    ln -s "${HOME}/.config/pyenv/pyenv-virtualenv" "${HOME}/.config/pyenv/pyenv/plugins"
fi

# Check disabled submodules
IFS=$'\n'
_disabled_submodules=($(dotfiles config -f .gitmodules --get-regexp update | grep none | awk '{print $1}' | cut -d '.' -f2))
unset IFS

[ ${#_disabled_submodules[@]} -eq 0 ] || echo "The following submodules are disabled:"
for _disabled_submodule in "${_disabled_submodules[@]}"; do
    read -p "${_disabled_submodule}, do you want to enable it? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Qui non funziona, in quanto anche cambiando to checkout, su 
        dotfiles config --local submodule.$_disabled_submodule.update checkout
        dotfiles submodule update --quiet --init --recursive >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            echo -e "\t${_disabled_submodule} cannot be cloned, and will be disbaled again."
            dotfiles config --local submodule.$_disabled_submodule.update none
        fi
    fi
done

# Remove .zcompdump in the home, new cache location is "${_zsh_cache_dir}/zcompdump"
[[ -f $HOME/.zcompdump ]] && rm $HOME/.zcompdump

# Check disabled custom services
systemctl --user daemon-reload
for unit in `find $HOME/.config/systemd/user -maxdepth 1 -type f -printf "%f\n"`; do
    systemctl --user is-enabled --quiet $unit
    if [[ $? -ne 0 ]]; then
        read -p "[systemd] do you want enable ${unit}? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            systemctl --user enable --quiet $unit
            systemctl --user start $unit
        fi
    fi
done

# Ensure execution flag is granted to custom executables
for executable in `ls -A $HOME/.local/user_bin/*`; do
    chmod +x "${executable}"
done
