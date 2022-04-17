#!/bin/bash

# NGNR OS scripter

# (GNU/General Public License version 3.0)

# ----------------------------------------
# Define Variables
# ----------------------------------------
#./opt/ngnrosrepo
LCLST="en_US"
# Format is language_COUNTRY where language is lower case two letter code
# and country is upper case two letter code, separated with an underscore

KEYMP="us"
# Use lower case two letter country code

KEYMOD="pc105"
# pc105 and pc104 are modern standards, all others need to be researched

MYUSERNM="live"
# use all lowercase letters only

MYUSRPASSWD="live"
# Pick a password of your choice

RTPASSWD="toor"
# Pick a root password

MYHOSTNM="NGNR OS"
# Pick a hostname for the machine

# ----------------------------------------
# Functions
# ----------------------------------------

# Test for root user
rootuser () {
  if [[ "$EUID" = 0 ]]; then
    continue
  else
    echo "Please Run As Root"
    sleep 2
    exit
  fi
}

# Display line error
handlerror () {
clear
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
}

# Clean up working directories
cleanup () {
[[ -d ./ngnrosreleng ]] && rm -r ./ngnrosreleng
[[ -d ./work ]] && rm -r ./work
[[ -d ./out ]] && mv ./out ../
sleep 2
}

# Requirements and preparation
prepreqs () {
pacman -S --noconfirm archlinux-keyring
pacman -S --needed --noconfirm archiso mkinitcpio-archiso
}

# Copy ngnrosreleng to working directory
cpngnrosreleng () {
cp -r /usr/share/archiso/configs/releng/ ./ngnrosreleng
rm -r ./ngnrosreleng/efiboot
rm -r ./ngnrosreleng/syslinux
}

# Copy ngnrosrepo to opt
cpngnrosrepo () {
cp -r ./opt/ngnrosrepo /opt/
}

# Remove ngnrosrepo from opt
rmngnrosrepo () {
rm -r /opt/ngnrosrepo
}

# Delete automatic login
nalogin () {
[[ -d ./ngnrosreleng/airootfs/etc/systemd/system/getty@tty1.service.d ]] && rm -r ./ngnrosreleng/airootfs/etc/systemd/system/getty@tty1.service.d
}

# Remove cloud-init and other stuff
rmunitsd () {
[[ -d ./ngnrosreleng/airootfs/etc/systemd/system/cloud-init.target.wants ]] && rm -r ./ngnrosreleng/airootfs/etc/systemd/system/cloud-init.target.wants
[[ -f ./ngnrosreleng/airootfs/etc/systemd/system/multi-user.target.wants/iwd.service ]] && rm ./ngnrosreleng/airootfs/etc/systemd/system/multi-user.target.wants/iwd.service
[[ -f ./ngnrosreleng/airootfs/etc/xdg/reflector/reflector.conf ]] && rm ./ngnrosreleng/airootfs/etc/xdg/reflector/reflector.conf
}

# Add Bluetooth, cups, haveged, NetworkManager, & sddm systemd links
addnmlinks () {
[[ ! -d ./ngnrosreleng/airootfs/etc/systemd/system/network-online.target.wants ]] && mkdir -p ./ngnrosreleng/airootfs/etc/systemd/system/network-online.target.wants
[[ ! -d ./ngnrosreleng/airootfs/etc/systemd/system/multi-user.target.wants ]] && mkdir -p ./ngnrosreleng/airootfs/etc/systemd/system/multi-user.target.wants
[[ ! -d ./ngnrosreleng/airootfs/etc/systemd/system/bluetooth.target.wants ]] && mkdir -p ./ngnrosreleng/airootfs/etc/systemd/system/bluetooth.target.wants
[[ ! -d ./ngnrosreleng/airootfs/etc/systemd/system/printer.target.wants ]] && mkdir -p ./ngnrosreleng/airootfs/etc/systemd/system/printer.target.wants
[[ ! -d ./ngnrosreleng/airootfs/etc/systemd/system/sockets.target.wants ]] && mkdir -p ./ngnrosreleng/airootfs/etc/systemd/system/sockets.target.wants
[[ ! -d ./ngnrosreleng/airootfs/etc/systemd/system/timers.target.wants ]] && mkdir -p ./ngnrosreleng/airootfs/etc/systemd/system/timers.target.wants
[[ ! -d ./ngnrosreleng/airootfs/etc/systemd/system/sysinit.target.wants ]] && mkdir -p ./ngnrosreleng/airootfs/etc/systemd/system/sysinit.target.wants
ln -sf /usr/lib/systemd/system/NetworkManager-wait-online.service ./ngnrosreleng/airootfs/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service
ln -sf /usr/lib/systemd/system/NetworkManager-dispatcher.service ./ngnrosreleng/airootfs/etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service
ln -sf /usr/lib/systemd/system/NetworkManager.service ./ngnrosreleng/airootfs/etc/systemd/system/multi-user.target.wants/NetworkManager.service
ln -sf /usr/lib/systemd/system/bluetooth.service ./ngnrosreleng/airootfs/etc/systemd/system/bluetooth.target.wants/bluetooth.service
ln -sf /usr/lib/systemd/system/haveged.service ./ngnrosreleng/airootfs/etc/systemd/system/sysinit.target.wants/haveged.service
ln -sf /usr/lib/systemd/system/cups.service ./ngnrosreleng/airootfs/etc/systemd/system/printer.target.wants/cups.service
ln -sf /usr/lib/systemd/system/cups.socket ./ngnrosreleng/airootfs/etc/systemd/system/sockets.target.wants/cups.socket
ln -sf /usr/lib/systemd/system/cups.path ./ngnrosreleng/airootfs/etc/systemd/system/multi-user.target.wants/cups.path
ln -sf /usr/lib/systemd/system/bluetooth.service ./ngnrosreleng/airootfs/etc/systemd/system/dbus-org.bluez.service
ln -sf /usr/lib/systemd/system/sddm.service ./ngnrosreleng/airootfs/etc/systemd/system/display-manager.service
}

# Copy files to customize the ISO
cpmyfiles () {
cp packages.x86_64 ./ngnrosreleng/
cp pacman.conf ./ngnrosreleng/
cp profiledef.sh ./ngnrosreleng/
cp -r efiboot ./ngnrosreleng/
cp -r syslinux ./ngnrosreleng/
cp -r usr ./ngnrosreleng/airootfs/
cp -r etc ./ngnrosreleng/airootfs/
cp -r opt ./ngnrosreleng/airootfs/
ln -sf /usr/share/ngnrosER ./ngnrosreleng/airootfs/etc/skel/ngnrosER
}

# Set hostname
sethostname () {
echo "${MYHOSTNM}" > ./ngnrosreleng/airootfs/etc/hostname
}

# Create passwd file
crtpasswd () {
echo "root:x:0:0:root:/root:/usr/bin/bash
"${MYUSERNM}":x:1010:1010::/home/"${MYUSERNM}":/bin/bash" > ./ngnrosreleng/airootfs/etc/passwd
}

# Create group file
crtgroup () {
echo "root:x:0:root
sys:x:3:"${MYUSERNM}"
adm:x:4:"${MYUSERNM}"
wheel:x:10:"${MYUSERNM}"
log:x:19:"${MYUSERNM}"
network:x:90:"${MYUSERNM}"
floppy:x:94:"${MYUSERNM}"
scanner:x:96:"${MYUSERNM}"
power:x:98:"${MYUSERNM}"
rfkill:x:850:"${MYUSERNM}"
users:x:985:"${MYUSERNM}"
video:x:860:"${MYUSERNM}"
storage:x:870:"${MYUSERNM}"
optical:x:880:"${MYUSERNM}"
lp:x:840:"${MYUSERNM}"
audio:x:890:"${MYUSERNM}"
"${MYUSERNM}":x:1010:" > ./ngnrosreleng/airootfs/etc/group
}

# Create shadow file
crtshadow () {
usr_hash=$(openssl passwd -6 "${MYUSRPASSWD}")
root_hash=$(openssl passwd -6 "${RTPASSWD}")
echo "root:"${root_hash}":14871::::::
"${MYUSERNM}":"${usr_hash}":14871::::::" > ./ngnrosreleng/airootfs/etc/shadow
}

# create gshadow file
crtgshadow () {
echo "root:!*::root
"${MYUSERNM}":!*::" > ./ngnrosreleng/airootfs/etc/gshadow
}

# Set the keyboard layout
setkeylayout () {
echo "KEYMAP="${KEYMP}"" > ./ngnrosreleng/airootfs/etc/vconsole.conf
}

# Create 00-keyboard.conf file
crtkeyboard () {
mkdir -p ./ngnrosreleng/airootfs/etc/X11/xorg.conf.d
echo "Section \"InputClass\"
        Identifier \"system-keyboard\"
        MatchIsKeyboard \"on\"
        Option \"XkbLayout\" \""${KEYMP}"\"
        Option \"XkbModel\" \""${KEYMOD}"\"
EndSection" > ./ngnrosreleng/airootfs/etc/X11/xorg.conf.d/00-keyboard.conf
}

# Fix 40-locale-gen.hook and create locale.conf
crtlocalec () {
sed -i "s/en_US/"${LCLST}"/g" ./ngnrosreleng/airootfs/etc/pacman.d/hooks/40-locale-gen.hook
echo "LANG="${LCLST}".UTF-8" > ./ngnrosreleng/airootfs/etc/locale.conf
}

# Start mkarchiso
runmkarchiso () {
mkarchiso -v -w work -o out ngnrosreleng
}

# ----------------------------------------
# Run Functions
# ----------------------------------------

rootuser
handlerror
prepreqs
cleanup
cpngnrosreleng
addnmlinks
cpngnrosrepo
nalogin
rmunitsd
cpmyfiles
sethostname
crtpasswd
crtgroup
crtshadow
crtgshadow
setkeylayout
crtkeyboard
crtlocalec
runmkarchiso
rmngnrosrepo



