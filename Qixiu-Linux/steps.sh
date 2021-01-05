#!/bin/bash

# Revision: 2 -- by eznix (https://sourceforge.net/projects/ezarch/)
# (GNU/General Public License version 3.0)

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

# Copy releng to working directory
cpreleng () {
cp -r /usr/share/archiso/configs/releng/ ./
}

# Copy qxrepo to opt
cpqxrepo () {
cp -r ./opt/qxrepo /opt/
}

# Add qxrepo to pacman.conf
# repo created with:
# repo-add ./qxrepo.db.tar.gz calamares-3.2.35.1-1-x86_64.pkg.tar.zst ckbcomp-1.199-1-any.pkg.tar.zst mkinitcpio-openswap-0.1.0-3-any.pkg.tar.zst
addqxrepo () {
cp /etc/pacman.conf /etc/pacman.conf.prev
echo "# Temporarily add qxrepo.
[archlinuxcn]
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
[qxrepo]
SigLevel = Optional TrustAll
Server = file:///opt/qxrepo" >> /etc/pacman.conf
pacman -Sy
}

# Remove qxrepo from opt
rmqxrepo () {
rm -r /opt/qxrepo
}

# Restore original pacman.conf
mvpacmanconf () {
mv /etc/pacman.conf.prev /etc/pacman.conf
}

# Delete automatic login
nalogin () {
[[ -d ./releng/airootfs/etc/systemd/system/getty@tty1.service.d ]] && rm -r ./releng/airootfs/etc/systemd/system/getty@tty1.service.d
}

# Remove systemd-networkd
rmnetworkd () {
[[ -d ./releng/airootfs/etc/systemd/network ]] && rm -r ./releng/airootfs/etc/systemd/network
[[ -d ./releng/airootfs/etc/systemd/system/systemd-networkd-wait-online.service.d ]] && rm -r ./releng/airootfs/etc/systemd/system/systemd-networkd-wait-online.service.d
[[ -f ./releng/airootfs/etc/systemd/system/dbus-org.freedesktop.network1.service ]] && rm ./releng/airootfs/etc/systemd/system/dbus-org.freedesktop.network1.service
[[ -f ./releng/airootfs/etc/systemd/system/multi-user.target.wants/systemd-networkd.service ]] && rm ./releng/airootfs/etc/systemd/system/multi-user.target.wants/systemd-networkd.service
[[ -f ./releng/airootfs/etc/systemd/system/multi-user.target.wants/iwd.service ]] && rm ./releng/airootfs/etc/systemd/system/multi-user.target.wants/iwd.service
[[ -f ./releng/airootfs/etc/systemd/system/sockets.target.wants/systemd-networkd.socket ]] && rm ./releng/airootfs/etc/systemd/system/sockets.target.wants/systemd-networkd.socket
[[ -f ./releng/airootfs/etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service ]] && rm ./releng/airootfs/etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service
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

# Delete customize_airootfs.sh, it's not needed anymore.
rmcustairoot () {
[[ -f ./releng/airootfs/root/customize_airootfs.sh ]] && rm ./releng/airootfs/root/customize_airootfs.sh
}

# Copy files to customize the ISO
cpmyfiles () {
cp packages.x86_64 ./releng/
cp pacman.conf ./releng/
cp splash.png ./releng/syslinux/
cp profiledef.sh ./releng/
cp -r usr ./releng/airootfs/
cp -r etc ./releng/airootfs/
cp -r opt ./releng/airootfs/
}

# Set hostname
sethostname () {
echo "qixiu" > ./releng/airootfs/etc/hostname
}

# Set username, user password and root password
setpasswd () {
usr_name="qixiu"
usr_pass="qixiu"
root_pass="toor"
}

# Create passwd file
crtpasswd () {
echo "root:x:0:0:root:/root:/usr/bin/bash
${usr_name}:x:1010:1010::/home/${usr_name}:/bin/bash" > ./releng/airootfs/etc/passwd
}

# Create group file
crtgroup () {
echo "root:x:0:root
sys:x:3:${usr_name}
adm:x:4:${usr_name}
wheel:x:10:${usr_name}
log:x:19:${usr_name}
network:x:90:${usr_name}
floppy:x:94:${usr_name}
scanner:x:96:${usr_name}
power:x:98:${usr_name}
rfkill:x:850:${usr_name}
users:x:985:${usr_name}
video:x:860:${usr_name}
storage:x:870:${usr_name}
optical:x:880:${usr_name}
lp:x:840:${usr_name}
audio:x:890:${usr_name}
${usr_name}:x:1010:" > ./releng/airootfs/etc/group
}

# Create shadow file
crtshadow () {
usr_hash=$(openssl passwd -6 "${usr_pass}")
root_hash=$(openssl passwd -6 "${root_pass}")
echo "root:${root_hash}:14871::::::
${usr_name}:${usr_hash}:14871::::::" > ./releng/airootfs/etc/shadow
}

# create gshadow file
crtgshadow () {
echo "root:!*::root
${usr_name}:!*::" > ./releng/airootfs/etc/gshadow
}

# Set the keyboard layout
setkeylayout () {
echo "KEYMAP=us" > ./releng/airootfs/etc/vconsole.conf
}

# Create 00-keyboard.conf file
crtkeyboard () {
mkdir -p ./releng/airootfs/etc/X11/xorg.conf.d
echo "Section \"InputClass\"
        Identifier \"system-keyboard\"
        MatchIsKeyboard \"on\"
        Option \"XkbLayout\" \"us\"
        Option \"XkbModel\" \"pc105\"
EndSection" > ./releng/airootfs/etc/X11/xorg.conf.d/00-keyboard.conf
}

# Create locale.conf file
crtlocalec () {
echo "LANG=en_US.UTF-8" > ./releng/airootfs/etc/locale.conf
}

# Generate mirrorlist
mkmirrorlist () {
echo "Generating mirrorlist, please be patient..."
mkdir -p ./releng/airootfs/etc/pacman.d
reflector --age 3 --protocol https --save ./releng/airootfs/etc/pacman.d/mirrorlist
sleep 2
}

# Start mkarchiso
runmkarchiso () {
mkarchiso -v -w ./work -o ./out ./releng
}

######

handlerror
cleanup
cpreleng
addnmlinks
cpqxrepo
addqxrepo
nalogin
rmnetworkd
rmcustairoot
cpmyfiles
sethostname
setpasswd
crtpasswd
crtgroup
crtshadow
crtgshadow
setkeylayout
crtkeyboard
crtlocalec
mkmirrorlist
runmkarchiso
sleep 3
rmqxrepo
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
