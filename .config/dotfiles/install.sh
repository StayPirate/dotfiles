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
echo "                [https://github.com/StayPirate/dotfiles]              "
echo -e "\n\n"
dotfiles() { git --git-dir="${HOME}/.config/dotfiles/public" --work-tree="${HOME}" "${@}"; }
export -f dotfiles
[ -z $XDG_RUNTIME_DIR ] && XDG_RUNTIME_DIR=/tmp
_log_file=$(mktemp -t dotfile-XXXX.log -p $XDG_RUNTIME_DIR)
echo -e "${_orange}[*]${_no_color} Instalaltion logs at ${_log_file}."

type git >/dev/null 2>&1
if [[ $? -ne 0 ]]; then echo -e "\t${_red}[!]${_no_color} Abort: git is not installed." && exit 1; fi

if [[ -f $HOME/.config/dotfiles/public/HEAD ]]; then
    echo -e "${_red}[!]${_no_color} Abort: a dotfiles repository exists in ${HOME}/.config/dotfiles/public."
    exit 1
fi

echo "[.] Cloning dotfiles repository..."
git clone --bare --branch homegit https://github.com/StayPirate/dotfiles.git ~/.config/dotfiles/public > "$_log_file" 2>&1
# FIXME:           ^^^^^^^^^^^^^^ remove after merge to master
if [[ $? -ne 0 ]]; then echo -e "${_red}[!]${_no_color} Abort: cannot clone the dotfiles repository." && exit 1; fi
dotfiles switch homegit > "$_log_file" 2>&1
# FIXME: ^^^^^^^^^^^^^^ remove after merge to master
echo "[.] Branch checkout to ${HOME}"
cd $HOME && dotfiles checkout > "$_log_file" 2>&1
if [[ $? -ne 0 ]]; then
    IFS=$'\n'
    # Get the list of files that cannot be checked out because already exist in the worktree (in this case $HOME)
    _existing_files=($(dotfiles checkout 2>&1 | grep -E "^[[:space:]]+" | sed 's/^\s*//' | sort -u))
    unset IFS
    _now=$(date +"%Y%m%d_%H%M%S")
    echo "[.] Backing up the following file in ${HOME}/.config/dotfiles/backup-${_now}:"
    for _existing_file in "${_existing_files[@]}"; do
        echo -e "\t${_existing_file}"
        _file_dir="$(dirname "$_existing_file")"
        mkdir -p "${HOME}/.config/dotfiles/backup-${_now}/${_file_dir}"
        mv "${_existing_file}" "${HOME}/.config/dotfiles/backup-${_now}/${_existing_file}" > "$_log_file" 2>&1
    done
    dotfiles checkout > "$_log_file" 2>&1
    if [[ $? -ne 0 ]]; then
        echo -e "${_orange}[*]${_no_color} Something went wrong during the branch checkout, please check the logs."
    fi
fi
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
        # Check if $USER can sudo and try to set zsh as default shell
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

echo -e "${_green}[*]${_no_color} Installation done"
