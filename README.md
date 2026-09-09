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
