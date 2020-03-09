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
source zsh/vars.zsh
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
create_safe_symlink "/zsh/.zprofile" ~/".zprofile"
create_safe_symlink "/zsh" ~/".config/zsh"

########
### SYSTEMD USER UNITS
create_safe_symlink "/systemd/user" ~/".config/systemd/user"
echo "The following units are NOT enabled/started yet, do it manually."
for unit in `ls -A ~/.config/systemd/user`; do
    echo -e "\t${unit}"
done

########
### BIN
create_safe_symlink "/bin" ~/".local/user_bin"
for executable in `ls -A ~/.local/user_bin/*.sh`; do
    chmod +x "${executable}"
done

########
### FONTS
create_safe_symlink "/fonts/Hack Regular Nerd Font Complete.ttf" ~/".local/share/fonts/Hack Regular Nerd Font Complete.ttf"
fc-cache
#===================================

#=================
# Variables unset

unset _dotfiles_dir
#===================================
