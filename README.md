# Pintoo
Gentoo a la Pinto
Yes let's create an easy install of Gentoo
PintoGentoo
Steps:
* 1- Descarregar do gentoo.org - Minimal Gentoo for AMD64
* 2- Arrancar com o "Live CD"
* 3- Escolher o teclado - pt
* 4- Mudar o tamanho da fonte - setfont -d
* 5- Mudar a password para a root - passwd root
* 6- Arrancar com o servidor ssh - /etc/init.d/sshd start
* 7- Ver o ip - ip a
* 8- efetuar uma sessão remota - ssh root@ip
* 9- Criar partições do tipo GPT
* 10 - Utilizando cfdisk, primeira 1G tipo EFI System
* 11 - Segunda 4G tipo swap
* 12 - Terceira restante espaço deixar o tipo em Linux FileSystem
* 13 - formatar a partição 1 como fat32 - mkfs.vfat -F32 /dev/sda1
* 14 - formatar a partição 2 como swap - mkswap /dev/sda2
* 15 - Ativar a swap -  swapon /dev/sda2
* 16 - formatar a partição 3 com ext4 - mkfs.ext4 /dev/sda3
* 17 - montar o sistema - mount -m /dev/sda3 /mnt/gentoo
* 18 - sincronizar o relógio - chronyd -q
* 18 - ir para dentro do sistema - cd /mnt/gentoo
* 19 - descarregar o ficheiro tar com o sistema - links https://www.gentoo.org/downloads/mirrors/
* wget https://distfiles.gentoo.org/releases/amd64/autobuilds/20260906T170102Z/stage3-amd64-openrc-20260906T170102Z.tar.xz
* 20 - extrair a imagem com os atributos preservados - tar -xpvf file.tar.xz --xattrs-include=´.´ --numeric-owner
* 21 - alterar o make.conf para instalar binários- cd etc/portage alteral make.conf
* 22 - alterar o binrepos.conf - cd etc/portage/binrepos.conf alterar o gentoo.conf
* 23 - verificar o PGP - getuto
* 24 - voltar para a raiz e montar a partição EFI - cd e mount -m /dev/sda1 /mnt/gentoo/efi
* 25 - gerar o ficheiro fstab - genfstab -U /mnt/gentoo/ > /mnt/gentoo/etc/fstab
* 26 - Copiar as referencias de DNS para o nosso sistema - cp --dereference /etc/resolv.conf /mnt/gentoo/etc
* 27 - Ir para dentro do sistema - arch-chroot /mnt/gentoo
* 28 - Source o perfil - source /etc/profile
* 29 - Ir para a pasta do utilizador - cd
* 30 - Sincronizar o repositorio - emerge-webrsync
* 31 - Vamos ver para selecionar um perfil - eselect profile list | less
* 32 - vamos selecionar um perfil - eselect profile set 1
* 33 - vamos finalmente instalar o Gentoo - emerge --ask --verbose --update --deep --changed-use --getbinpkg @world
* 34 - vamos defenir a zona - ln -sf /usr/share/zoneinfo/Atlantic/Azores /etc/localtime
* 35 - instalar um editor de texto em condições - emerge app-editors/vim
* 36 - vamos gerar o local, primeiro editar e tirar o # do local para mim pt_PT - vim /etc/locale.gen
* 37 - vamos gerar O locale - locale-gen
* 38 - vamos atualziar a variavel do perfil - eselect locale list e eselect locale set 4
* 39 - vamos atualizar o perfil - env-update && source /etc/profile
* 40 - marcar a prompt para sabermos que estamos em chroot - export PS1="(chroot) ${PS1}"
* 41 - instalar o firmware - emerge --ask sys-kernel/linux-firmware sys-firmware/sof-firmware
* 42 - criar e editar os pacotes que são relacionados com o sistema -  vim /etc/portage/package.use/system
* 43 - Adicionar o software - sys-kernel/installkernel dracut efistub
* 44 - para que o efistub funcionar - 
