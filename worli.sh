#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "this script needs to be ran as root. if your a noob thats 'sudo ./worli.sh'"
  exit
fi
echo  "WORli, made by JoJo Autoboy#1111"
echo  "heavily based off of Mario's wor linux guide: https://www.worproject.ml/guides/how-to-install/from-other-os"

mkdir -p /tmp/isomount
chmod 777 /tmp/isomount

echo " "
echo -e "are you installing to a Raspberry Pi 4 or a Raspberry Pi 3, CM3 or 2?"
read -r -p "[4/3]: " input
case $input in
    [4])
 export PI="4"
 ;;
    [3])
 export PI="3"
       ;;
    *)
 echo "Invalid input..."
 exit 1
 ;;
esac 

echo " "
echo -e "do you want the tool to download the uefi, drivers and pe-installer or use your own files?"
read -r -p "[Y/N]: " input
case $input in
    [yY][eE][sS]|[yY])
    
    if ! command -v wget &> /dev/null
    then
        echo "- wget package not installed. install it (for debian and ubuntu its 'sudo apt install wget', for arch it's also wget)"
        exit 1
    fi

  efiURL="$(wget -qO- https://api.github.com/repos/pftf/RPi${PI}/releases/latest | grep '"browser_download_url":'".*RPi${PI}_UEFI_Firmware_.*\.zip" | sed 's/^.*browser_download_url": "//g' | sed 's/"$//g')"
  wget -O "/tmp/UEFI_Firmware.zip" "$efiURL" || error "Failed to download UEFI"
  
  drivURL="$(wget -qO- https://api.github.com/repos/worproject/RPi-Windows-Drivers/releases/latest | grep '"browser_download_url":'".*RPi${PI}_Windows_ARM64_Drivers_.*\.zip" | sed 's/^.*browser_download_url": "//g' | sed 's/"$//g')"
  wget -O "/tmp/Windows_ARM64_Drivers.zip" "$drivURL" || error "Failed to download drivers"
  
  peuuid="$(wget --spider --content-disposition --trust-server-names -O /dev/null "https://worproject.ml/dldserv/worpe/downloadlatest.php" 2>&1 | grep Location | sed 's/^Location: //g' | sed 's/ \[following\]$//g' | grep 'drive\.google\.com' | sed 's+.*/++g' | sed 's/.*&id=//g')"
  wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id='"$peuuid" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$peuuid" -O "/tmp/WoR-PE_Package.zip" && rm -rf /tmp/cookies.txt || error "Failed to download pe-installer"
  
  export efi="/tmp/UEFI_Firmware.zip"
  
  export driv="/tmp/Windows_ARM64_Drivers.zip"
  
  export inst="/tmp/WoR-PE_Package.zip"
  
  export auto="1"
  
 ;;
    [nN][oO]|[nN])
    
    echo " "
    echo "- go to https://www.worproject.ml/downloads#windows-on-raspberry-pe-based-installer and download the 'Windows on Raspberry PE-based installer' then rename the zip to 'WoR-PE_Package.zip'"
    echo " "
    
    echo "what's the path to the 'WoR-PE_Package.zip'?"
    read -r -p "[/*] eg '~/WoR-PE_Package.zip': " inst
    
    echo " "
    echo "- download the driver package from: https://github.com/worproject/RPi-Windows-Drivers/releases (get the ZIP archive with the RPi prefix followed by your board version) and rename the zip to Windows_ARM64_Drivers.zip"
    echo " "
    
    echo "what's the path to the 'Windows_ARM64_Drivers.zip'?"
    read -r -p "[/*] eg '~/Windows_ARM64_Drivers.zip': " driv
    
    echo "- download the UEFI package: (not the source code)"
    echo "  for Pi 4 and newer: https://github.com/pftf/RPi4/releases" 
    echo "  for Pi 2, 3, CM3: https://github.com/pftf/RPi3/releases"
    echo "  then rename the zip to 'UEFI_Firmware.zip'"
    echo " "
    
    echo "what's the path to the 'UEFI_Firmware.zip'?"
    read -r -p "[/*] eg '~/UEFI_Firmware.zip': " efi
       ;;
    *)
 echo "Invalid input..."
 exit 1
 ;;
esac

echo " "
if [ -f $inst ]; then
    echo "WoR-PE_Package.zip found"
else 
    echo "WoR-PE_Package.zip does not exist. abort."
    exit 1
fi

if [ -f $driv ]; then
    echo "Windows_ARM64_Drivers.zip found"
else 
    echo "Windows_ARM64_Drivers.zip does not exist. abort."
    exit 1
fi

if [ -f $efi ]; then
    echo "UEFI_Firmware.zip found"
else 
    echo "UEFI_Firmware.zip does not exist. abort."
    exit 1
fi

echo " "
echo "prerequisites"
echo " "
echo "- get the windows iso: https://www.worproject.ml/guides/getting-windows-images"
echo "  rename the iso to 'win.iso'"
echo " "
echo "- (NOT RECOMMENDED) if you want use use a custom wim rename it to 'install.wim' NOTE: you still need the iso the wim came from"
echo " "
echo "- If you're using a Raspberry Pi 4, you must update the bootloader to the latest version: https://www.raspberrypi.org/documentation/computers/raspberry-pi.html#updating-the-bootloader"
echo " "

if ! command -v wimupdate &> /dev/null
then
    echo "- wimtools package not installed. install it (for debian and ubuntu its 'sudo apt install wimtools', for arch it's wimlib)"
    exit 1
fi

if ! command -v parted &> /dev/null
then
    echo "- parted package not installed. install it (for debian and ubuntu its 'sudo apt install parted', for arch it's also parted)"
    exit 1
fi

if ! command -v mkfs.ntfs &> /dev/null
then
    echo "- mkfs.ntfs command not found. install ntfs support somehow (like ntfs-3g and ntfsprogs)"
    exit 1
fi

echo -e "\e[0;31mDO THE PRE STUFF BEFORE CONTINUING\e[0m"

echo " "
read -p "Press any key to continue..."
echo " "

echo "what's the path to the 'win.iso'?"
read -r -p "[/*] eg '~/win.iso': " iso

echo " "
echo "do you want to use a custom wim?"
echo " "

read -r -p "[N/Y]: " input
case $input in
    [yY][eE][sS]|[yY])
    
    echo "what's the path to the 'install.wim'?"
    read -r -p "[/*] eg '~/install.wim': " wim
    
    echo " "
    if [ -f $wim ]; then
        echo "install.wim found"
    else 
        echo "install.wim does not exist. abort."
        exit 1
    fi
 ;;
    [nN][oO]|[nN])
    echo " "
    echo "no custom wim then"

       ;;
    *)
 echo "Invalid input..."
 exit 1
 ;;
esac

echo " "
if [ -f $iso ]; then
    echo "win.iso found"
else 
    echo "win.iso does not exist. abort."
    exit 1
fi
echo " "

echo  "what /dev/* is your drive? NOTE: all your data on the selected disk will be erased, proceed with caution"
echo  "--------------------------------------------------------------------------------------------------------"

parted -l

read -r -p "[/dev/*] eg 'sdb', 'mmcblk0': " disk

echo "you have selected '$disk' is this correct?"
read -r -p "[Y/N]: " input
case $input in
    [yY][eE][sS]|[yY])
 echo "ok $disk it is"
 ;;
    [nN][oO]|[nN])
 echo "abort."
 exit 1
       ;;
    *)
 echo "Invalid input..."
 exit 1
 ;;
esac 

if [[ $disk == *"mmcblk"* ]]; then
    export nisk="${disk}p"
else
    export nisk="$disk"
fi

if [[ $disk == *"/dev"* ]]; then
    echo "DO NOT PUT /dev, only put the name like 'sdb'"
    exit 1
else
   echo "disk name format correct" 
fi

if [ -b "/dev/$disk" ]; then
   echo "$disk found"
else 
   echo "$disk does not exist. abort."
   exit 1
fi

echo -e "\e[0;31mWARNING: THE DISK $disk WILL BE WIPED\e[0m do you want to continue?"
read -r -p "[Y/N]: " input
case $input in
    [yY][eE][sS]|[yY])
 echo "no going back now"
 ;;
    [nN][oO]|[nN])
 echo "abort."
 exit 1
       ;;
    *)
 echo "Invalid input..."
 exit 1
 ;;
esac 

echo " "
echo "creating partitions..."
echo " "

echo "ignore the 'not mounted' errors, they are normal"
echo " "
umount /dev/$disk*

parted -s /dev/$disk mklabel gpt

parted -s /dev/$disk mkpart primary 1MB 1000MB
parted -s /dev/$disk set 1 msftdata on

binbowstype() {
    echo " "
    echo  "1: do you want the installer to be able to install Windows on the same drive? (drive needs at least 32 GB)"
    echo  "2: OR create an installation media that's able to install Windows on other drives? (installation disk needs at least 8 GB, destination drive needs at least 16 GB)"
    read -r -p "[1/2]: " input
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
        echo "Invalid input..."
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
echo "copying windows files to the drive, this may take awhile"
echo " "
echo "note: 'WARNING: device write-protected, mounted read-only.' is also normal"
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
echo "copying the drivers to the drive..."
echo " "

unzip $inst -d /tmp/peinstaller

cp -r /tmp/peinstaller/efi /media/bootpart
wimupdate /media/bootpart/sources/boot.wim 2 --command="add /tmp/peinstaller/winpe/2 /"


unzip $driv -d /tmp/driverpackage
wimupdate /media/bootpart/sources/boot.wim 2 --command="add /tmp/driverpackage /drivers"

echo " "
echo "copying the uefi boot files to the drive..."
echo " "

unzip $efi -d /tmp/uefipackage
sudo cp /tmp/uefipackage/* /media/bootpart

echo " "
echo "ignore cp: -r not specified; omitting directory ..."
echo " "

if [[ $PI == *"3"* ]]; then
    echo "installing to pi 3, applying gptpatch"
    dd if=/tmp/peinstaller/pi3/gptpatch.img of=/dev/$disk conv=fsync
else
    echo "installing to pi 4, no need to apply gptpatch" 
fi

echo " "
echo "unmounting drive, this may also take awhile"
echo " "

sync

echo "again, ignore the 'not mounted' errors, they are normal"
umount /dev/$disk*


echo " "
echo "cleaning up..."

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
    echo "no need to clear downloaded files" 
fi



echo " "
echo "Connect the drive and other peripherals to your Raspberry Pi then boot it up."
echo " "
echo "Assuming everything went right in the previous steps, you'll be further guided by the PE-based installer on your Pi."
echo " "
echo "If you've used the first method (self-installation), there's no need to touch the Raspberry Pi once it has booted. The installer will automatically start the installation process after a delay of 15 seconds. Moving the mouse cursor over the Windows Setup window will stop the timer, so you'll have to manually click on the Install button."
echo " "
echo "If you've used the second method (install on a secondary drive), you must also connect the 2nd drive before the installer window opens up, then select it in the drop-down list. Otherwise it will assume you're trying to install Windows on the same drive (self-installation)."
echo " "
echo -e "\e[0;31mNOTE:\e[0m disabling the 3gb ram limit before first boot can cause the disk to not be reconized in the pe installer. after the instalation though the limit can be removed"
echo " "

echo "all done :)"
exit 1

