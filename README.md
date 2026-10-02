# Pintoo Gentoo a la Pinto
Yes let's create an easy install of Gentoo

## [Just with 19 steps](https://github.com/dpnpinto/Pintoo/blob/main/install_pintoo.sh):

* Initialize and Prepare Disks: Enables exit-on-error and partitions the /dev/vda drive into three sections: EFI (1GB, FAT32), Swap (4GB), and Linux Root (Remaining space, EXT4).

* Mount Partitions: Mounts the newly created EXT4 root file system to /mnt/gentoo and the FAT32 EFI partition to /mnt/gentoo/efi.

* Synchronize the Clock: Quickly synchronizes the system clock using chronyd to prevent SSL/download errors.

* Download and Extract Stage3: Downloads the Gentoo Stage3 tarball (AMD64 with OpenRC) and extracts it into the root mount, preserving file owners and extended attributes.

* Configure Portage (make.conf): Configures Gentoo's package manager settings to optimize for x86-64-v3 architecture, enables multi-core processing (2 jobs), strictly accepts free/binary-redistributable licenses, and enables the use of signed binary packages.

* Configure Binary Repositories: Sets up /etc/portage/binrepos.conf to pull from Gentoo's official binary package servers, prioritizing the optimized x86-64-v3 repository.

* Generate fstab: Uses genfstab to automatically create the file system table, ensuring partitions mount correctly on boot.

* Copy DNS Configuration: Copies the host system's resolv.conf to the new environment so it can resolve web addresses during the rest of the installation.

* Create the Chroot Script: Begins generating a secondary script (chroot_install.sh) inside /mnt/gentoo that will run the internal configuration steps.

* Update Repositories & Select Profile (Inside Chroot): Synchronizes the Portage tree from the web (emerge-webrsync) and sets the system profile to the standard, stable AMD64 profile.

* Install the Base System (Inside Chroot): Installs the core Gentoo system (@world set) using pre-compiled binary packages to save compilation time.

* Configure Localization (Inside Chroot): Sets the system timezone to Atlantic/Azores, configures the system language/locale to Portuguese (pt_PT), generates the locale files, and reloads the environment variables.

* Install Firmware and Kernel (Inside Chroot): Installs essential hardware firmware (including SOF audio firmware). It configures the package manager to accept the binary kernel (gentoo-kernel-bin), prepares installkernel to use dracut and grub, and installs the kernel.

* Configure GRUB Bootloader (Inside Chroot): Installs grub and efibootmgr, installs the bootloader to the EFI partition under the ID "Pintoo", and generates the main GRUB configuration file.

* Setup Hostname and Networking (Inside Chroot): Names the computer "Pintoo", creates the local /etc/hosts file, and installs/enables dhcpcd to automatically handle internet connections at boot.

* Create Users and Passwords (Inside Chroot): Sets the root password to "pintoo", creates a new user named "pintoo" (adding them to administrative and media groups), and installs doas (a sudo alternative) to grant administrative rights to the wheel group.

* Install Logging and Cron (Inside Chroot): Installs a system logger (sysklogd) and an NTP client (chrony), configuring both to start automatically with OpenRC.

* Optimize OpenRC (Inside Chroot): Disables user-level service autostart and disables virtual terminals (TTYs) 3 through 6 in the inittab file to free up system resources.

* Install Essential Software (Inside Chroot): Installs system monitoring and text editing tools: htop, fastfetch, and vim.

* Finalize the Script: Closes the chroot script generation, makes the script executable (chmod +x), and prints instructions for the user to finally run arch-chroot to execute it.

### References:

* https://wiki.gentoo.org/
* https://wiki.gentoo.org/wiki/Handbook:Main_Page
* https://wiki.gentoo.org/wiki/Gentoo_Binary_Host_Quickstart

