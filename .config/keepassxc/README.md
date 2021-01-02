# Disable Gnome Keyring in GNOME

In order to make keepassxc works as a local keyring (secret service integration) you first need to stop the gnome-keyring (if running) and disable it from starting at boot.

In Archlinux with Gnome, I found out that to successfully disable gnome-keyring, the following changes are required:

 * Append `Hidden=true` to the content of the following files:

       /etc/xdg/autostart/gnome-keyring-pkcs11.desktop
       /etc/xdg/autostart/gnome-keyring-ssh.desktop
       /etc/xdg/autostart/gnome-keyring-secrets.desktop

 * Rename the follwoing file by appending the suffix `.disabled`

       /usr/share/dbus-1/services/org.gnome.keyring.service
       /usr/share/dbus-1/services/org.freedesktop.secrets.service
       /usr/share/dbus-1/services/org.freedesktop.impl.portal.Secret.service

 * Comment-out the following line in `/etc/pam.d/gdm-autologin`

       session    optional                    pam_gnome_keyring.so auto_start

To quikly apply the described changes you can run [`./disable_gnome_keyring.sh`](disable_gnome_keyring.sh).