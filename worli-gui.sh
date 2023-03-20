#!/bin/bash

if ! command -v zenity &> /dev/null
then
    echo "'zenity' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install zenity'; for Arch, run 'sudo pacman -S zenity'; for macOS, run 'brew install zenity')"
fi

if [ "$EUID" -ne 0 ]
    then zenity --title "worli" --info --ok-label="Exit" --text "This script needs to be run as root. If you're a noob, that's 'sudo ./worli.sh' or 'sudo bash worli.sh'"
    exit 1
fi

debug() {
 echo -e "\e[1;36m[DEBUG]\e[0m $1" >&2
}

error() {
 zenity --error --title "worli" --text "An error has occurred.\n\nError: $1"
 echo -e "\e[1;31m[ERROR]\e[0m $1" >&2
 exit 1
}

if [[ $OSTYPE == 'darwin'* ]]; then
  zenity --title "worli" --info --ok-label="Next" --text "macOS detected, running in experimental macOS mode.\n\n Prerequisites\n Due to how brew works you need to run these commands in a non root shell:\n - 'brew install wimlib gdisk dosfstools gnu-sed gawk'\n - 'brew install --cask macfuse'\n - 'brew install --HEAD gmerlino/exfat/exfat'\n - You may need to disable SIP as stated <a href='https://www.rodsbooks.com/gdisk/'>here</a>"
  
  if ! command -v gdisk &> /dev/null
  then
    error "gdisk command not found"
  fi
  
  if ! command -v gawk &> /dev/null
  then
    error "gawk command not found"
  fi
  
  if ! command -v gsed &> /dev/null
  then
    error "gsed command not found"
  fi
  
  export MACOS=1
  export PATH=$PATH:/usr/local/sbin
else
  export MACOS=0
fi

zenity --title "worli" --info --ok-label="Next" --text "WoRli, made by JoJo Autoboy#1931\n\n Heavily based off of Mario's WoR Linux <a href='https://worproject.com/guides/how-to-install/from-other-os'>guide</a>"

mkdir -p /tmp/isomount
chmod 777 /tmp/isomount

zenity --question --title="worli" --text "Are you installing onto a Raspberry Pi 4, 3, CM3, or 2?" --ok-label="4" --cancel-label="3/CM3/2"
case $? in
    [0])
    export PI="4"
    zenity --title "worli" --info --ok-label="Next" --text "- If you're using a Raspberry Pi 4, you must update the Bootloader to the latest version: <a href='https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#updating-the-bootloader'>https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#updating-the-bootloader</a>"
    ;;
    [1])
    export PI="3"
    ;;
    *)
    error "Invalid input"
    exit 1
    ;;
esac

zenity --question --title="worli" --text "Do you want the tool to download the UEFI, drivers, and PE-installer automatically? Press 'No' to use your own files"

case $? in

    [0])

    if ! command -v wget &> /dev/null
    then
        zenity --title "worli" --info --ok-label="Exit" --text "'wget' package not installed. Install it\n\n For Debian and Ubuntu, run 'sudo apt install wget'\n\n for Arch, run 'sudo pacman -S wget'\n\n for macOS, run 'brew install wget'"
        exit 1
    fi

    if [[ $MACOS == *"1"* ]]; then
    efiURL="$(wget -qO- https://api.github.com/repos/pftf/RPi${PI}/releases/latest | grep '"browser_download_url":'".*RPi${PI}_UEFI_Firmware_.*\.zip" | gsed 's/^.*browser_download_url": "//g' | gsed 's/"$//g')"
    wget -O "/tmp/UEFI_Firmware.zip" "$efiURL" || error "Failed to download UEFI_Firmware.zip"
    drivURL="$(wget -qO- https://api.github.com/repos/worproject/RPi-Windows-Drivers/releases/latest | grep '"browser_download_url":'".*RPi${PI}_Windows_ARM64_Drivers_.*\.zip" | gsed 's/^.*browser_download_url": "//g' | gsed 's/"$//g')"
    wget -O "/tmp/Windows_ARM64_Drivers.zip" "$drivURL" || error "Failed to download Windows_ARM64_Drivers.zip"
    peuuid="$(wget --spider --content-disposition --trust-server-names -O /dev/null "https://worproject.com/dldserv/worpe/downloadlatest.php" 2>&1 | grep Location | gsed 's/^Location: //g' | gsed 's/ \[following\]$//g' | grep 'drive\.google\.com' | gsed 's+.*/++g' | gsed 's/.*&id=//g')"
    wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id='"$peuuid" -O- | gsed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$peuuid" -O "/tmp/WoR-PE_Package.zip" && rm -rf /tmp/cookies.txt || error "Failed to download WoR-PE_Package.zip"
    else
    efiURL="$(wget -qO- https://api.github.com/repos/pftf/RPi${PI}/releases/latest | grep '"browser_download_url":'".*RPi${PI}_UEFI_Firmware_.*\.zip" | sed 's/^.*browser_download_url": "//g' | sed 's/"$//g')"
    wget -O "/tmp/UEFI_Firmware.zip" "$efiURL" || error "Failed to download UEFI_Firmware.zip"
    drivURL="$(wget -qO- https://api.github.com/repos/worproject/RPi-Windows-Drivers/releases/latest | grep '"browser_download_url":'".*RPi${PI}_Windows_ARM64_Drivers_.*\.zip" | sed 's/^.*browser_download_url": "//g' | sed 's/"$//g')"
    wget -O "/tmp/Windows_ARM64_Drivers.zip" "$drivURL" || error "Failed to download Windows_ARM64_Drivers.zip"
    peuuid="$(wget --spider --content-disposition --trust-server-names -O /dev/null "https://worproject.com/dldserv/worpe/downloadlatest.php" 2>&1 | grep Location | sed 's/^Location: //g' | sed 's/ \[following\]$//g' | grep 'drive\.google\.com' | sed 's+.*/++g' | sed 's/.*&id=//g')"
    wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id='"$peuuid" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$peuuid" -O "/tmp/WoR-PE_Package.zip" && rm -rf /tmp/cookies.txt || error "Failed to download WoR-PE_Package.zip"
    fi
    
    
    export efi="/tmp/UEFI_Firmware.zip"
    export driv="/tmp/Windows_ARM64_Drivers.zip"
    export inst="/tmp/WoR-PE_Package.zip"
    export auto="1"
    ;;

    [1])

    zenity --title "worli" --info --ok-label="Next" --text "Download the UEFI package (not the source code):\n\n for Pi 4 and newer: <a href='https://github.com/pftf/RPi4/releases'>https://github.com/pftf/RPi4/releases</a>\n\n for Pi 2, 3, CM3: <a href='https://github.com/pftf/RPi3/releases'>https://github.com/pftf/RPi3/releases</a>\n\n Then, rename the ZIP file to 'UEFI_Firmware.zip'"

    efi=$(zenity --title "worli" --entry --text "What's the path to 'UEFI_Firmware.zip'?\n\n E.g. '~/UEFI_Firmware.zip'")

    zenity --title "worli" --info --ok-label="Next" --text "Go to\n<a href='https://worproject.com/downloads#windows-on-raspberry-pe-based-installer'>https://worproject.com/downloads#windows-on-raspberry-pe-based-installer</a> and download the 'Windows on Raspberry PE-based installer'\n\nthen rename the ZIP file to 'WoR-PE_Package.zip'"

    inst=$(zenity --title "worli" --entry --text "What's the path to 'WoR-PE_Package.zip'?\n\n E.g. '~/WoR-PE_Package.zip'")
    
    zenity --title "worli" --info --ok-label="Next" --text "Download the driver package from\n<a href='https://github.com/worproject/RPi-Windows-Drivers/releases'>https://github.com/worproject/RPi-Windows-Drivers/releases</a>\n\nget the ZIP archive with the RPi prefix followed by your board version\n\n and rename the ZIP file to Windows_ARM64_Drivers.zip"
    
    driv=$(zenity --title "worli" --entry --text "What's the path to 'Windows_ARM64_Drivers.zip'?\n\n E.g. '~/Windows_ARM64_Drivers.zip'")

    ;;

    *)

    error "Invalid input"
    ;;
esac

echo " "
if [ -f $efi ]; then
    debug "'UEFI_Firmware.zip' found"
else
    error "'UEFI_Firmware.zip' does not exist."
fi
if [ -f $driv ]; then
    debug "'Windows_ARM64_Drivers.zip' found"
else
    error "'Windows_ARM64_Drivers.zip' does not exist."
    exit 1
fi
if [ -f $inst ]; then
    debug "'WoR-PE_Package.zip' found"
else
    error "'WoR-PE_Package.zip' does not exist."
    exit 1
fi

if ! command -v wimupdate &> /dev/null
then
    wimtool=" - 'wimtools/wimlib' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install wimtools'; for Arch, run 'sudo pacman -S wimlib')"
    export requiredep=1
fi

if [[ $MACOS == *"1"* ]]; then
    if ! command -v gdisk &> /dev/null
    then
        debug "How tf-"
    fi
else
    if ! command -v parted &> /dev/null
    then
        parted=" - 'parted' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install parted'; for Arch, run 'sudo pacman -S parted')"
        export requiredep=1
    fi
fi

if ! command -v mkfs.exfat &> /dev/null
then
    exfat=" - 'mkfs.exfat' command not found. Install it (For Debaian and Ubuntu, run 'sudo apt install exfatprogs'; For Arch, run 'sudo pacman -S exfatprogs')"
    export requiredep=1
fi

if [[ $requiredep == *"1"* ]]; then
    zenity --title "worli" --info --ok-label="Exit" --text "Dependances\n\n$wimtool\n\n$parted\n\n$exfat"
    exit 1
else
    debug "All dependances are met!"
fi

zenity --question --title="worli" --text "Do you want this script to generate its own iso with uupdump? (press No to use your own iso or a previously generated one)"

case $? in

    [0])

if ! command -v jq &> /dev/null
then
    jq=" - 'jq' command not found."
    jqp="jq"
    export requiredep=1
fi
    
if ! command -v aria2c &> /dev/null
then
    aria2c=" - 'aria2c' command not found."
    aria2p="aria2"
    export requiredep=1
fi

if ! command -v cabextract &> /dev/null
then
    cabextract=" - 'cabextract' command not found."
    cabextractp="cabextract"
    export requiredep=1
fi

if ! command -v chntpw &> /dev/null
then
    chntpw=" - 'chntpw' command not found."
    chntpwp="chntpw"
    chntpwmac="sidneys/homebrew/chntpw"
    export requiredep=1
fi

if ! command -v mkisofs &> /dev/null && ! command -v genisoimage &> /dev/null
then
    mkisofs=" - 'genisoimage or mkisofs' command not found."
    mkisofsarmc="cdrtools"
    mkisofsdeb="genisoimage"
    export requiredep=1
fi

if [[ $requiredep == *"1"* ]]; then
    zenity --title "worli" --info --ok-label="Exit" --text "Dependances\n$jq\n$aria2c\n$cabextract\n$chntpw\n$mkisofs\n\ninstall them:\n\nFor Debaian and Ubuntu, run 'sudo apt install $jqp $aria2p $cabextractp $chntpwp $mkisofsdeb'\n\nFor Arch, run 'sudo pacman -S $jqp $aria2p $cabextractp $chntpwp $mkisofsarmc'\n\nFor macOS run 'brew install $jqp $aria2p $cabextractp $chntpwmac $mkisofsarmc'\n\nnote: if your on macos and the build for 'sidneys/homebrew/chntpw' fails try running 'brew install minacle/chntpw/chntpw'"
    exit 1
else
    debug "All dependances are met!"
fi
    
zenity --question --title="worli" --text "Do you want to use the latest retail/dev builds or enter your own uupdump.net build id? Press 'No' to use id"

case $? in
    [1])
    updateid=$(zenity --title "worli" --entry --text "What's the uupdump.net uuid?\n\n e.g once you select the build you want the id will be in the url like:\n\nhttps://uupdump.net/selectlang.php?id= '6b1e576c-9854-44b4-9cdd-108d13cf0035'")
    
    foundBuild=$(curl -sk "https://uupdump.net/json-api/listlangs.php?id=$updateid" | jq -r '.response.updateInfo.title')
    
    if [[ $? -ne 0 ]]; then
        error "Got rate limited or id is incrorrect, please try again"
    else
        debug "Not null thats good"
    fi
    
    ;;
    [0])
    release=$(zenity --list --title="worli" --text="What windows release type do you want?\nnote: defaults to dev" --column 'Release type'  "Latest Public Release build" "Latest Dev Channel build")
    
    
    if [[ $release == "Latest Public Release build" ]]; then
        export ring="retail&build=19041.1"
    else
        export ring="wif&build=latest"
    fi
    
    apiget=$(curl "https://uupdump.net/json-api/fetchupd.php?arch=arm64&ring=$ring" | jq -r '.response.updateArray[] | select( .updateTitle | contains("Windows")) | {Id: .updateId, Name: .updateTitle} ')
    
    if [[ $? -ne 0 ]]; then
        error "Probably got rate limited, please try again"
    else
        debug "Not null thats good"
    fi

    updateid=$(echo $apiget | jq -r .Id)

    foundBuild=$(echo $apiget | jq -r .Name)
    ;;
    *)
    exit 1
    ;;
esac

debug $foundBuild 

zenity --question --title="worli" --text "You are about to download:\n\n'$foundBuild'\n\nIs this ok?"

case $? in
    [0])
    debug "ok '$foundBuild' it is then"
    ;;
    [1])
    exit 1
    ;;
    *)
    exit 1
    ;;
esac

langjson=$(curl -sk "https://uupdump.net/json-api/listlangs.php?id=$updateid" | jq -r '.response.langFancyNames')

if [[ $? -ne 0 ]]; then
    error "Probably got rate limited, please try again"
else
    debug "Not null thats good"
fi

var=$(echo "$langjson" | cut -d\" -f4 | tr -d '{}' | tr '\n' '|'); var="${var#?}"; var="${var%?}"; var="${var%?}"

langa=$(zenity --forms --title "worli" --text "language" --add-combo "Choose your language." --combo-values "$var")

if [[ -z "$langa" ]]
    then error "No language was selected"
fi 

language=$(echo "$langjson" | grep "$langa" | cut -d\" -f2)

debug "language is $language"

tmpuupvar=$(zenity --question --title="worli" --text "Do you want the iso to be deleted when the script finishes?\n\nnote: the uup files and iso will be put in the current directory ($PWD/uup)\n\nnote: the /tmp option is not recommended as /tmp can be too small to fit the files needed (4gb+)\n\nnote: the /tmp option will delete the iso when the script finishes" --extra-button "generate iso in /tmp")

case $? in
    [0])
    uuproot="$(pwd)"
    export deluup=1
    ;;
    [1])
    uuproot="$(pwd)"
    ;;
    *)
    exit 1
    ;;
esac

if [[ $tmpuupvar == "generate iso in /tmp" ]]; then
    mkdir /tmp/tmpuup
    uuproot=/tmp/tmpuup
    export tmpuup=1
fi

wget -O "/tmp/UUP.zip" "https://uupdump.net/json-api/get.php?id=$updateid&pack=en-us&edition=professional&autodl=2" || error "Failed to download UUP.zip"

export uupzip=1

unzip "/tmp/UUP.zip" -d "$uuproot/uup"

zenity --question --title="worli" --text "uupdump is known to be unstable sometimes and may require multiple tries to sucessfully download all reqired files.\n\nto combat this, do you want to enable auto retry? It will indefinitely rerun the uup script until it suceeds.\n\nyou can stop this any time by pressing the cancel button on the 'progress' window or by ctrl+c'ing the terminal this script is running from"

case $? in
    [0])
    export autoretry=1
    export counter=1
    ;;
    [1])
    export autoretry=0
    ;;
    *)
    exit 1
    ;;
esac


zenity --title "worli" --info --ok-label="Continue" --text "The uupdump script will now be executed\nIts output will be in the terminal where this script was ran"

cd $uuproot/uup

chmod +x uup_download_linux.sh

isogen() {
 ./uup_download_linux.sh >&2
}

(

isogen
if [[ $? -ne 0 ]]; then
    if [[ $autoretry == *"1"* ]]; then
    echo "# auto retry enabled, current amount of attempts: $counter"
    sleep 5
    isogen
    while [ $? -ne 0 ]; do
        counter=$(( counter + 1 ))
        echo "# auto retry enabled, current amount of attempts: $counter"
        sleep 5
        isogen
    done
    else
    error "auto retry disabled, quitting scritpt"
    fi
else
    zenity --title "worli" --info --ok-label="Continue" --text "The uupdump script suceeded!"
fi

) |
zenity --progress \
  --title="worli" \
  --text="Generating iso...." \
  --pulsate \
  --auto-close
  
(( $? != 0 )) && exit 1 

cd ../

if [ -f "$uuproot/uup/"*ARM64*.ISO ]; then
    debug "iso found"
    iso=$(find $uuproot/uup/ -name "*ARM64*.ISO")
else
    error "iso not found."
fi

    ;;

    [1])

zenity --title "worli" --info --ok-label="Next" --text "Prerequisites\n\n- Get the windows ISO: <a href='https://worproject.com/guides/getting-windows-images'>https://worproject.com/guides/getting-windows-images</a>\n\n- Rename the ISO file to 'win.iso'\n\n- If you want use use a modified install.wim, rename it to 'install.wim'\n NOTE: You will still need the ISO where the WIM came from\n\n<span color=\"red\">DO THE PREREQUISITES BEFORE CONTINUING</span>"

if [[ -f $(find $(pwd)/uup/ -name "*ARM64*.ISO") ]] || [[ -f $(find /tmp/uup -name "*ARM64*.ISO") ]] ; then

zenity --question --title="worli" --text "Previously generated iso found, would you like to use that or use another one?"

case $? in
    [0])
    iso=$(find $(pwd)/uup/ -name "*ARM64*.ISO") || iso=$(find /tmp/uup -name "*ARM64*.ISO")
    ;;
    [1])
    iso=$(zenity --title "worli" --entry --text "What's the path to the 'win.iso'?\n\n E.g. '~/win.iso'")
    ;;
    *)
    exit 1
    ;;
esac

else

iso=$(zenity --title "worli" --entry --text "What's the path to the 'win.iso'?\n\n E.g. '~/win.iso'")

fi

case $? in

    [1])
    wim=$(zenity --title "worli" --entry --text "What's the path to the 'install.wim'?\n\n E.g. '~/install.wim'")
    export custwim="1"

    if [ -f $wim ]; then
        debug "'install.wim' found"
    else
        error "'install.wim' does not exist."
    fi
    ;;

    [0])

    debug "No custom WIM then"
    export custwim="0"
    ;;

    *)

    error "Invalid input"
    exit 1
    ;;
esac
    ;;

    *)

    error "Invalid input"
    exit 1
    ;;
esac


if [ -f $iso ]; then
    debug "'win.iso' found"
else
    error "'win.iso' does not exist. iso veriable was set to '$iso'"
fi

disko () {

if [[ $MACOS == *"1"* ]]; then

export fdisk=$(diskutil list | grep disk | grep -v /dev/disk | grep -v disk.*s | grep -v + | cut -d'*' -f2 | gawk '{ printf "FALSE""\0"$0"\0" }' | xargs -0 zenity --list --title="worli" --text="What /dev/* is your drive?" --radiolist --multiple --column ' ' --column 'Disks' --extra-button "Rescan")

(( $? != 0 )) && exit 1

disk=$(echo $fdisk | grep -o disk.*)

else

export fdisk=$(sudo parted -l | grep "Disk /dev*" | grep -v loop | sort | awk '{ printf "FALSE""\0"$0"\0" }' | xargs -0 zenity --list --title="worli" --text="What /dev/* is your drive?" --radiolist --multiple --column ' ' --column 'Disks' --extra-button "Rescan")

(( $? != 0 )) && exit 1

sdisk=${fdisk#Disk /dev/*}
disk="${sdisk%%:*}"
fi

}
 
disko

while [[ $fdisk == *"Rescan"* ]]; do
    disko
done

zenity --question --title="worli" --text "You have selected '$disk', is this correct?"

case $? in
    [0])
    debug "ok '$disk' it is then"
    ;;
    [1])
    exit 1
    ;;
    *)
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
    error "how.... ('/dev' is in disk name)"
else
    debug "Disk name format correct"
fi

if [ -b "/dev/$disk" ]; then
   debug "'$disk' found"
else
   error "'$disk' does not exist."
fi

zenity --question --title="worli" --text '<span color=\"red\">WARNING: THE DISK '$disk' WILL BE WIPED!</span>\n\n Do you want to continue?' --ok-label="No" --cancel-label="Yes"

case $? in
    [1])
    debug "No going back now"
    ;;
    [0])
    exit 1
    ;;
    *)
    error "Invalid input"
    ;;
esac

(

echo "# Creating partitions..."

debug "Creating partitions..."

if [[ $MACOS == *"1"* ]]; then
    diskutil unmountDisk /dev/$disk
else
    umount /dev/$disk*
fi

if [[ $MACOS == *"1"* ]]; then

printf "o\nY\nn\n1\n\n+1000M\n0700\nw\nY\n" | sudo gdisk /dev/$disk || error "Failed to partition disk"
sync
diskutil unmountDisk /dev/$disk || error "Failed to unmount disk"
#echo -e "${PREFIX} \e[0;31mNOTE:\e[0m Due to macOS weirdness you need to disconnect and reconnect the drive now"
#read -p "Press enter to continue..."

echo "10"

binbowstype() {
    zenity --question --title="worli" --text "[1]: Do you want the installer to be able to install Windows on the same drive (at least 32GB)?\n\n[2]: OR create an installation media on this drive (at least 8GB) that's able to install Windows on other drives (at least 16GB)?" --ok-label="1" --cancel-label="2"
    case $? in
        [0])
        printf "n\n2\n\n+19000M\n0700\nw\nY\n" | sudo gdisk /dev/$disk || error "Failed to partition disk"
        sync
        diskutil unmountDisk /dev/$disk || error "Failed to unmount disk"
        echo "20"
        #echo -e "${PREFIX} \e[0;31mNOTE:\e[0m Again, due to macOS weirdness you need to disconnect and reconnect the drive now"
        #read -p "Press enter to continue..."
        return 0
        ;;
        [1])
        printf "n\n2\n\n\n0700\nw\nY\n" | sudo gdisk /dev/$disk || error "Failed to partition disk"
        sync
        diskutil unmountDisk /dev/$disk || error "Failed to unmount disk"
        echo "20"
        #echo -e "${PREFIX} \e[0;31mNOTE:\e[0m Again, due to macOS weirdness you need to disconnect and reconnect the drive now"
        #read -p "Press enter to continue..."
        return 0
        ;;
        *)
        debug "Invalid input"
        return 1
        ;;
    esac
}
until binbowstype; do : ; done

else

parted -s /dev/$disk mklabel gpt
parted -s /dev/$disk mkpart primary 1MB 1000MB
parted -s /dev/$disk set 1 msftdata on

echo "10"

binbowstype() {
    zenity --question --title="worli" --text "[1]: Do you want the installer to be able to install Windows on the same drive (at least 32GB)?\n\n[2]: OR create an installation media on this drive (at least 8GB) that's able to install Windows on other drives (at least 16GB)?" --ok-label="1" --cancel-label="2"
    case $? in
        [0])
        parted -s /dev/$disk mkpart primary 1000MB 19000MB
        parted -s /dev/$disk set 2 msftdata on
        echo "20"
        return 0
        ;;
        [1])
        parted -s -- /dev/$disk mkpart primary 1000MB -0
        parted -s /dev/$disk set 2 msftdata on
        echo "20"
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
if [[ $MACOS == *"1"* ]]; then
    diskutil unmountDisk /dev/$disk || error "Failed to unmount disk"
fi
mkfs.fat -F 32 /dev/$nisk'1' || error "Failed to format disk"
sync
if [[ $MACOS == *"1"* ]]; then
    diskutil unmountDisk /dev/$disk || error "Failed to unmount disk"
fi
mkfs.exfat /dev/$nisk'2' || error "Failed to format disk"
sync
echo "30"

echo "# Mounting partitions..."

mkdir -p /tmp/bootpart /tmp/winpart

if [[ $MACOS == *"1"* ]]; then
    diskutil mount -mountPoint /tmp/bootpart /dev/$nisk'1'
    diskutil mount -mountPoint /tmp/winpart /dev/$nisk'2'
else
    mount /dev/$nisk'1' /tmp/bootpart
    mount /dev/$nisk'2' /tmp/winpart
fi

echo "40"
echo "# Copying Windows files to the drive\n\nthis may take a while..."
debug "Copying Windows files to the drive."

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

echo "50"
echo "# Copying the PE-installer to the drive..."
debug "Copying the PE-installer to the drive."

unzip $inst -d /tmp/peinstaller
cp -r /tmp/peinstaller/efi /tmp/bootpart
wimupdate /tmp/bootpart/sources/boot.wim 2 --command="add /tmp/peinstaller/winpe/2 /"

echo "60"
echo "# Copying the drivers to the drive..."
debug "Copying the drivers to the drive."

unzip $driv -d /tmp/driverpackage
wimupdate /tmp/bootpart/sources/boot.wim 2 --command="add /tmp/driverpackage /drivers"

echo "70"
echo "# Copying the UEFI boot files to the drive..."
debug "Copying the UEFI boot files to the drive."

unzip $efi -d /tmp/uefipackage
sudo cp /tmp/uefipackage/* /tmp/bootpart

if [[ $PI == *"3"* ]]; then
    echo "# Installing to Pi 3 and below, applying gptpatch..."
    dd if=/tmp/peinstaller/pi3/gptpatch.img of=/dev/$disk conv=fsync
else
    debug "Installing to Pi 4, no need to apply gptpatch"
fi

echo "80"
echo "# Unmounting drive\n\nthis may also take a while..."
debug "Unmounting drive."

sync

if [[ $MACOS == *"1"* ]]; then
    diskutil unmountDisk /dev/$disk
else
    umount /dev/$disk*
fi

echo "90"
echo "# Cleaning up..."

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
    debug "No need to clear downloaded files"
fi

if [[ $tmpuup == *"1"* ]]; then
    rm -rf /tmp/tmpuup
else
    debug "No need to clear tmp uup"
fi

if [[ $deluup == *"1"* ]]; then
    rm -rf $uuproot/uup
else
    debug "uups set to not be deleted"
fi

if [[ $uupzip == *"1"* ]]; then
    rm -rf /tmp/UUP.zip
else
    debug "No need to clear uup zip"
fi

echo "100"
echo "# Press OK to continue"

) |
zenity --progress \
  --title="worli" \
  --text="Creating partitions..." \
  --percentage=0

(( $? != 0 )) && exit 1
  
zenity --title "worli" --info --ok-label="Done!" --text "Booting\n\n1. Connect the drive and other peripherals to your Raspberry Pi then boot it up.\n\n2. Assuming everything went right in the previous steps, you'll be further guided by the PE-based installer on your Pi.\n\n\n  - If you've used the 1st method (self-installation), there's no need to touch the Raspberry Pi once it has booted. The installer will automatically start the installation process after a delay of 15 seconds. Moving the mouse cursor over the Windows Setup window will stop the timer, so you'll have to manually click on the Install button.\n\n  - If you've used the 2nd method (installing on a secondary drive), you must also connect the 2nd drive before the installer window opens up, then select it in the drop-down list. Otherwise, it will assume you're trying to install Windows on the same drive (self-installation).\n\n\n<span color=\"red\">NOTE:</span> Disabling the 3gb ram limit before the first boot can cause the disk to not be recognized in the PE-installer. The limit can be removed AFTER the installation.\n\n\nAll done :)\nThanks for using WoRli: gui edition!"

debug "It has finnished"

exit 0
