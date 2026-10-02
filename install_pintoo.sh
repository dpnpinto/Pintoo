#!/bin/bash
# Pintoo Installation (Gentoo a la Pinto)
# WARNING: This script serves as a reference and is based on /dev/vda.

echo "=== 0. Start ==="
set -e # Exit on error

echo "=== 1. Preparing disks ==="
# /dev/vda1: EFI (1GB)
# /dev/vda2: Linux swap (4GB)
# /dev/vda3: Linux filesystem (Remaining)

sgdisk -Z -n 1:0:+1G -t 1:ef00 -c 1:"EFI" -n 2:0:+4G -t 2:8200 -c 2:"Swap" -n 3:0:0 -t 3:8300 -c 3:"Linux" /dev/vda
mkfs.fat -F 32 /dev/vda1
mkswap /dev/vda2
swapon /dev/vda2
mkfs.ext4 /dev/vda3  # EXT4

echo "=== 2. Mounting partitions ==="
mount /dev/vda3 /mnt/gentoo
mkdir -p /mnt/gentoo/efi
mount /dev/vda1 /mnt/gentoo/efi

echo "=== 3. Synchronizing clock ==="
chronyd -q

echo "=== 4. Downloading and extracting Stage3 (AMD64 OpenRC) ==="
# Go there
cd /mnt/gentoo
# The generic Stage3 amd64+OpenRC link
BASE_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc"
LATEST_FILE=$(curl -s "${BASE_URL}/latest-stage3-amd64-openrc.txt" | grep -v "^#" | awk '{print $1}')
STAGE3_URL="${BASE_URL}/${LATEST_FILE}"
wget $STAGE3_URL -O stage3.tar.xz
# Extraction to keep owner and xattrs
tar xpvf stage3.tar.xz --xattrs-include='*.*' --numeric-owner

echo "=== 5. Configuring Portage make.conf (Binary Packages V3) ==="
cat << 'EOF' > /mnt/gentoo/etc/portage/make.conf
# These settings were set by the catalyst build script that automatically
# built this stage.
# Please consult /usr/share/portage/config/make.conf.example for a more
# detailed example.
COMMON_FLAGS="-O2 -pipe -march=x86-64-v3" # Architecture to use
EMERGE_DEFAULT_OPTS="--jobs=2 --load-average=2.0"
MAKEOPTS="-j2 -l2" # cpus to use
FEATURES="getbinpkg binpkg-request-signature" # mostly use bin packages with signatures
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"

# NOTE: This stage was built with the bindist USE flag enabled
USE="dist-kernel" # use a distributed precompiled kernel
ACCEPT_LICENSE="-* @FREE @BINARY-REDISTRIBUTABLE" #Only Free redistributable software
# This sets the language of build output to English.
# Please keep this setting intact when reporting bugs.
LC_MESSAGES=C.UTF-8
EOF

echo "=== 6. Configuring binrepos ==="
mkdir -p /mnt/gentoo/etc/portage/binrepos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf
cat << 'EOF' > /mnt/gentoo/etc/portage/binrepos.conf/gentoo.conf
# These settings were set by the catalyst build script that automatically
# built this stage.
# Please consider using a local mirror.

[gentoo]
priority = 1
sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64
location = /var/cache/binhost/gentoo
verify-signature = true

[gentoo-x86-64-v3]
priority = 9999
sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3
location = /var/cache/binhost/gentoo-x86-64-v3
verify-signature = true
EOF

echo "=== 7. Generating file system boot table fstab ==="
genfstab -U /mnt/gentoo >> /mnt/gentoo/etc/fstab

echo "=== 8. Copying name resolution file (DNS) resolv.conf ==="
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

echo "=== 9. Creating chroot mode installation script ==="
cat << 'EOF' > /mnt/gentoo/chroot_install.sh
#!/bin/bash
source /etc/profile # Loads the user profile 
# export PS1="(Pintoo) ${PS1}" # If you care with this uncoment, only changes the prompt
getuto # Updates trust, Gentoo "TuTo" Trust Tool

echo "=== 10. Updating local repository and selecting base profile ==="
emerge-webrsync
eselect profile set 1 # /default/linux/amd64/23.0 (stable) *

echo "=== 11. Finally installing Gentoo @world (Via binaries, like pacstrap in Arch Linux) ==="
emerge --verbose --update --deep --changed-use --getbinpkg @world

echo "=== 12. Configuring Locale ==="
ln -sf /usr/share/zoneinfo/Atlantic/Azores /etc/localtime

sed -i 's/# pt_PT/pt_PT/' /etc/locale.gen
locale-gen
eselect locale set 4 

env-update && source /etc/profile

echo "=== 13. Firmware and Binary Kernel ==="
emerge --ask=n sys-kernel/linux-firmware sys-firmware/sof-firmware

mkdir -p /etc/portage/package.use
echo "sys-kernel/installkernel dracut grub" > /etc/portage/package.use/system
echo "sys-kernel/gentoo-kernel-bin ~amd64" > /etc/portage/package.accept_keywords/kernel
echo "virtual/dist-kernel ~amd64" >> /etc/portage/package.accept_keywords/kernel
emerge sys-kernel/gentoo-kernel-bin

echo "=== 14. GRUB Configuration (Bootloader) ==="
# Installing the GRUB and efibootmgr packages
emerge sys-boot/grub sys-boot/efibootmgr

# Installing and generating the GRUB config in the /efi partition
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Pintoo
grub-mkconfig -o /boot/grub/grub.cfg

echo "=== 15. Hostname and Network ==="

echo "Pintoo" > /etc/hostname
cat << 'HOSTS' >> /etc/hosts
127.0.0.1 Pintoo localhost
::1       Pintoo localhost
HOSTS

emerge net-misc/dhcpcd # use dhcpcd
rc-update add dhcpcd default

# emerge net-misc/networkmanager # uncomment if you prefer networkmanager
# rc-update add NetworkManager default

echo "=== 16. Users (Default password: password) ==="
echo "root:pintoo" | chpasswd
useradd -m -G wheel,audio,video -s /bin/bash pintoo
echo "pintoo:pintoo" | chpasswd

emerge app-admin/doas
echo "permit persist :wheel" > /etc/doas.conf

echo "=== 17. Logger and Cron ==="
emerge app-admin/sysklogd net-misc/chrony
rc-update add sysklogd default
rc-update add chronyd default

echo "=== 18. OpenRC Optimization ==="
# remove autostart of user services https://wiki.gentoo.org/wiki/OpenRC
echo 'rc_autostart_user="NO"' >> /etc/rc.conf 

# comment in inittab to prevent starting tty3 through tty6 
sed -i 's/^c3:/#c3:/' /etc/inittab
sed -i 's/^c4:/#c4:/' /etc/inittab
sed -i 's/^c5:/#c5:/' /etc/inittab
sed -i 's/^c6:/#c6:/' /etc/inittab

echo "=== 19. Fundamental software ;) ==="
# install fastfetch, htop and vim
emerge sys-process/htop app-misc/fastfetch app-editors/vim

echo "=== Base Installation finished with binaries (with GRUB and ext4)! ==="
EOF

chmod +x /mnt/gentoo/chroot_install.sh

echo "Script finished! Now you can execute the chroot:"
echo "arch-chroot /mnt/gentoo /chroot_install.sh"
