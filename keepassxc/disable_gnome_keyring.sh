#!/bin/sh
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

declare -a autostart_files=(
    "/etc/xdg/autostart/gnome-keyring-pkcs11.desktop"
    "/etc/xdg/autostart/gnome-keyring-ssh.desktop"
    "/etc/xdg/autostart/gnome-keyring-secrets.desktop"
)

declare -a services_units=(
    "/usr/share/dbus-1/services/org.gnome.keyring.service"
    "/usr/share/dbus-1/services/org.freedesktop.secrets.service"
    "/usr/share/dbus-1/services/org.freedesktop.impl.portal.Secret.service"
)

gdm_autologin=/etc/pam.d/gdm-autologin

# Hide autostart gnome-keyring desktop files
for file in "${autostart_files[@]}"; do
    if [[ -f "${file}" && $(grep -cE "^Hidden=true$" "${file}") -eq 0 ]]; then
        echo "Hidden=true" >> "${file}"
        if [ $? -eq 0 ]; then
            echo "${file} is now hidden"
        fi
    fi
done

# Disable units by appending the suffix .disabled
for unit in "${services_units[@]}"; do
    if [[ -f "${unit}" ]]; then
        mv "${unit}" "${unit}.disabled"
        if [ $? -eq 0 ]; then
            echo "${file} is now disabled"
        fi
    fi
done

# Dsiable gnome_keyring PAM module
if grep -qE "^session*[[:space:]]*optional[[:space:]]*pam_gnome_keyring.so auto_start$" $gdm_autologin; then
    sed -e '/^[^#].*pam_gnome_keyring.so auto_start$/s/^/#/g' -i $gdm_autologin
    echo "Autostart PAM gnome_keyring module disabled"
fi