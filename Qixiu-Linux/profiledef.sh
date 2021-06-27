#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="qixiu-kde"
iso_label="Qixiu-KDE_$(date +%Y%m)"
iso_publisher="Qixiu Linux <https://github.com/linlinger/qixiu/>"
iso_application="Qixiu DVD"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:0400"
  ["/etc/gshadow"]="0:0:0400"
  ["/etc/sudoers"]="0:0:0440"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/ezmaint"]="0:0:755"
  ["/usr/local/bin/localegen.sh"]="0:0:755"
  ["/usr/share/ezarcher/Scripts/ezarch.bios"]="0:0:755"
  ["/usr/share/ezarcher/Scripts/ezarch.uefi"]="0:0:755"
  ["/usr/share/ezarcher/Scripts/ezmaint"]="0:0:755"
  ["/usr/share/ezarcher/Scripts/updater"]="0:0:755"
  ["/usr/share/ezarcher/Scripts/vmdetection"]="0:0:755"
  ["/usr/share/ezarcher/Scripts/user-post"]="0:0:755"
  ["/usr/share/ezarcher/Scripts/post-install"]="0:0:755"

)
