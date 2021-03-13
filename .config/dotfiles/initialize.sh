#!/bin/bash

# Create a lock file to mark this script as executed once
touch $HOME/.config/dotfiles/first_run

dotfiles() { git --git-dir="${HOME}/.config/dotfiles/public" --work-tree="${HOME}" "${@}"; }
dotfiles-pvt() { git --git-dir="${HOME}/.config/dotfiles/private/.git" --work-tree="${HOME}" "${@}"; }
dotfiles-root() { sudo git --git-dir="${HOME}/.config/dotfiles/root/.git" --work-tree=/ "${@}"; }
export -f dotfiles
export -f dotfiles-pvt
export -f dotfiles-root

# Enabling pyenv-virtualenv plugin in pyenv
if [[ -d "${HOME}/.config/pyenv/pyenv/plugins" && ! -L "${HOME}/.config/pyenv/pyenv/plugins/pyenv-virtualenv" ]]; then
    ln -s "${HOME}/.config/pyenv/pyenv-virtualenv" "${HOME}/.config/pyenv/pyenv/plugins"
fi

# List disabled submodules
IFS=$'\n'
_disabled_submodules=($(dotfiles config --local --get-regexp update | grep none | awk '{print $1}' | cut -d '.' -f2))
unset IFS

[ ${#_disabled_submodules[@]} -eq 0 ] || echo "The following submodules are disabled:"
for _disabled_submodule in "${_disabled_submodules[@]}"; do
    read -p "${_disabled_submodule}, do you want to enable it? [y/N] " -n 1 -r 2>&1
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        dotfiles config --local submodule.$_disabled_submodule.update checkout
        dotfiles submodule update --quiet --init --recursive >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            echo -e "\t${_disabled_submodule} cannot be cloned, and will be disbaled again."
            dotfiles config --local submodule.$_disabled_submodule.update none
        fi
    fi
done

# A HTTPS pull url is useful to fetch new commits without authentication (it's a public repo),
# while a SSH push url is handy to push new commits via Github keyfile authentication
dotfiles remote set-url --push origin git@github.com:StayPirate/dotfiles.git > /dev/stderr

# Stop dotfiles to show untracked files
dotfiles config --local status.showUntrackedFiles no > /dev/stderr
# If dotfiles-pvt doesn't return an error, it means it has been successfully enabled previously
# then the user can proceed with the checkout of the files. Use -f to overwrite existing files
dotfiles-pvt config --local status.showUntrackedFiles no > /dev/stderr
[[ $? -eq 0 ]] && dotfiles-pvt checkout -f > /dev/stderr
# If dotfiles-root doesn't return an error, it means it has been successfully enabled previously
# then the user can proceed with the checkout of the files. Use -f to overwrite existing files
dotfiles-root config --local status.showUntrackedFiles no > /dev/stderr
[[ $? -eq 0 ]] && dotfiles-root checkout -f > /dev/stderr

# Remove .zcompdump in the home, new cache location is "${_zsh_cache_dir}/zcompdump"
[[ -f $HOME/.zcompdump ]] && rm $HOME/.zcompdump

# Check disabled custom services
systemctl --user daemon-reload
for unit in `find $HOME/.config/systemd/user -maxdepth 1 -type f -printf "%f\n"`; do
    systemctl --user is-enabled --quiet $unit
    if [[ $? -ne 0 ]]; then
        read -p "[systemd] do you want enable and start ${unit}? [y/N] " -n 1 -r 2>&1
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            systemctl --user enable --quiet $unit
            systemctl --user start $unit
        fi
    fi
done

# Ensure execution flag is granted to custom executables
for executable in `ls -A $HOME/.local/bin/*`; do
    chmod +x "${executable}"
done
