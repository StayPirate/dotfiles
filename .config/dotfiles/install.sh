#!/bin/bash

_red='\033[0;31m'
_orange='\033[0;33m'
_green='\033[0;32m'
_no_color='\033[0m'
echo -e "${_red}"
echo "     ▓█████▄  ▒█████  ▄▄▄█████▓  █████▒██▓ ██▓    ▓█████   ██████"
echo "     ▒██▀ ██▌▒██▒  ██▒▓  ██▒ ▓▒▓██   ▒▓██▒▓██▒    ▓█   ▀ ▒██    ▒"
echo "     ░██   █▌▒██░  ██▒▒ ▓██░ ▒░▒████ ░▒██▒▒██░    ▒███   ░ ▓██▄   "
echo "     ░▓█▄   ▌▒██   ██░░ ▓██▓ ░ ░▓█▒  ░░██░▒██░    ▒▓█  ▄   ▒   ██▒"
echo "     ░▒████▓ ░ ████▓▒░  ▒██▒ ░ ░▒█░   ░██░░██████▒░▒████▒▒██████▒▒"
echo "      ▒▒▓  ▒ ░ ▒░▒░▒░   ▒ ░░    ▒ ░   ░▓  ░ ▒░▓  ░░░ ▒░ ░▒ ▒▓▒ ▒ ░"
echo "      ░ ▒  ▒   ░ ▒ ▒░     ░     ░      ▒ ░░ ░ ▒  ░ ░ ░  ░░ ░▒  ░ ░"
echo "      ░ ░  ░ ░ ░ ░ ▒    ░       ░ ░    ▒ ░  ░ ░      ░   ░  ░  ░  "
echo "        ░        ░ ░                   ░      ░  ░   ░  ░      ░  "
echo "      ░                                                           "
echo -e "${_no_color}"
echo "                    - dotfiles installation script -                   "
echo "                [ https://github.com/StayPirate/dotfiles ]             "
echo -e "\n\n"
dotfiles() { git --git-dir="${HOME}/.config/dotfiles/public" --work-tree="${HOME}" "${@}"; }
export -f dotfiles

# Check if git is installed
type git >/dev/null 2>&1
if [[ $? -ne 0 ]]; then echo -e "\t${_red}[!]${_no_color} Abort: git is not installed." && exit 1; fi

# Abort installation if the dotfiles repository already exists in the system
if [[ -f $HOME/.config/dotfiles/public/HEAD ]]; then
    echo -e "${_red}[!]${_no_color} Abort: a dotfiles repository exists in ${HOME}/.config/dotfiles/public."
    exit 1
fi

# Create the installation log file
_log_file=$(mktemp -t dotfile-XXXX.log -p ${XDG_RUNTIME_DIR:-/tmp})
echo -e "${_orange}[*]${_no_color} Instalaltion logs at ${_log_file}."

# Clone the dotfiles bare repository
echo "[.] Cloning dotfiles repository..."
git clone --bare https://github.com/StayPirate/dotfiles.git ~/.config/dotfiles/public > "$_log_file" 2>&1

# Abort if git failed to clone the repo
if [[ $? -ne 0 ]]; then echo -e "${_red}[!]${_no_color} Abort: cannot clone the dotfiles repository." && exit 1; fi

# Populate the worktree
echo "[.] Branch checkout to ${HOME}"
cd $HOME && dotfiles checkout > "$_log_file" 2>&1

# It fails if files already exists in $HOME, in that case let's move all the involved files in a safe place
# (a backup folder) and try to populate again the $HOME
if [[ $? -ne 0 ]]; then
    IFS=$'\n'
    # Get the list of files that cannot be checked out because already exist in the worktree
    _existing_files=($(dotfiles checkout 2>&1 | grep -E "^[[:space:]]+" | sed 's/^\s*//' | sort -u))
    unset IFS
    # Create an unique backup folder
    _now=$(date +"%Y%m%d_%H%M%S")
    echo "[.] Backing up the following file in ${HOME}/.config/dotfiles/backup-${_now}:"
    # Move blocking files to the backup folder while keeping the same directory-tree
    for _existing_file in "${_existing_files[@]}"; do
        echo -e "\t${_existing_file}"
        _file_dir="$(dirname "$_existing_file")"
        mkdir -p "${HOME}/.config/dotfiles/backup-${_now}/${_file_dir}"
        mv "${_existing_file}" "${HOME}/.config/dotfiles/backup-${_now}/${_existing_file}" > "$_log_file" 2>&1
    done
    # Try again to populate the worktree, this time should work as no existing file with same name should exist in $HOME
    dotfiles checkout > "$_log_file" 2>&1
    # If keep failing there should be another problem, so abort the installation
    if [[ $? -ne 0 ]]; then
        echo -e "${_orange}[*]${_no_color} Something went wrong during the branch checkout, please check the logs."
    fi
fi

# Refresh font cache to include user's fonts
if type fc-cache >/dev/null 2>&1; then
    if fc-cache -f -v >/dev/null 2>&1; then
        echo -e "[.] Font cache refreshed."
    else
        echo -e "${_orange}[*]${_no_color} Font cache cannot be refreshed."
    fi
else
    echo -e "${_orange}[*]${_no_color} Font cache not refreshed: fc-cache not found."
fi

# Initialize submodules
echo "[.] Initializing git submodules"
dotfiles submodule update --init --recursive > "$_log_file" 2>&1

# Check if zsh is installed
type zsh >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
     echo -e "${_orange}[*]${_no_color} Zsh is not installed."
else
    # If zsh is installed, check if it's the default shell for $USER
    _zsh_is_not_default=true
    grep "$USER.*zsh.*" /etc/passwd >/dev/null 2>&1 && _zsh_is_not_default=false
    if [[ "$_zsh_is_not_default" = true ]]; then
        echo -e "${_orange}[*]${_no_color} Zsh is not the default shell for ${USER}"
        # If the $USER can sudo, try to set zsh as default shell
        sudo -l >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            echo "[.] Executing: sudo chsh -s $(which zsh) ${USER}"
            sudo chsh -s $(which zsh) $USER > "$_log_file"
            if [[ $? -ne 0 ]]; then
                echo -e "${_orange}[*]${_no_color} Cannot change the default shell, please ask an administrator."
            else
                echo -e "${_green}[*]${_no_color} Zsh is now the default shell, logout to make it effective."
            fi
            sudo -k > "$_log_file" 2>&1
        fi
    fi
fi

# If you are here the installation succeeded
echo -e "${_green}[*]${_no_color} Installation done"
