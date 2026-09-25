#!/bin/bash
# Instalação do Pintoo (Gentoo a la Pinto)
# ATENÇÃO: Este script serve como referência e tem /dev/vda como base.

echo "=== 0. Iniciar ==="
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

echo "=== 4. Descarregando e extraindo Stage3 (AMD64 OpenRC) ==="
cd /mnt/gentoo
# O link do Stage3 genérico
STAGE3_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-20260920T170055Z.tar.xz"
wget $STAGE3_URL -O stage3.tar.xz

# Extração para manter dono e xattrs
tar xpvf stage3.tar.xz --xattrs-include='*.*' --numeric-owner

echo "=== 5. Configurar o Portage make.conf (Binary Packages V3) ==="
cat << 'EOF' > /mnt/gentoo/etc/portage/make.conf
# These settings were set by the catalyst build script that automatically
# built this stage.
# Please consult /usr/share/portage/config/make.conf.example for a more
# detailed example.
COMMON_FLAGS="-O2 -pipe -march=x86-64-v3" # Architecture to usa
EMERGE_DEFAULT_OPTS="--jobs=2 --load-average=2.0"
MAKEOPTS="-j2 -l2" # cpus to use
FEATURES="getbinpkg binpkg-request-signature" # mostrly use bin pakages with signatures
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
source /etc/profile # Carrega o perfil para o utilizador 
export PS1="(Pintoo) ${PS1}" # Muda a prompt
getuto # Atualiza a confiança, Gentoo"TuTo" Trust Tool

echo "=== 10. atualizar o repositório local e selecionar perfil base ==="
emerge-webrsync
eselect profile set 1 # /default/linux/amd64/23.0 (stable) *

echo "=== 11. Finalmente instalar o Gentoo @world (Via binários, como o pacstrap no Arch Linux) ==="
emerge --verbose --update --deep --changed-use --getbinpkg @world

echo "=== 12. Configurando Localidade ==="
ln -sf /usr/share/zoneinfo/Atlantic/Azores /etc/localtime

sed -i 's/# pt_PT/pt_PT/' /etc/locale.gen
locale-gen
eselect locale set 4 

env-update && source /etc/profile

echo "=== 13. Firmware e Kernel Binário ==="
emerge --ask=n sys-kernel/linux-firmware sys-firmware/sof-firmware

mkdir -p /etc/portage/package.use
echo "sys-kernel/installkernel dracut grub" > /etc/portage/package.use/system
echo "sys-kernel/gentoo-kernel-bin ~amd64" > /etc/portage/package.accept_keywords/kernel
echo "virtual/dist-kernel ~amd64" >> /etc/portage/package.accept_keywords/kernel
emerge sys-kernel/gentoo-kernel-bin

echo "=== 14. Configuração GRUB (Bootloader) ==="
# Instalando o pacote do GRUB e efibootmgr
emerge sys-boot/grub sys-boot/efibootmgr

# Instalando e gerando o config do GRUB na partição /efi
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Gentoo
grub-mkconfig -o /boot/grub/grub.cfg

echo "=== 15. Hostname e Rede ==="

echo "Pintoo" > /etc/hostname
cat << 'HOSTS' >> /etc/hosts
127.0.0.1 Pintoo localhost
::1       Pintoo localhost
HOSTS

emerge net-misc/dhcpcd # utilizar dhcpcd
rc-update add dhcpcd default

# emerge net-misc/networkmanager # descomentar se preferir networkmanager
# rc-update add NetworkManager default

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

echo "=== 18. Otimização do OpenRC ==="
# remover autostart dos serviços dos utilizadores https://wiki.gentoo.org/wiki/OpenRC
echo 'rc_autostart_user="NO"' >> /etc/rc.conf 

# comentar no inittab para não dar inicio ao tty3 a tty6 
sed -i 's/^c3:/#c3:/' /etc/inittab
sed -i 's/^c4:/#c4:/' /etc/inittab
sed -i 's/^c5:/#c5:/' /etc/inittab
sed -i 's/^c6:/#c6:/' /etc/inittab

echo "=== 19. Software fundamental ;) ==="
# instalar fastfetch, o htop e o vim
emerge sys-process/htop app-misc/fastfetch app-editors/vim

echo "=== Instalação Base concluída com binários(com GRUB e ext4)! ==="
EOF

chmod +x /mnt/gentoo/chroot_install.sh

echo "Script finalizado! Agora pode executar o chroot:"
echo "arch-chroot /mnt/gentoo /chroot_install.sh"
