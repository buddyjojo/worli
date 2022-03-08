#!/bin/bash
if [ "$EUID" -ne 0 ]
    then echo "This script needs to be run as root. If you're a noob, that's 'sudo ./worli.sh' or 'sudo bash worli.sh'"
    exit 1
fi
echo "WoRli, made by JoJo Autoboy#1931"
echo "Heavily based off of Mario's WoR Linux guide: https://worproject.ml/guides/how-to-install/from-other-os"

mkdir -p /tmp/isomount
chmod 777 /tmp/isomount

echo " "
echo -e "Are you installing onto a Raspberry Pi 4, 3, CM3, or 2?"
read -r -p "[4/3/CM3/2]: " input
case $input in
    [4])
    export PI="4"
    ;;
    [3]|[cC][mM][3]|[2])
    export PI="3"
    ;;
    *)
    echo "Invalid input"
    exit 1
    ;;
esac

echo " "
echo -e "Do you want the tool to download the UEFI, drivers, and PE-installer automatically? Say 'N' to use your own files"
read -r -p "[Y/N]: " input
echo " "
case $input in

    [yY][eE][sS]|[yY])

    if ! command -v wget &> /dev/null
    then
        echo "- 'wget' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install wget'; for Arch, run 'sudo pacman -S wget')"
        exit 1
    fi

    efiURL="$(wget -qO- https://api.github.com/repos/pftf/RPi${PI}/releases/latest | grep '"browser_download_url":'".*RPi${PI}_UEFI_Firmware_.*\.zip" | sed 's/^.*browser_download_url": "//g' | sed 's/"$//g')"
    wget -O "/tmp/UEFI_Firmware.zip" "$efiURL" || error "Failed to download UEFI"
    drivURL="$(wget -qO- https://api.github.com/repos/worproject/RPi-Windows-Drivers/releases/latest | grep '"browser_download_url":'".*RPi${PI}_Windows_ARM64_Drivers_.*\.zip" | sed 's/^.*browser_download_url": "//g' | sed 's/"$//g')"
    wget -O "/tmp/Windows_ARM64_Drivers.zip" "$drivURL" || error "Failed to download drivers"
    peuuid="$(wget --spider --content-disposition --trust-server-names -O /dev/null "https://worproject.ml/dldserv/worpe/downloadlatest.php" 2>&1 | grep Location | sed 's/^Location: //g' | sed 's/ \[following\]$//g' | grep 'drive\.google\.com' | sed 's+.*/++g' | sed 's/.*&id=//g')"
    wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id='"$peuuid" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$peuuid" -O "/tmp/WoR-PE_Package.zip" && rm -rf /tmp/cookies.txt || error "Failed to download PE-installer"

    export efi="/tmp/UEFI_Firmware.zip"
    export driv="/tmp/Windows_ARM64_Drivers.zip"
    export inst="/tmp/WoR-PE_Package.zip"
    export auto="1"
    ;;

    [nN][oO]|[nN])

    echo " "
    echo "- Download the UEFI package (not the source code):"
    echo "  - for Pi 4 and newer: https://github.com/pftf/RPi4/releases"
    echo "  - for Pi 2, 3, CM3: https://github.com/pftf/RPi3/releases"
    echo "- Then, rename the ZIP file to 'UEFI_Firmware.zip'"
    echo " "
    echo "What's the path to 'UEFI_Firmware.zip'?"
    read -r -p "[/*] E.g. '~/UEFI_Firmware.zip': " efi

    echo " "
    echo "- Go to https://worproject.ml/downloads#windows-on-raspberry-pe-based-installer and download the 'Windows on Raspberry PE-based installer', then rename the ZIP file to 'WoR-PE_Package.zip'"
    echo " "
    echo "What's the path to 'WoR-PE_Package.zip'?"
    read -r -p "[/*] E.g. '~/WoR-PE_Package.zip': " inst

    echo " "
    echo "- Download the driver package from: https://github.com/worproject/RPi-Windows-Drivers/releases (get the ZIP archive with the RPi prefix followed by your board version) and rename the ZIP file to Windows_ARM64_Drivers.zip"
    echo " "
    echo "What's the path to 'Windows_ARM64_Drivers.zip'?"
    read -r -p "[/*] E.g. '~/Windows_ARM64_Drivers.zip': " driv
    ;;

    *)

    echo "Invalid input"
    exit 1
    ;;
esac

echo " "
if [ -f $efi ]; then
    echo "'UEFI_Firmware.zip' found"
else
    echo "'UEFI_Firmware.zip' does not exist. Abort."
    exit 1
fi
if [ -f $driv ]; then
    echo "'Windows_ARM64_Drivers.zip' found"
else
    echo "'Windows_ARM64_Drivers.zip' does not exist. Abort."
    exit 1
fi
if [ -f $inst ]; then
    echo "'WoR-PE_Package.zip' found"
else
    echo "'WoR-PE_Package.zip' does not exist. Abort."
    exit 1
fi

echo " "
echo "Prerequisites"
echo " "
echo "- Get the windows ISO: https://worproject.ml/guides/getting-windows-images"
echo "- Rename the ISO file to 'win.iso'"
echo " "
echo "- (NOT RECOMMENDED) If you want use use a custom WIM, rename it to 'install.wim'. NOTE: You will still need the ISO where the WIM came from"
echo " "
echo "- If you're using a Raspberry Pi 4, you must update the Bootloader to the latest version: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#updating-the-bootloader"

echo " "
if ! command -v wimupdate &> /dev/null
then
    echo "- 'wimtools' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install wimtools'; for Arch, run 'sudo pacman -S wimtools')"
    exit 1
fi
if ! command -v parted &> /dev/null
then
    echo "- 'parted' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install parted'; for Arch, run 'sudo pacman -S parted')"
    exit 1
fi
if ! command -v mkfs.ntfs &> /dev/null
then
    echo "- 'mkfs.ntfs' command not found. Install NTFS support somehow (such as ntfs-3g and ntfsprogs)"
    exit 1
fi

echo -e "\e[0;31mDO THE PREREQUISITES STUFF BEFORE CONTINUING\e[0m"
read -p "Press any key to continue..."
echo " "

echo "What's the path to the 'win.iso'?"
read -r -p "[/*] E.g. '~/win.iso': " iso
echo " "

echo "Do you want to use a custom WIM?"
read -r -p "[N/Y]: " input
echo " "
case $input in

    [yY][eE][sS]|[yY])

    echo "what's the path to the 'install.wim'?"
    read -r -p "[/*] E.g. '~/install.wim': " wim

    echo " "
    if [ -f $wim ]; then
        echo "'install.wim' found"
    else
        echo "'install.wim' does not exist. Abort."
        exit 1
    fi
    ;;

    [nN][oO]|[nN])

    echo " "
    echo "No custom WIM then"
    ;;

    *)

    echo "Invalid input"
    exit 1
    ;;
esac

echo " "
if [ -f $iso ]; then
    echo "'win.iso' found"
else
    echo "'win.iso' does not exist. Abort."
    exit 1
fi

echo " "
echo "What /dev/* is your drive? NOTE: ALL your data on the selected disk will be ERASED, proceed with caution!"
echo "---------------------------------------------------------------------------------------------------------"
echo " "
parted -l
echo " "
read -r -p "[/dev/*] E.g. 'sdb', 'mmcblk0': " disk

echo "You have selected '$disk', is this correct?"
read -r -p "[Y/N]: " input
case $input in
    [yY][eE][sS]|[yY])
    echo "ok '$disk' it is then"
    ;;
    [nN][oO]|[nN])
    echo "Abort."
    exit 1
    ;;
    *)
    echo "Invalid input"
    exit 1
    ;;
esac

if [[ $disk == *"mmcblk"* ]]; then
    export nisk="${disk}p"
else
    export nisk="$disk"
fi

if [[ $disk == *"/dev"* ]]; then
    echo "DO NOT PUT '/dev', only put the name like 'sdb'"
    exit 1
else
    echo "Disk name format correct"
fi

if [ -b "/dev/$disk" ]; then
   echo "'$disk' found"
else
   echo "'$disk' does not exist. Abort."
   exit 1
fi

echo -e "\e[0;31mWARNING: THE DISK '$disk' WILL BE WIPED!\e[0m Do you want to continue?"
read -r -p "[Y/N]: " input
case $input in
    [yY][eE][sS]|[yY])
    echo "No going back now"
    ;;
    [nN][oO]|[nN])
    echo "Abort."
    exit 1
    ;;
    *)
    echo "Invalid input"
    exit 1
    ;;
esac

echo " "
echo "Creating partitions..."
echo " "
echo "*Ignore the 'not mounted' errors, they are normal*"
echo " "

umount /dev/$disk*

parted -s /dev/$disk mklabel gpt
parted -s /dev/$disk mkpart primary 1MB 1000MB
parted -s /dev/$disk set 1 msftdata on

binbowstype() {
    echo " "
    echo "[1]: Do you want the installer to be able to install Windows on the same drive (at least 32GB)?"
    echo "[2]: OR create an installation media on this drive (at least 8GB) that's able to install Windows on other drives (at least 16GB)?"
    read -r -p "[1/2]: " input
    echo " "
    case $input in
        [1])
        parted -s /dev/$disk mkpart primary 1000MB 19000MB
        parted -s /dev/$disk set 2 msftdata on
        return 0
        ;;
        [2])
        parted -s -- /dev/$disk mkpart primary 1000MB -0
        parted -s /dev/$disk set 2 msftdata on
        return 0
        ;;
        *)
        echo "Invalid input"
        return 1
        ;;
    esac
}
until binbowstype; do : ; done

sync

sudo mkfs.fat -F 32 /dev/$disk'1'
sudo mkfs.ntfs -f /dev/$disk'2'

mkdir -p /media/bootpart /media/winpart
mount /dev/$nisk'1' /media/bootpart
mount /dev/$nisk'2' /media/winpart

echo " "
echo "Copying Windows files to the drive, this may take a while..."
echo " "
echo "*NOTE: 'WARNING: Device write-protected, mounted read-only' is also normal*"
echo " "

mount $iso /tmp/isomount
cp -r /tmp/isomount/boot /media/bootpart
cp -r /tmp/isomount/efi /media/bootpart
mkdir /media/bootpart/sources
cp /tmp/isomount/sources/boot.wim /media/bootpart/sources

if [ -f $wim ]; then
    cp $wim /media/winpart
else
    cp /tmp/isomount/sources/install.wim /media/winpart
fi

umount /tmp/isomount

echo " "
echo "Copying the UEFI boot files to the drive..."
echo " "

unzip $efi -d /tmp/uefipackage
sudo cp /tmp/uefipackage/* /media/bootpart

echo " "
echo "Copying the drivers to the drive..."
echo " "

unzip $driv -d /tmp/driverpackage
wimupdate /media/bootpart/sources/boot.wim 2 --command="add /tmp/driverpackage /drivers"

echo " "
echo "Copying the PE-installer to the drive..."
echo " "

unzip $inst -d /tmp/peinstaller
cp -r /tmp/peinstaller/efi /media/bootpart
wimupdate /media/bootpart/sources/boot.wim 2 --command="add /tmp/peinstaller/winpe/2 /"

echo " "
echo "*Ignore 'cp: -r not specified; omitting directory...'*"

echo " "
if [[ $PI == *"3"* ]]; then
    echo "Installing to Pi 3 and below, applying gptpatch..."
    echo " "
    dd if=/tmp/peinstaller/pi3/gptpatch.img of=/dev/$disk conv=fsync
else
    echo "Installing to Pi 4, no need to apply gptpatch"
fi

echo " "
echo "Unmounting drive, this may also take a while..."

sync

echo " "
echo "*Again, ignore the 'not mounted' errors, they are normal*"
echo " "

umount /dev/$disk*

echo " "
echo "Cleaning up..."

rm -rf /tmp/driverpackage
rm -rf /tmp/uefipackage
rm -rf /tmp/peinstaller
rm -rf /tmp/isomount

if [[ $auto == *"1"* ]]; then
    rm -rf /tmp/UEFI_Firmware.zip
    rm -rf /tmp/Windows_ARM64_Drivers.zip
    rm -rf /tmp/WoR-PE_Package.zip
else
    echo " "
    echo "No need to clear downloaded files"
fi

echo " "
echo "1. Connect the drive and other peripherals to your Raspberry Pi then boot it up."
echo " "
echo "2. Assuming everything went right in the previous steps, you'll be further guided by the PE-based installer on your Pi."
echo " "
echo "  - If you've used the 1st method (self-installation), there's no need to touch the Raspberry Pi once it has booted. The installer will automatically start the installation process after a delay of 15 seconds. Moving the mouse cursor over the Windows Setup window will stop the timer, so you'll have to manually click on the Install button."
echo " "
echo "  - If you've used the 2nd method (installing on a secondary drive), you must also connect the 2nd drive before the installer window opens up, then select it in the drop-down list. Otherwise, it will assume you're trying to install Windows on the same drive (self-installation)."
echo " "
echo -e "\e[0;31mNOTE:\e[0m Disabling the 3gb ram limit before the first boot can cause the disk to not be recognized in the PE-installer. The limit can be removed AFTER the installation."
echo " "

echo "All done :)"
echo "Thanks for using WoRli!"
echo " "
exit 0
