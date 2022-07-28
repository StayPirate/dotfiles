#!/bin/bash

# Create a lock file to mark this script as executed once
touch $HOME/.config/dotfiles/first_run

# Dotfiles repositories addresses
DOTFILES_HTTPS=https://github.com/StayPirate/dotfiles.git
DOTFILES_SSH=github.com:StayPirate/dotfiles.git

DOTFILES_PRIVATE_HTTPS=https://github.com/StayPirate/dotfiles-private.git
DOTFILES_PRIVATE_SSH=git@github.com:StayPirate/dotfiles-private.git

DOFTILES_ROOT_HTTPS=https://github.com/StayPirate/dotfiles-root.git
DOFTILES_ROOT_SSH=git@github.com:StayPirate/dotfiles-root.git

dotfiles() { git --git-dir="${HOME}/.config/dotfiles/public" --work-tree="${HOME}" "${@}"; }
dotfiles-private() { git --git-dir="${HOME}/.config/dotfiles/private" --work-tree="${HOME}" "${@}"; }
dotfiles-root() { sudo git --git-dir="${HOME}/.config/dotfiles/root" --work-tree=/ "${@}"; }

export -f dotfiles
export -f dotfiles-private
export -f dotfiles-root

# Enabling pyenv-virtualenv plugin in pyenv
# it needs to be done here as the `${HOME}/.config/pyenv/pyenv/plugins` folder is created only after the pyenv submodule
# was initialized. Hence, I cannot simply add the symbolic link to my dotfiles.
if [[ -d "${HOME}/.config/pyenv/pyenv/plugins" && ! -L "${HOME}/.config/pyenv/pyenv/plugins/pyenv-virtualenv" ]]; then
    ln -s "${HOME}/.config/pyenv/pyenv-virtualenv" "${HOME}/.config/pyenv/pyenv/plugins"
fi

# Ask the user which submodules enable (if there are any disabled)
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

# Fetch git commits via HTTPS is handy as you can pull them without authentication (if public repo),
# while push commits via SSH is good as you are automatically authenticated.
# For this reason I set the remote pull url with HTTPS and push url with GIT
# Example: > dot remote -v
#          origin  https://github.com/StayPirate/dotfiles.git (fetch)
#          origin  git@github.com:StayPirate/dotfiles.git (push)
dotfiles remote set-url --push origin git@github.com:StayPirate/dotfiles.git > /dev/stderr

# This is a very important step.
# As we use $HOME as worktree, all the contained files will be listed as `untracked` when you type
# something like `dot status`, making the dotfiles management via git almost impossible.
# Setting status.showUntrackedFiles to no will stop this behavior in git, and only the manually added
# files will be shown in git output. So, you just need to use `git add file_x` to make file_x versionated
# in git.
dotfiles config --local status.showUntrackedFiles no > /dev/stderr

# Lets try to clone dotfiles-private and dotfiles-root as bare repositories as well.
# These are private repositories, so it will fail if the user is not authorized to access them (ssh-key).

# If git clone succeeded
if git clone --bare $DOTFILES_PRIVATE_HTTPS ~/.config/dotfiles/private 2>&1; then
    # If the bare repo si correctly instantiated
    if [[ -f $HOME/.config/dotfiles/private/HEAD ]]; then
        # Set remote push url via git
        dotfiles-private remote set-url --push origin git@$DOTFILES_PRIVATE_SSH > /dev/stderr
        # Do not shown untracked files
        dotfiles-private config --local status.showUntrackedFiles no > /dev/stderr
        # Copy all the files in the repository to $HOME. Please note that -f to overwrite existing files
        dotfiles-private checkout -f
    fi
fi

# If git clone succeeded
if git clone --bare $DOTFILES_ROOT_HTTPS ~/.config/dotfiles/root 2>&1; then
    # If the bare repo si correctly instantiated
    if [[ -f $HOME/.config/dotfiles/root/HEAD ]]; then
        # Set remote push url via git
        dotfiles-root remote set-url --push origin git@$DOTFILES_ROOT_SSH > /dev/stderr
        # Do not shown untracked files
        dotfiles-root config --local status.showUntrackedFiles no > /dev/stderr
        # Copy all the files in the repository to $HOME. Please note that -f to overwrite existing files
        dotfiles-root checkout -f
    fi
fi

# Remove .zcompdump in the home, new cache location is "${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
[[ -f $HOME/.zcompdump ]] && rm $HOME/.zcompdump

# Check disabled custom systemd services and ask the user if want to start and enable them
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
