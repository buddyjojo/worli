#!/bin/bash
PREFIX="\e[1;36m[WoRli]\e[0m"
if [ "$EUID" -ne 0 ]
    then echo -e "${PREFIX} This script needs to be run as root. If you're a noob, that's 'sudo ./worli.sh' or 'sudo bash worli.sh'"

    exit 1
fi

if [[ $OSTYPE == 'darwin'* ]]; then
  echo -e "${PREFIX} macOS detected, running in experimental macOS mode."
    echo " "
    echo -e "${PREFIX} Prerequisites"
    echo -e "${PREFIX} Due to how brew works you need to run these commands in a non root shell:"
    echo -e "${PREFIX} - 'brew install wimlib gdisk dosfstools gnu-sed'" 
    echo -e "${PREFIX} - 'brew install --cask macfuse'"
    echo -e "${PREFIX} - 'brew tap gmerlino/exfat'"
    echo -e "${PREFIX} - 'brew install --HEAD exfat'"
    echo -e "${PREFIX} - You may need to disable SIP as stated here: https://www.rodsbooks.com/gdisk/"
    echo " "
  read -p "Press any key to continue..."
  export MACOS=1
  export PATH=$PATH:/usr/local/sbin
  export PATH=$PATH:/usr/local/opt/gnu-sed/libexec/gnubin
else
  export MACOS=0
fi

echo -e "${PREFIX} WoRli, made by JoJo Autoboy#1931"
echo -e "${PREFIX} Heavily based off of Mario's WoR Linux guide: https://worproject.com/guides/how-to-install/from-other-os"

mkdir -p /tmp/isomount
chmod 777 /tmp/isomount

echo " "
echo -e "${PREFIX} Are you installing onto a Raspberry Pi 4, 3, CM3, or 2?"
read -r -p "[4/3/CM3/2]: " input
case $input in
    [4])
    export PI="4"
    ;;
    [3]|[cC][mM][3]|[2])
    export PI="3"
    ;;
    *)
    echo -e "${PREFIX} Invalid input"
    exit 1
    ;;
esac

echo " "
echo -e "${PREFIX} Do you want the tool to download the UEFI, drivers, and PE-installer automatically? Say 'N' to use your own files"
read -r -p "[Y/N]: " input
echo " "
case $input in

    [yY][eE][sS]|[yY])

    if ! command -v wget &> /dev/null
    then
        echo -e "${PREFIX} - 'wget' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install wget'; for Arch, run 'sudo pacman -S wget'; for macOS, run 'brew install wget')"
        exit 1
    fi

    efiURL="$(wget -qO- https://api.github.com/repos/pftf/RPi${PI}/releases/latest | grep '"browser_download_url":'".*RPi${PI}_UEFI_Firmware_.*\.zip" | sed 's/^.*browser_download_url": "//g' | sed 's/"$//g')"
    wget -O "/tmp/UEFI_Firmware.zip" "$efiURL" || error "Failed to download UEFI"
    drivURL="$(wget -qO- https://api.github.com/repos/worproject/RPi-Windows-Drivers/releases/latest | grep '"browser_download_url":'".*RPi${PI}_Windows_ARM64_Drivers_.*\.zip" | sed 's/^.*browser_download_url": "//g' | sed 's/"$//g')"
    wget -O "/tmp/Windows_ARM64_Drivers.zip" "$drivURL" || error "Failed to download drivers"
    peuuid="$(wget --spider --content-disposition --trust-server-names -O /dev/null "https://worproject.com/dldserv/worpe/downloadlatest.php" 2>&1 | grep Location | sed 's/^Location: //g' | sed 's/ \[following\]$//g' | grep 'drive\.google\.com' | sed 's+.*/++g' | sed 's/.*&id=//g')"
    wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id='"$peuuid" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$peuuid" -O "/tmp/WoR-PE_Package.zip" && rm -rf /tmp/cookies.txt

    export efi="/tmp/UEFI_Firmware.zip"
    export driv="/tmp/Windows_ARM64_Drivers.zip"
    export inst="/tmp/WoR-PE_Package.zip"
    export auto="1"
    ;;

    [nN][oO]|[nN])

    echo " "
    echo -e "${PREFIX} - Download the UEFI package (not the source code):"
    echo -e "${PREFIX}   - for Pi 4 and newer: https://github.com/pftf/RPi4/releases"
    echo -e "${PREFIX}   - for Pi 2, 3, CM3: https://github.com/pftf/RPi3/releases"
    echo -e "${PREFIX} - Then, rename the ZIP file to 'UEFI_Firmware.zip'"
    echo " "
    echo -e "${PREFIX} What's the path to 'UEFI_Firmware.zip'?"
    read -r -p "[/*] E.g. '~/UEFI_Firmware.zip': " efi

    echo " "
    echo -e "${PREFIX} - Go to https://worproject.com/downloads#windows-on-raspberry-pe-based-installer and download the 'Windows on Raspberry PE-based installer', then rename the ZIP file to 'WoR-PE_Package.zip'"
    echo " "
    echo -e "${PREFIX} What's the path to 'WoR-PE_Package.zip'?"
    read -r -p "[/*] E.g. '~/WoR-PE_Package.zip': " inst

    echo " "
    echo -e "${PREFIX} - Download the driver package from: https://github.com/worproject/RPi-Windows-Drivers/releases (get the ZIP archive with the RPi prefix followed by your board version) and rename the ZIP file to Windows_ARM64_Drivers.zip"
    echo " "
    echo -e "${PREFIX} What's the path to 'Windows_ARM64_Drivers.zip'?"
    read -r -p "[/*] E.g. '~/Windows_ARM64_Drivers.zip': " driv
    ;;

    *)

    echo -e "${PREFIX} Invalid input"
    exit 1
    ;;
esac

echo " "
if [ -f $efi ]; then
    echo -e "${PREFIX} 'UEFI_Firmware.zip' found"
else
    echo -e "${PREFIX} 'UEFI_Firmware.zip' does not exist. Abort."
    exit 1
fi
if [ -f $driv ]; then
    echo -e "${PREFIX} 'Windows_ARM64_Drivers.zip' found"
else
    echo -e "${PREFIX} 'Windows_ARM64_Drivers.zip' does not exist. Abort."
    exit 1
fi
if [ -f $inst ]; then
    echo -e "${PREFIX} 'WoR-PE_Package.zip' found"
else
    echo -e "${PREFIX} 'WoR-PE_Package.zip' does not exist. Abort."
    exit 1
fi

echo " "
echo -e "${PREFIX} Prerequisites"
echo " "
echo -e "${PREFIX} - Get the windows ISO: https://worproject.com/guides/getting-windows-images"
echo -e "${PREFIX} - Rename the ISO file to 'win.iso'"
echo " "
echo -e "${PREFIX} - If you want use use a modified install.wim, rename it to 'install.wim'. NOTE: You will still need the ISO where the WIM came from"
echo " "
echo -e "${PREFIX} - If you're using a Raspberry Pi 4, you must update the Bootloader to the latest version: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#updating-the-bootloader"

echo " "
if ! command -v wimupdate &> /dev/null
then
    echo -e "${PREFIX} - 'wimtools' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install wimtools'; for Arch, run 'sudo pacman -S wimtools')"
    exit 1
fi

if [[ $MACOS == *"1"* ]]; then
    if ! command -v gdisk &> /dev/null
    then
        echo -e "${PREFIX} - 'gdisk' package not installed. Install it ('brew install gdisk')"
        exit 1
    fi
else
    if ! command -v parted &> /dev/null
    then
        echo -e "${PREFIX} - 'parted' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install parted'; for Arch, run 'sudo pacman -S parted')"
        exit 1
    fi
fi

if ! command -v mkfs.exfat &> /dev/null
then
    echo -e "${PREFIX} - 'mkfs.exfat' command not found. Install it (For Debaian and Ubuntu, run 'sudo apt install exfatprogs'; For Arch, run 'sudo pacman -S exfatprogs')"
    exit 1
fi

echo -e "${PREFIX} \e[0;31mDO THE PREREQUISITES STUFF BEFORE CONTINUING\e[0m"
read -p "Press any key to continue..."
echo " "

echo -e "${PREFIX} What's the path to the 'win.iso'?"
read -r -p "[/*] E.g. '~/win.iso': " iso
echo " "

echo -e "${PREFIX} Do you want to use a custom WIM?"
read -r -p "[N/Y]: " input
echo " "
case $input in

    [yY][eE][sS]|[yY])

    echo -e "${PREFIX} what's the path to the 'install.wim'?"
    read -r -p "[/*] E.g. '~/install.wim': " wim
    export custwim="1"
    echo " "
    if [ -f $wim ]; then
        echo -e "${PREFIX} 'install.wim' found"
    else
        echo -e "${PREFIX} 'install.wim' does not exist. Abort."
        exit 1
    fi
    ;;

    [nN][oO]|[nN])

    echo " "
    echo -e "${PREFIX} No custom WIM then"
    export custwim="0"
    ;;

    *)

    echo -e "${PREFIX} Invalid input"
    exit 1
    ;;
esac

echo " "
if [ -f $iso ]; then
    echo -e "${PREFIX} 'win.iso' found"
else
    echo -e "${PREFIX} 'win.iso' does not exist. Abort."
    exit 1
fi

echo " "
echo -e "${PREFIX} What /dev/* is your drive? NOTE: ALL your data on the selected disk will be ERASED, proceed with caution!"
echo -e "${PREFIX} ---------------------------------------------------------------------------------------------------------"
echo " "
if [[ $MACOS == *"1"* ]]; then
diskutil list
else
parted -l
fi
echo " "
read -r -p "[/dev/*] E.g. 'sdb', 'mmcblk0', 'disk7': " disk

echo -e "${PREFIX} You have selected '$disk', is this correct?"
read -r -p "[Y/N]: " input
case $input in
    [yY][eE][sS]|[yY])
    echo -e "${PREFIX} ok '$disk' it is then"
    ;;
    [nN][oO]|[nN])
    echo -e "${PREFIX} Abort."
    exit 1
    ;;
    *)
    echo -e "${PREFIX} Invalid input"
    exit 1
    ;;
esac

if [[ $disk == *"mmcblk"* ]]; then
    export nisk="${disk}p"
else
    export nisk="$disk"
fi

if [[ $disk == *"disk"* ]]; then
    export nisk="${disk}s"
else
    export nisk="$disk"
fi

if [[ $disk == *"/dev"* ]]; then
    echo -e "${PREFIX} DO NOT PUT '/dev', only put the name like 'sdb'"
    exit 1
else
    echo -e "${PREFIX} Disk name format correct"
fi

if [ -b "/dev/$disk" ]; then
   echo -e "${PREFIX} '$disk' found"
else
   echo -e "${PREFIX} '$disk' does not exist. Abort."
   exit 1
fi

echo -e "${PREFIX} \e[0;31mWARNING: THE DISK '$disk' WILL BE WIPED!\e[0m Do you want to continue?"
read -r -p "[Y/N]: " input
case $input in
    [yY][eE][sS]|[yY])
    echo -e "${PREFIX} No going back now"
    ;;
    [nN][oO]|[nN])
    echo -e "${PREFIX} Abort."
    exit 1
    ;;
    *)
    echo -e "${PREFIX} Invalid input"
    exit 1
    ;;
esac

echo " "
echo -e "${PREFIX} Creating partitions..."
echo " "
echo -e "${PREFIX} *Ignore the 'not mounted' errors, they are normal*"
echo " "

if [[ $MACOS == *"1"* ]]; then
    diskutil unmountDisk /dev/$disk
else
    umount /dev/$disk*
fi

if [[ $MACOS == *"1"* ]]; then

printf "o\nY\nn\n1\n\n+1000M\n0700\nw\nY\n" | sudo gdisk /dev/$disk
sync
#echo -e "${PREFIX} \e[0;31mNOTE:\e[0m Due to macOS weirdness you need to disconnect and reconnect the drive now"
#read -p "Press any key to continue..."

binbowstype() {
    echo " "
    echo -e "${PREFIX} [1]: Do you want the installer to be able to install Windows on the same drive (at least 32GB)?"
    echo -e "${PREFIX} [2]: OR create an installation media on this drive (at least 8GB) that's able to install Windows on other drives (at least 16GB)?"
    read -r -p "[1/2]: " input
    echo " "
    case $input in
        [1])
        printf "n\n2\n\n+19000M\n0700\nw\nY\n" | sudo gdisk /dev/$disk
        sync
        diskutil unmountDisk /dev/$disk
        #echo -e "${PREFIX} \e[0;31mNOTE:\e[0m Again, due to macOS weirdness you need to disconnect and reconnect the drive now"
        #read -p "Press any key to continue..."
        return 0
        ;;
        [2])
        printf "n\n2\n\n\n0700\nw\nY\n" | sudo gdisk /dev/$disk
        sync
        diskutil unmountDisk /dev/$disk
        #echo -e "${PREFIX} \e[0;31mNOTE:\e[0m Again, due to macOS weirdness you need to disconnect and reconnect the drive now"
        #read -p "Press any key to continue..."
        return 0
        ;;
        *)
        echo -e "${PREFIX} Invalid input"
        return 1
        ;;
    esac
}
until binbowstype; do : ; done

else

parted -s /dev/$disk mklabel gpt
parted -s /dev/$disk mkpart primary 1MB 1000MB
parted -s /dev/$disk set 1 msftdata on

binbowstype() {
    echo " "
    echo -e "${PREFIX} [1]: Do you want the installer to be able to install Windows on the same drive (at least 32GB)?"
    echo -e "${PREFIX} [2]: OR create an installation media on this drive (at least 8GB) that's able to install Windows on other drives (at least 16GB)?"
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
        echo -e "${PREFIX} Invalid input"
        return 1
        ;;
    esac
}
until binbowstype; do : ; done

fi

sync
sudo mkfs.fat -F 32 /dev/$nisk'1'
sync
sudo mkfs.exfat /dev/$nisk'2'
sync

mkdir -p /tmp/bootpart /tmp/winpart

if [[ $MACOS == *"1"* ]]; then
    diskutil mount -mountPoint /tmp/bootpart /dev/$nisk'1'
    diskutil mount -mountPoint /tmp/winpart /dev/$nisk'2'
else
    mount /dev/$nisk'1' /tmp/bootpart
    mount /dev/$nisk'2' /tmp/winpart
fi

echo " "
echo -e "${PREFIX} Copying Windows files to the drive, this may take a while..."
echo " "
echo -e "${PREFIX} *NOTE: 'WARNING: Device write-protected, mounted read-only' is also normal*"
echo " "

if [[ $MACOS == *"1"* ]]; then
    hdiutil attach $iso -mountpoint /tmp/isomount -nobrowse
else
    mount $iso /tmp/isomount
fi

cp -r /tmp/isomount/boot /tmp/bootpart
cp -r /tmp/isomount/efi /tmp/bootpart
mkdir /tmp/bootpart/sources
cp /tmp/isomount/sources/boot.wim /tmp/bootpart/sources

if [[ $custwim == *"1"* ]]; then
    cp $wim /tmp/winpart
else
    cp /tmp/isomount/sources/install.wim /tmp/winpart
fi

if [[ $MACOS == *"1"* ]]; then
    hdiutil detach /tmp/isomount
else
    umount /tmp/isomount
fi

echo " "
echo -e "${PREFIX} Copying the UEFI boot files to the drive..."
echo " "

unzip $efi -d /tmp/uefipackage
sudo cp /tmp/uefipackage/* /tmp/bootpart

echo " "
echo -e "${PREFIX} Copying the drivers to the drive..."
echo " "

unzip $driv -d /tmp/driverpackage
wimupdate /tmp/bootpart/sources/boot.wim 2 --command="add /tmp/driverpackage /drivers"

echo " "
echo -e "${PREFIX} Copying the PE-installer to the drive..."
echo " "

unzip $inst -d /tmp/peinstaller
cp -r /tmp/peinstaller/efi /tmp/bootpart
wimupdate /tmp/bootpart/sources/boot.wim 2 --command="add /tmp/peinstaller/winpe/2 /"

echo " "
echo -e "${PREFIX} *Ignore 'cp: -r not specified; omitting directory...'*"

echo " "
if [[ $PI == *"3"* ]]; then
    echo -e "${PREFIX} Installing to Pi 3 and below, applying gptpatch..."
    echo " "
    dd if=/tmp/peinstaller/pi3/gptpatch.img of=/dev/$disk conv=fsync
else
    echo -e "${PREFIX} Installing to Pi 4, no need to apply gptpatch"
fi

echo " "
echo -e "${PREFIX} Unmounting drive, this may also take a while..."

sync

echo " "
echo -e "${PREFIX} *Again, ignore the 'not mounted' errors, they are normal*"
echo " "

if [[ $MACOS == *"1"* ]]; then
    diskutil unmountDisk /dev/$disk
else
    umount /dev/$disk*
fi

echo " "
echo -e "${PREFIX} Cleaning up..."

rm -rf /tmp/driverpackage
rm -rf /tmp/uefipackage
rm -rf /tmp/peinstaller
rm -rf /tmp/isomount
rm -rf /tmp/bootpart
rm -rf /tmp/winpart

if [[ $auto == *"1"* ]]; then
    rm -rf /tmp/UEFI_Firmware.zip
    rm -rf /tmp/Windows_ARM64_Drivers.zip
    rm -rf /tmp/WoR-PE_Package.zip
else
    echo " "
    echo -e "${PREFIX} No need to clear downloaded files"
fi

echo " "
echo -e "${PREFIX} 1. Connect the drive and other peripherals to your Raspberry Pi then boot it up."
echo " "
echo -e "${PREFIX} 2. Assuming everything went right in the previous steps, you'll be further guided by the PE-based installer on your Pi."
echo " "
echo -e "${PREFIX}   - If you've used the 1st method (self-installation), there's no need to touch the Raspberry Pi once it has booted. The installer will automatically start the installation process after a delay of 15 seconds. Moving the mouse cursor over the Windows Setup window will stop the timer, so you'll have to manually click on the Install button."
echo " "
echo -e "${PREFIX}   - If you've used the 2nd method (installing on a secondary drive), you must also connect the 2nd drive before the installer window opens up, then select it in the drop-down list. Otherwise, it will assume you're trying to install Windows on the same drive (self-installation)."
echo " "
echo -e "${PREFIX} \e[0;31mNOTE:\e[0m Disabling the 3gb ram limit before the first boot can cause the disk to not be recognized in the PE-installer. The limit can be removed AFTER the installation."
echo " "

echo -e "${PREFIX} All done :)"
echo -e "${PREFIX} Thanks for using WoRli!"
echo " "
exit 0
