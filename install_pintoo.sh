#!/bin/bash
# Instalação do Pintoo (Gentoo a la Pinto)
# ATENÇÃO: Este script serve como referência e tem /dev/vda como base.

set -e # Exit se erro

echo "=== 1. Preparando discos ==="
# /dev/vda1: EFI (1GB)
# /dev/vda2: Linux swap (4GB)
# /dev/vda3: Linux filesystem (Restante)

sgdisk -Z -n 1:0:+1G -t 1:ef00 -c 1:"EFI" -n 2:0:+4G -t 2:8200 -c 2:"Swap" -n 3:0:0 -t 3:8300 -c 3:"Linux" /dev/vda
mkfs.fat -F 32 /dev/vda1
mkswap /dev/vda2
swapon /dev/vda2
mkfs.ext4 /dev/vda3  # EXT4

echo "=== 2. Montando partições ==="
mount /dev/vda3 /mnt/gentoo
mkdir -p /mnt/gentoo/efi
mount /dev/vda1 /mnt/gentoo/efi

echo "=== 3. Sincronizando relógio ==="
chronyd -q

echo "=== 4. Baixando e extraindo Stage3 (AMD64 OpenRC) ==="
cd /mnt/gentoo
# O link do Stage3 genérico
STAGE3_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-20260906T170102Z.tar.xz"
wget $STAGE3_URL -O stage3.tar.xz

# Extração para manter dono e xattrs
tar xpvf stage3.tar.xz --xattrs-include='*.*' --numeric-owner

echo "=== 5. Configurando make.conf (Binary Packages V3) ==="
cat << 'EOF' > /mnt/gentoo/etc/portage/make.conf
# These settings were set by the catalyst build script that automatically
# built this stage.
# Please consult /usr/share/portage/config/make.conf.example for a more
# detailed example.
COMMON_FLAGS="-O2 -pipe -march=x86-64-v3" # Architecture to use
MAKEOPTS="-j2" # cpus to use
FEATURES="getbinpkg binpkg-request-signature" # mostrly use bin pakages with signatures
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"

# NOTE: This stage was built with the bindist USE flag enabled
USE="dist-kernel" # use a distributed precompiled kernel
ACCEPT_LICENSE="-* @FREE @BINARY @BINARY-REDISTRIBUTABLE" #Only Free redistributable software
# This sets the language of build output to English.
# Please keep this setting intact when reporting bugs.
LC_MESSAGES=C.UTF-8
EOF

echo "=== 6. Configurando binrepos ==="
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

echo "=== 7. Gerar tabela de arranque do file system  fstab ==="
genfstab -U /mnt/gentoo >> /mnt/gentoo/etc/fstab

echo "=== 8. Copiar ficheiro de resolução de nomes (DNS) resolv.conf ==="
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

echo "=== 9. Criando script de instalação em modo chroot ==="
cat << 'EOF' > /mnt/gentoo/chroot_install.sh
#!/bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"

echo "=== 10. atualizar o repositório local e selecionar perfil base ==="
emerge-webrsync
eselect profile set 1 # default/linux/amd64/23.0

echo "=== 11. Atualizando @world (Via binários) ==="
emerge --ask --verbose --update --deep --changeduse --getbinpkg @world

echo "=== 12. Configurando Localidade ==="
ln -sf /usr/share/zoneinfo/Atlantic/Azores /etc/localtime
emerge app-editors/vim

sed -i 's/#pt_PT.UTF-8 UTF-8/pt_PT.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
eselect locale set 4 

env-update && source /etc/profile

echo "=== 13. Firmware e Kernel Binário ==="
emerge --ask=n sys-kernel/linux-firmware sys-firmware/sof-firmware

mkdir -p /etc/portage/package.use
echo "sys-kernel/installkernel dracut efi-stub" > /etc/portage/package.use/system
emerge sys-kernel/gentoo-kernel-bin

echo "=== 14. Configuração EFI STUB (ext4) ==="
ROOT_UUID=$(findmnt -no UUID /)
mkdir -p /etc/default
# Utilziando ext4:
echo "entry_id=linux name=linux.kernel_version root=UUID=${ROOT_UUID} rootfstype=ext4 rw" > /etc/default/uefi-mkconfig

echo "=== 15. Hostname e Rede ==="
echo "Pintoo" > /etc/hostname
cat << 'HOSTS' >> /etc/hosts
127.0.0.1 Pintoo localhost
::1       Pintoo localhost
HOSTS

emerge net-misc/networkmanager
rc-update add NetworkManager default

echo "=== 16. Utilizadores (Senha padrão: password) ==="
echo "root:password" | chpasswd
useradd -m -G wheel,audio,video -s /bin/bash pintoo
echo "pintoo:password" | chpasswd

emerge app-admin/doas
echo "permit persist :wheel" > /etc/doas.conf

echo "=== 17. Logger e Cron ==="
emerge app-admin/sysklogd net-misc/chrony
rc-update add sysklogd default
rc-update add chronyd default

echo "Instalação Base concluída."
EOF

chmod +x /mnt/gentoo/chroot_install.sh

echo "Script finalizado! Agora pode executar o chroot:"
echo "arch-chroot /mnt/gentoo /chroot_install.sh"
