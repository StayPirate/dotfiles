#!/bin/bash

#===============================================================================
#                           Dotfiles' installation script.
#
#   It first creates the symlink `~/.dotfiles` pointing to the local copy of 
#   the dotfiles' repo, so you can clone this repo wherever you prefer on your
#   filesystem.
#   You can customize this folder changing the _dotfiles_link var. 
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

    _local_dotfiles_link=NOTEXIST
    [ -L $_dotfiles_link ] && _local_dotfiles_link=$_dotfiles_link

    if [ ! -e "$_dst" ]; then
        ln -s "$_src" "$_dst"
    elif [ -L "$_dst" ]; then
        if [[ ! $(readlink "$_dst") == "$_src" ]] && [[ ! $(readlink "$_dst") == "${_local_dotfiles_link}${1}" ]]; then
            echo "\"${_dst}\" exists and is not pointing to \"${_src}\" or \"${_local_dotfiles_link}${1}\": Left untouched."
            unset _src
            unset _dst
            unset _dot
            return 1
        fi
    else
        echo "\"${_dst}\" exists and is not a symbolic link: Left untouched."
    fi

    unset _src
    unset _dst
    unset _dot
    return 0
}
#===================================

#==============
# Main

# Initialize submodules
if ! git submodule update --init --recursive; then
    echo "### Aborting: Submodules initialization FAILED ###"
    exit 1
fi
# Override origin/push to push it via ssh
# while fetching via HTTPS
git remote set-url --push origin git@github.com:StayPirate/dotfiles.git

# Create a symlink `_dotfiles_link` pointing
# to the local copy of the repo
if ! create_safe_symlink "" "${_dotfiles_link}"; then
    if [ $(readlink "${_dotfiles_link}") == $(pwd) ] || [ ${_dotfiles_link} == $(pwd) ]; then
        echo "${_dotfiles_link} is already pointing to this repository."
        echo "Continue the installation..."
    else
        echo "${_dotfiles_link} is not pointing to this repository."
        echo "Aborting installation."
        exit 1
    fi
fi

########
### ENVIRONMENT VARIABLES
# Xorg compatibility
grep "DOTFILES" zsh/.zprofile >/dev/null 2>&1 || echo "export DOTFILES=\"${_dotfiles_link}\"" >> zsh/.zprofile
# Lightdm compatibility
# https://superuser.com/questions/597291/xfce-lightdm-startup-configuration-files#comment1478463_687401
grep "zprofile" ~/.xsessionrc >/dev/null 2>&1 || echo ". \$HOME/.zprofile" >> ~/.xsessionrc
# Wayland compatibility (check below #SYSTEMD_ENVIRONMENT_VARIABLES)
grep "DOTFILES" systemd/environment.d/00-dotfiles.conf >/dev/null 2>&1 || echo "DOTFILES=\"${_dotfiles_link}\"" >> systemd/environment.d/00-dotfiles.conf

########
### ZSH
create_safe_symlink "/zsh/.zprofile" ~/".zprofile"
create_safe_symlink "/zsh" $_zsh_dir
[ -d $_zsh_cache_dir ] || mkdir -p $_zsh_cache_dir
[ -f "${_zsh_cache_dir}/zcompdump" ] && rm -f "${_zsh_cache_dir}/zcompdump"

########
### SYSTEMD ENVIRONMENT VARIABLES
# That works for GNOME on Wayland since the graphical terminal emulator runs as 
# the gnome-terminal-server.service user unit, which in turn runs the user shell, 
# so that shell will inherit environment variables exported by the user manager.
# https://jlk.fjfi.cvut.cz/arch/manpages/man/environment.d.5#APPLICABILITY
[ -d $_systemd_environmentd ] || mkdir -p $_systemd_environmentd
for conf in `ls -A systemd/environment.d`; do
    create_safe_symlink "/systemd/environment.d/${conf}" "${_systemd_environmentd}/${conf}"
done

########
### SYSTEMD USER UNITS
[ -d $_systemd_user_dir ] || mkdir -p $_systemd_user_dir
for unit in `ls -A systemd/user`; do
    create_safe_symlink "/systemd/user/${unit}" "${_systemd_user_dir}/${unit}"
done
systemctl --user daemon-reload
for unit in `ls -A systemd/user`; do
    systemctl --user is-enabled --quiet $unit || echo -e "[Service] ${unit} is not enabled"
done

########
### BIN
create_safe_symlink "/bin" $_bin_dir
for executable in `ls -A $_bin_dir/*`; do
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
### TMUX
create_safe_symlink "/tmux/powerline-custom" "${_xdg_config_home}/powerline"
create_safe_symlink "/tmux/tmux.conf" ~/".tmux.conf"

########
### Keepassxc
[ -d $_keepassxc_dir ] || mkdir -p $_keepassxc_dir
create_safe_symlink "/keepassxc/keepassxc.ini" "${_keepassxc_dir}/keepassxc.ini"

########
### Pyenv / Pyenv-Virtualenv
create_safe_symlink "/pyenv/pyenv-virtualenv" "${_pyenv_dir}/plugins/pyenv-virtualenv"
[ -d $_pyenv_virtualenv_cache_dir ] || mkdir -p $_pyenv_virtualenv_cache_dir

########
### OTHERS
[ -d $_less_cache_dir ] || mkdir -p $_less_cache_dir
#===================================


#==============
# Check missing packages

declare -a tools=(
    ### Essential
    "zsh"
    "fzf"
    "tmux"
    "vim"
    "git"
    ### Utility
    "fc-cache"
    "less"
    "dircolors"
    "htop"
    "pkgfile"
    "socat"
    "curl"
    "xclip"
    ### Extra
    "scrcpy"
    "keepassxc"
    ### Dependecies
    # Required by powerline's spotify segment
    "python-dbus"
)

_missing_pkgs=false
for tool in "${tools[@]}"; do
    type "$tool" >/dev/null 2>&1 || _missing_pkgs=true
done

if [ "$_missing_pkgs" = true ]; then
    read -p "Do you want to install missing packages? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        declare -A pkgmngr_cmd
        pkgmngr_cmd[archlinux]="sudo pacman --noconfirm --needed -Sy"
        pkgmngr_cmd[debian]="sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install"

        _distro=""
        if grep -i "arch" /etc/*-release >/dev/null 2>&1; then
            _distro="archlinux"
        elif grep -i "debian" /etc/*-release >/dev/null 2>&1; then
            _distro="debian"
        fi

        if [ -n $_distro ]; then
            echo "Packages installation (wait):"
            for tool in "${tools[@]}"; do
                type "$tool" >/dev/null 2>&1 || sh -c "${pkgmngr_cmd[$_distro]} $tool" >/dev/null 2>&1
            done
        else
            echo "Operative System not detected."
        fi
        unset _distro
    fi
fi

for tool in "${tools[@]}"; do
    type "$tool" >/dev/null 2>&1 || echo -e "\t${tool} is missing"
done

# Set zsh as default shell for the user
grep "$USER.*zsh.*" /etc/passwd >/dev/null 2>&1 || chsh -s $(which zsh) $USER

echo "### Notes ###"
echo -e "\t * Do not forget to change the font on your favorite terminal emulator."
echo -e "\t * In order to keep the dotfiles updated use: dotfiles-update"
#===================================