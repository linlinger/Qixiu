#!/bin/bash

# Version: 4 -- by eznix (https://sourceforge.net/projects/ezarch/)
# Revision: 2021.05.02
# (GNU/General Public License version 3.0)

# ----------------------------------------
# Define Variables
# ----------------------------------------

LCLST="en_US"
# Format is language_COUNTRY where language is lower case two letter code
# and country is upper case two letter code, separated with an underscore

KEYMP="us"
# Use lower case two letter country code

KEYMOD="pc105"
# pc105 and pc104 are modern standards, all others need to be researched

MYUSERNM="qixiu"
# use all lowercase letters only

MYUSRPASSWD="qixiu"
# Pick a password of your choice

RTPASSWD="qixiu"
# Pick a root password

MYHOSTNM="qixiu"
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
[[ -d ./releng ]] && rm -r ./releng
[[ -d ./work ]] && rm -r ./work
[[ -d ./out ]] && mv ./out ../
sleep 2
}

# Requirements and preparation
prepreqs () {
pacman -S --noconfirm archlinux-keyring
pacman -S --needed --noconfirm archiso mkinitcpio-archiso
}

# Copy releng to working directory
cpreleng () {
cp -r /usr/share/archiso/configs/releng/ ./
}

# Copy ezrepo to opt
cpezrepo () {
cp -r ./opt/qixiu /opt/
}

# Add ezrepo to pacman.conf
addezrepo () {
cp /etc/pacman.conf /etc/pacman.conf.prev
echo "# Temporarily add ezrepo.
[qixiu]
SigLevel = Optional TrustAll
Server = file:///opt/qixiu" >> /etc/pacman.conf
pacman -Sy
}

# Remove ezrepo from opt
rmezrepo () {
rm -r /opt/qixiu
}

# Restore original pacman.conf
mvpacmanconf () {
mv /etc/pacman.conf.prev /etc/pacman.conf
}

# Delete automatic login
nalogin () {
[[ -d ./releng/airootfs/etc/systemd/system/getty@tty1.service.d ]] && rm -r ./releng/airootfs/etc/systemd/system/getty@tty1.service.d
}

# Remove pacman.d hooks & cloud-init
rmunitsd () {
[[ -d ./releng/airootfs/etc/pacman.d/hooks ]] && rm -r ./releng/airootfs/etc/pacman.d/hooks
[[ -d ./releng/airootfs/etc/systemd/system/cloud-init.target.wants ]] && rm -r ./releng/airootfs/etc/systemd/system/cloud-init.target.wants
[[ -f ./releng/airootfs/etc/systemd/system/multi-user.target.wants/iwd.service ]] && rm ./releng/airootfs/etc/systemd/system/multi-user.target.wants/iwd.service
[[ -f ./releng/airootfs/etc/xdg/reflector/reflector.conf ]] && rm ./releng/airootfs/etc/xdg/reflector/reflector.conf
}

# Add NetworkManager, localegen, lightdm, & haveged systemd links
addnmlinks () {
[[ ! -d ./releng/airootfs/etc/systemd/system/sysinit.target.wants ]] && mkdir -p ./releng/airootfs/etc/systemd/system/sysinit.target.wants
[[ ! -d ./releng/airootfs/etc/systemd/system/network-online.target.wants ]] && mkdir -p ./releng/airootfs/etc/systemd/system/network-online.target.wants
[[ ! -d ./releng/airootfs/etc/systemd/system/multi-user.target.wants ]] && mkdir -p ./releng/airootfs/etc/systemd/system/multi-user.target.wants
ln -sf /usr/lib/systemd/system/NetworkManager-wait-online.service ./releng/airootfs/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service
ln -sf /usr/lib/systemd/system/NetworkManager.service ./releng/airootfs/etc/systemd/system/multi-user.target.wants/NetworkManager.service
ln -sf /usr/lib/systemd/system/NetworkManager-dispatcher.service ./releng/airootfs/etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service
ln -sf /usr/lib/systemd/system/localegen.service ./releng/airootfs/etc/systemd/system/multi-user.target.wants/localegen.service
ln -sf /usr/lib/systemd/system/sddm.service ./releng/airootfs/etc/systemd/system/display-manager.service
ln -sf /usr/lib/systemd/system/haveged.service ./releng/airootfs/etc/systemd/system/sysinit.target.wants/haveged.service
}

# Copy files to customize the ISO
cpmyfiles () {
cp packages.x86_64 ./releng/
cp pacman.conf ./releng/
cp profiledef.sh ./releng/
cp -r efiboot ./releng/
cp -r syslinux ./releng/
cp -r usr ./releng/airootfs/
cp -r etc ./releng/airootfs/
cp -r opt ./releng/airootfs/
#ln -sf /usr/share/ezarcher ./releng/airootfs/etc/skel/ezarcher
}

# Set hostname
sethostname () {
echo "${MYHOSTNM}" > ./releng/airootfs/etc/hostname
}

# Create passwd file
crtpasswd () {
echo "root:x:0:0:root:/root:/usr/bin/bash
"${MYUSERNM}":x:1010:1010::/home/"${MYUSERNM}":/bin/bash" > ./releng/airootfs/etc/passwd
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
"${MYUSERNM}":x:1010:" > ./releng/airootfs/etc/group
}

# Create shadow file
crtshadow () {
usr_hash=$(openssl passwd -6 "${MYUSRPASSWD}")
root_hash=$(openssl passwd -6 "${RTPASSWD}")
echo "root:"${root_hash}":14871::::::
"${MYUSERNM}":"${usr_hash}":14871::::::" > ./releng/airootfs/etc/shadow
}

# create gshadow file
crtgshadow () {
echo "root:!*::root
"${MYUSERNM}":!*::" > ./releng/airootfs/etc/gshadow
}

# Set the keyboard layout
setkeylayout () {
echo "KEYMAP="${KEYMP}"" > ./releng/airootfs/etc/vconsole.conf
}

# Create 00-keyboard.conf file
crtkeyboard () {
mkdir -p ./releng/airootfs/etc/X11/xorg.conf.d
echo "Section \"InputClass\"
        Identifier \"system-keyboard\"
        MatchIsKeyboard \"on\"
        Option \"XkbLayout\" \""${KEYMP}"\"
        Option \"XkbModel\" \""${KEYMOD}"\"
EndSection" > ./releng/airootfs/etc/X11/xorg.conf.d/00-keyboard.conf
}

# Create locale.gen and locale.conf files
crtlocalec () {
echo ""${LCLST}".UTF-8 UTF-8" >> ./releng/airootfs/etc/locale.gen
echo "LANG="${LCLST}".UTF-8" > ./releng/airootfs/etc/locale.conf
}

# Start mkarchiso
runmkarchiso () {
mkarchiso -v -w ./work -o ./out ./releng
}

# ----------------------------------------
# Run Functions
# ----------------------------------------

rootuser
handlerror
prepreqs
cleanup
cpreleng
addnmlinks
cpezrepo
addezrepo
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
rmezrepo
mvpacmanconf


# Disclaimer:
#
# THIS SOFTWARE IS PROVIDED BY EZNIX “AS IS” AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL EZNIX BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# END
#
