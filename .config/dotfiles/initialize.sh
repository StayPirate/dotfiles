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

# Enabling OMG plugin for OSC (osc maintenance plugin)
dotfiles config -f .gitmodules --get-regexp osc-plugins.\*update | grep -q none
if [[ $? -ne 0 ]]; then
    echo "[.] Installing OMG plugin for OSC"
    # Install dependecies
    echo -e "\t[*] Install dependecies"
    type pip >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then 
        echo -e "\t[!] Cannot install python dependencies: pip is missing"
    else
        pip install git+https://gitlab.suse.de/tools/maintenance-toolkit.git >/dev/stderr
        [[ $? -ne 0 ]] || echo -e "\t[.] Maintenance ToolKit (MTK) installed" && echo -e "\t[!] Maintenance ToolKit (MTK) installation failed"
        pip install git+https://gitlab.suse.de/tools/checkers.git >/dev/stderr
        [[ $? -ne 0 ]] || echo -e "\t[.] Checkers installed" && echo -e "\t[!] Checkers installation failed"
    fi
    if [[ -f "${HOME}/.osc-plugins/osc-plugin-omg.py" ]]; then
        ln -s "${HOME}/.config/osc/osc-plugins/osc-plugin-omg.py" "${HOME}/.osc-plugins"
    fi
    if [[ -f "${HOME}/.osc-plugins/osc-edit.py" ]]; then
        ln -s "${HOME}/.config/osc/osc-plugins/osc-edit.py" "${HOME}/.osc-plugins"
    fi
    if [[ -d "${HOME}/.osc-plugins/omg" ]]; then
        ln -s "${HOME}/.config/osc/osc-plugins/omg" "${HOME}/.osc-plugins"
    fi
    echo "[.] OMG plugin installed"
else
    # If osc-plugins submodule is disable, ensure symlinks don't exist
    if [[ -L "${HOME}/.osc-plugins/osc-plugin-omg.py" ]]; then
        rm "${HOME}/.osc-plugins/osc-plugin-omg.py"
    fi
    if [[ -L "${HOME}/.osc-plugins/osc-edit.py" ]]; then
        rm "${HOME}/.osc-plugins/osc-edit.py"
    fi
    if [[ -L "${HOME}/.osc-plugins/omg" ]]; then
        rm "${HOME}/.osc-plugins/omg"
    fi
fi

# Enabling pyenv-virtualenv plugin in pyenv
if [[ -d "${HOME}/.config/pyenv/pyenv/plugins" && ! -L "${HOME}/.config/pyenv/pyenv/plugins/pyenv-virtualenv" ]]; then
    ln -s "${HOME}/.config/pyenv/pyenv-virtualenv" "${HOME}/.config/pyenv/pyenv/plugins"
fi

# Remove .zcompdump in the home, new cache location is "${_zsh_cache_dir}/zcompdump"
[[ -f $HOME/.zcompdump ]] && rm $HOME/.zcompdump

# Check disabled custom services
systemctl --user daemon-reload
for unit in `find $HOME/.config/systemd/user -maxdepth 1 -type f -printf "%f\n"`; do
    systemctl --user is-enabled --quiet $unit
    if [[ $? -ne 0 ]]; then
        read -p "[systemd] do you want enable ${unit}? [y/N] " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo
            systemctl --user enable --quiet $unit
            systemctl --user start $unit
        fi
    fi
done

# Ensure execution flag is granted to custom executables
for executable in `ls -A $HOME/.local/user_bin/*`; do
    chmod +x "${executable}"
done
