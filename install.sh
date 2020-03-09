#!/bin/bash

#===============================================================================
#                           Dotfiles' installation script.
#
#   It first creates the symlink `~/.dotfiles` pointing to the local copy of 
#   the dotfiles' repo, so you can clone this repo wherever you prefer on your
#   filesystem.
#   You can customize this folder changing the _dotfiles_dir var. 
#   Default: ~/.dotfiles
#
#   Then, it proceeds to create symlinks for all the contained dotfiles.
#   That will help you to manage everythin from a single directory.
#   
#   External plugins, themes, etc. are managed as git submodules. This will
#   allow you to easily keep them updated with a single command.
#
#===============================================================================

#==============
# Variables
source ./vars
#===================================

#==============
# Functions

function create_safe_symlink {
    _src=$(pwd)${1}
    _dst=${2}

    if [ ! -e "$_dst" ]; then
        ln -s "$_src" "$_dst"
        return 0
    else
        echo "${_dst} exists, symlink not created."
        return 1
    fi

    unset _src
    unset _dst
}
#===================================

#==============
# Main

# Initialize submodules
git submodule update --init --recursive

# Create a symlink pointing to the local
# copy of the repo at _dotfiles_dir
if ! create_safe_symlink "" "${_dotfiles_dir}"; then
    if [ $(readlink "${_dotfiles_dir}") == $(pwd) ]; then
        echo "${_dotfiles_dir} is already pointing to this repository."
        echo "Continue the installation..."
    else
        echo "${_dotfiles_dir} is not pointing to this repository."
        echo "Aborting installation."
        exit 1
    fi
fi

########
### ZSH
echo "export DOTFILES_DIR=\"${_dotfiles_dir}\"" >> zsh/.zprofile
create_safe_symlink "/zsh/.zprofile" ~/".zprofile"
create_safe_symlink "/zsh" $_zsh_dir
[ -d $_zsh_cache_dir ] || mkdir -p $_zsh_cache_dir

########
### SYSTEMD USER UNITS
[ -d $_systemd_user_dir ] || mkdir -p $_systemd_user_dir
create_safe_symlink "/systemd/user" "${_systemd_user_dir}/user"
systemctl --user daemon-reload
echo "The following units are NOT enabled/started yet, do it manually."
for unit in `ls -A $_systemd_user_dir`; do
    echo -e "\t${unit}"
done

########
### BIN
create_safe_symlink "/bin" $_bin_dir
for executable in `ls -A $_bin_dir/*.sh`; do
    chmod +x "${executable}"
done

########
### FONTS
[ -d $_fonts_dir ] || mkdir -p $_fonts_dir
create_safe_symlink "/fonts/Hack Regular Nerd Font Complete.ttf" "${_fonts_dir}/Hack Regular Nerd Font Complete.ttf"
fc-cache

########
### LAUNCHERS
[ -d $_launchers_dir ] || mkdir -p $_launchers_dir
create_safe_symlink "/launchers/shield.desktop" "${_launchers_dir}/shield.desktop"

########
### ICONS
[ -d "${_icons_dir}/256x256/apps" ] || mkdir -p "${_icons_dir}/256x256/apps"
create_safe_symlink "/icons/shield.png" "${_icons_dir}/256x256/apps/shield.png"

########
### OTHERS
[ -d $_less_cache_dir ] || mkdir -p $_less_cache_dir
#===================================


#==============
# Check missing packages

declare -a tools=(
    "zsh"
    "fzf"
    "fc-cache"
    "less"
    "dircolors"
    "tmux"
    "vim"
    "git"
)

for tool in "${tools[@]}"; do
    type "$tool" >/dev/null 2>&1 || echo -e "\t${tool} is not installed"
done
#===================================