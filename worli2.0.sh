#!/bin/bash

if ! command -v zenity &> /dev/null
then
    echo "'zenity' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install zenity'; for Arch, run 'sudo pacman -S zenity')"
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

zenity --title "worli" --info --ok-label="Next" --text "WoRli2.0, made by JoJo Autoboy#1931\n\n Somewhat based off of Mario's WoR Linux <a href='https://worproject.com/guides/how-to-install/from-other-os'>guide</a>"

mkdir -p /tmp/worli/
chmod 777 /tmp/worli/

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

zenity --question --title="worli" --text "Do you want the tool to download the UEFI, drivers, PE setup script/batchexec and ntfs bootloader automatically? Press 'No' to use your own files"

case $? in

    [0])

    if ! command -v wget &> /dev/null
    then
        zenity --title "worli" --info --ok-label="Exit" --text "'wget' package not installed. Install it\n\n For Debian and Ubuntu, run 'sudo apt install wget'\n\n for Arch, run 'sudo pacman -S wget'\n\n for macOS, run 'brew install wget'"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null
    then
        zenity --title "worli" --info --ok-label="Exit" --text "'jq' package not installed. Install it\n\n For Debian and Ubuntu, run 'sudo apt install jq'\n\n for Arch, run 'sudo pacman -S jq'"
        exit 1
    fi

    
    efiURL="$(curl https://api.github.com/repos/pftf/RPi${PI}/releases/latest | jq -r '.assets[] | .browser_download_url')"
    
    wget -O "/tmp/worli/UEFI_Firmware.zip" "$efiURL" || error "Failed to download UEFI_Firmware.zip"
    
    drivURL="$(curl https://api.github.com/repos/worproject/RPi-Windows-Drivers/releases/latest | jq -r '.assets[] | .browser_download_url' | grep RPi${PI})"
    
    wget -O "/tmp/worli/Windows_ARM64_Drivers.zip" "$drivURL" || error "Failed to download Windows_ARM64_Drivers.zip"
    
    wget -O "/tmp/worli/bootaa64.efi" "https://github.com/pbatard/uefi-ntfs/releases/latest/download/bootaa64.efi" || error "Failed to download bootaa64.efi from pbatard/uefi-ntfs"
    wget -O "/tmp/worli/ntfs_aa64.efi" "https://github.com/pbatard/ntfs-3g/releases/latest/download/ntfs_aa64.efi" || error "Failed to download ntfs_aa64.efi from pbatard/ntfs-3g"
    
    wget -O "/tmp/worli/worlipe.cmd" "https://raw.githubusercontent.com/buddyjojo/worli/worli2.0/files/worlipe.cmd" || error "Failed to download worlipe.cmd"
    wget -O "/tmp/worli/batchexec.exe" "https://raw.githubusercontent.com/buddyjojo/worli/worli2.0/files/batchexe.exe" || error "Failed to download batchexec.exe"
    wget -O "/tmp/worli/BCD" "https://raw.githubusercontent.com/buddyjojo/worli/worli2.0/files/BCD" || error "Failed to download the BCD"
    
    export efi="/tmp/worli/UEFI_Firmware.zip"
    export driv="/tmp/worli/Windows_ARM64_Drivers.zip"
    
    export uefntf="/tmp/worli/bootaa64.efi"
    export uefntfd="/tmp/worli/ntfs_aa64.efi"
    
    
    
    #---Change this to the location of `worlipe-no-re.cmd` if you did not want WinRE (see GitHub description)---#
    export pei="/tmp/worli/worlipe.cmd"
    #-----------------------------------------------------------------------------------------------------------#
    
    
    
    export bexec="/tmp/worli/batchexec.exe"
    export bcd="/tmp/worli/BCD"
    
    if [[ $PI == *"3"* ]]; then
        wget -O "/tmp/worli/gptpatch.img" "https://github.com/buddyjojo/worli/raw/worli2.0/files/gptpatch.img" || error "Failed to download gptpatch.img"
        export gptpatch="/tmp/worli/gptpatch.img"
    else
        debug "Installing to Pi 4, no need for gptpatch"
    fi
    
    export auto="1"
    ;;

    [1])

    zenity --title "worli" --info --ok-label="Next" --text "Download the UEFI package (not the source code):\n\n for Pi 4 and newer: <a href='https://github.com/pftf/RPi4/releases'>https://github.com/pftf/RPi4/releases</a>\n\n for Pi 2, 3, CM3: <a href='https://github.com/pftf/RPi3/releases'>https://github.com/pftf/RPi3/releases</a>\n\n Then, rename the ZIP file to 'UEFI_Firmware.zip'"

    efi=$(zenity --title "worli" --entry --text "What's the path to 'UEFI_Firmware.zip'?\n\n E.g. '~/UEFI_Firmware.zip'")
    
    zenity --title "worli" --info --ok-label="Next" --text "Download the driver package from\n<a href='https://github.com/worproject/RPi-Windows-Drivers/releases'>https://github.com/worproject/RPi-Windows-Drivers/releases</a>\n\nget the ZIP archive with the RPi prefix followed by your board version\n\n and rename the ZIP file to Windows_ARM64_Drivers.zip"
    
    driv=$(zenity --title "worli" --entry --text "What's the path to 'Windows_ARM64_Drivers.zip'?\n\n E.g. '~/Windows_ARM64_Drivers.zip'")
    
    zenity --title "worli" --info --ok-label="Next" --text "Download uefi-ntfs from\n<a href='https://github.com/pbatard/uefi-ntfs/releases'>https://github.com/pbatard/uefi-ntfs/releases</a>\n\nget the 'bootaa64.efi' file"
    
    uefntf=$(zenity --title "worli" --entry --text "What's the path to 'bootaa64.efi'?\n\n E.g. '~/bootaa64.efi'")
    
    zenity --title "worli" --info --ok-label="Next" --text "Download ntfs-3g from\n<a href='https://github.com/pbatard/ntfs-3g/releases'>https://github.com/pbatard/ntfs-3g/releases</a>\n\nget the 'ntfs_aa64.efi' file"
    
    uefntfd=$(zenity --title "worli" --entry --text "What's the path to 'ntfs_aa64.efi'?\n\n E.g. '~/ntfs_aa64.efi'")
    
    zenity --title "worli" --info --ok-label="Next" --text "Download/compile batchexec.exe, worlipe.cmd and 'bcd' (and gptpatch.img if installing to pi3) from\n\n<a href='https://github.com/buddyjojo/worli/tree/master/files'>https://github.com/buddyjojo/worli/tree/master/files</a>"
    
    pei=$(zenity --title "worli" --entry --text "What's the path to 'worlipe.cmd'?\n\n E.g. '~/worlipe.cmd'")
    
    bexec=$(zenity --title "worli" --entry --text "What's the path to 'batchexec.exe'?\n\n E.g. '~/batchexec.exe'")
    
    bcd=$(zenity --title "worli" --entry --text "What's the path to 'bcd'?\n\n E.g. '~/bcd'")
    
    if [[ $PI == *"3"* ]]; then
        gptpatch=$(zenity --title "worli" --entry --text "What's the path to 'gptpatch.img'?\n\n E.g. '~/gptpatch.img'")
    else
        debug "Installing to Pi 4, no need for gptpatch"
    fi
    
    ;;

    *)

    error "Invalid input"
    ;;
esac


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
if [ -f $uefntf ]; then
    debug "'bootaa64.efi' found"
else
    error "'bootaa64.efi' does not exist."
    exit 1
fi
if [ -f $uefntfd ]; then
    debug "'ntfs_aa64.efi' found"
else
    error "'ntfs_aa64.efi' does not exist."
    exit 1
fi
if [ -f $pei ]; then
    debug "'worlipe.cmd' found"
else
    error "'worlipe.cmd' does not exist."
    exit 1
fi
if [ -f $bexec ]; then
    debug "'batchexec.exe' found"
else
    error "'batchexec.exe' does not exist."
    exit 1
fi
if [ -f $bcd ]; then
    debug "'batchexec.exe' found"
else
    error "'batchexec.exe' does not exist."
    exit 1
fi


if ! command -v wimupdate &> /dev/null
then
    wimtool=" - 'wimtools' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install wimtools'; for Arch, run 'sudo pacman -S wimtools')"
    export requiredep=1
fi


if ! command -v parted &> /dev/null
then
    parted=" - 'parted' package not installed. Install it (For Debian and Ubuntu, run 'sudo apt install parted'; for Arch, run 'sudo pacman -S parted')"
    export requiredep=1
fi

if ! command -v mkfs.ntfs &> /dev/null
then
    exfat=" - 'mkfs.ntfs' command not found. Install NTFS support somehow (such as ntfs-3g and ntfsprogs)"
    export requiredep=1
fi

if ! command -v gawk &> /dev/null
then
    gawk=" - 'gawk' command not found. Install it (For Debian and Ubuntu, run 'sudo apt install gawk'; for Arch, run 'sudo pacman -S gawk')"
    export requiredep=1
fi

if [[ $requiredep == *"1"* ]]; then
    zenity --title "worli" --info --ok-label="Exit" --text "Dependances\n\n$wimtool\n\n$parted\n\n$exfat\n\n$gawk"
    exit 1
else
    debug "All dependances are met!"
fi

dwnopt=$(zenity --question --title="worli" --text "Do you want:\n\n(1) this script to download a esd directly from microsoft (fastest, en_us only)\n(2) generate iso with uupdump (slower, gives language options)\n(3) use your own iso/esd or a previously generated/downloaded one?" --switch --extra-button "1" --extra-button "2" --extra-button "3")


case $dwnopt in

    1)

if ! command -v aria2c &> /dev/null
then
    zenity --title "worli" --info --ok-label="Exit" --text "'aria2c' package not installed. Install it\n\n For Debian and Ubuntu, run 'sudo apt install aria2'\n\n for Arch, run 'sudo pacman -S aria2'"
    exit 1
fi
    
winver=$(zenity --list --title="worli" --text="What windows version do you want?\n\nNote: defaults to 22621.525" --column 'Windows version' "Windows 11, 22621.525" "Windows 11, 22000.318" "Windows 10, 19044.1288" --height=300)

case $winver in

  "Windows 11, 22621.525")
    export esdurl="http://dl.delivery.mp.microsoft.com/filestreamingservice/files/3da94e91-327c-48ce-8bc8-7a2af30fc4bc/22621.525.220925-0207.ni_release_svc_refresh_CLIENTCONSUMER_RET_A64FRE_en-us.esd"
    ;;

  "Windows 11, 22000.318")
    export esdurl="http://dl.delivery.mp.microsoft.com/filestreamingservice/files/78630d4b-9cdc-44ee-9c4a-fd14e8d72936/22000.318.211104-1236.co_release_svc_refresh_CLIENTCONSUMER_RET_A64FRE_en-us.esd"
    ;;

  "Windows 10, 19044.1288")
    export esdurl="http://dl.delivery.mp.microsoft.com/filestreamingservice/files/3da94e91-327c-48ce-8bc8-7a2af30fc4bc/22621.525.220925-0207.ni_release_svc_refresh_CLIENTCONSUMER_RET_A64FRE_en-us.esd"
    ;;

  *)
    exit 1
    ;;
esac

    
tmpuupvar=$(zenity --question --title="worli" --text "Do you want the esd to be deleted when the script finishes?\n\nnote: the esd will be put in the current directory ($PWD)\n\nnote: the /tmp option is not recommended as /tmp can be too small to fit the esd (~3.6GB)\n\nnote: the /tmp option will delete the esd when the script finishes" --extra-button "download esd in /tmp")

case $? in
    [0])
    export esdpth="$(pwd)"
    export delesd=1
    ;;
    [1])
    export esdpth="$(pwd)"
    ;;
    *)
    exit 1
    ;;
esac

if [[ $tmpuupvar == "download esd in /tmp" ]]; then
    mkdir /tmp/worli/tmpesd
    export esdpth=/tmp/worli/tmpesd
    export tmpesd=1
fi

if [[ -f $esdpth/win.esd ]] ; then

zenity --question --title="worli" --text "Previously generated win.esd found in $esdpth/win.esd, would you like to delete it?"

case $? in
    [0])
    rm "$esdpth/win.esd"
    ;;
    [1])
    error "Please remove or rename file $esdpth/win.esd (or use it with option 3)"
    ;;
    *)
    exit 1
    ;;
esac

fi

zenity --title "worli" --info --ok-label="Continue" --text "The aria2c download will now be ran\nIts output will be in the terminal where this script was ran"

esddwn() {
 aria2c -d $esdpth -o "win.esd" $esdurl >&2
}

(

esddwn
if [[ $? -ne 0 ]]; then
    echo "# download failed, trying again. current amount of attempts: $counter"
    sleep 5
    esddwn
    while [ $? -ne 0 ]; do
        counter=$(( counter + 1 ))
        echo "# download failed, trying again. current amount of attempts: $counter"
        sleep 5
        esddwn
    done
else
    zenity --title "worli" --info --ok-label="Continue" --text "The esd download suceeded!"
fi

) |
zenity --progress \
  --title="worli" \
  --text="Downloading esd...." \
  --pulsate \
  --auto-close
  
(( $? != 0 )) && exit 1 
    
export iso="$esdpth/win.esd"

    ;;
    2)

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
    export requiredep=1
fi

if ! command -v mkisofs &> /dev/null && ! command -v genisoimage &> /dev/null
then
    mkisofs=" - 'genisoimage or mkisofs' command not found."
    mkisofsdeb="genisoimage"
    export requiredep=1
fi

if [[ $requiredep == *"1"* ]]; then
    zenity --title "worli" --info --ok-label="Exit" --text "Dependances\n$jq\n$aria2c\n$cabextract\n$chntpw\n$mkisofs\n\ninstall them:\n\nFor Debaian and Ubuntu, run 'sudo apt install $jqp $aria2p $cabextractp $chntpwp $mkisofsdeb'\n\nFor Arch, run 'sudo pacman -S $jqp $aria2p $cabextractp $chntpwp $mkisofsarmc'"
    exit 1
else
    debug "All dependances are met!"
fi
    
zenity --question --title="worli" --text "Do you want to use the latest retail/dev builds or enter your own uupdump.net build id? Press 'No' to use id"

case $? in
    [1])
    updateid=$(zenity --title "worli" --entry --text "What's the uupdump.net uuid?\n\n e.g once you select the build you want the id will be in the url like:\n\nhttps://uupdump.net/selectlang.php?id= '6b1e576c-9854-44b4-9cdd-108d13cf0035'")
    
    foundBuild=$(curl -sk "https://api.uupdump.net/listlangs.php?id=$updateid" | jq -r '.response.updateInfo.title')
    
    if [[ $? -ne 0 ]]; then
        error "Got rate limited or id is incrorrect, please try again"
    else
        debug "Not null thats good"
    fi
    
    ;;
    [0])
    release=$(zenity --list --title="worli" --text="What windows release type do you want?\n\nNote: defaults to Public Release\n\nNOTE: Dev builds will not boot on pi 4 and below" --column 'Release type'  "Latest Public Release build" "Latest Dev Channel build" --height=300)
    
    if [[ $release == "Latest Dev Channel build" ]]; then
        export ring="wif&build=latest"
    else
        export ring="retail&build=19041.1"   
    fi
    
    apiget=$(curl "https://api.uupdump.net/fetchupd.php?arch=arm64&ring=$ring" | jq -r '.response.updateArray[] | select( .updateTitle | contains("Windows")) | {Id: .updateId, Name: .updateTitle} ')
    
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

langjson=$(curl -sk "https://api.uupdump.net/listlangs.php?id=$updateid" | jq -r '.response.langFancyNames')

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
    mkdir /tmp/worli/tmpuup
    uuproot=/tmp/worli/tmpuup
    export tmpuup=1
fi

wget -O "/tmp/worli/UUP.zip" "https://uupdump.net/get.php?id=$updateid&pack=en-us&edition=professional&autodl=2" || error "Failed to download UUP.zip"

export uupzip=1

unzip "/tmp/worli/UUP.zip" -d "$uuproot/uup"

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
    export fulliso=1
else
    error "iso not found."
fi

    ;;

    3)

zenity --title "worli" --info --ok-label="Next" --text "Prerequisites\n\n- Get the windows ISO: <a href='https://worproject.com/guides/getting-windows-images'>https://worproject.com/guides/getting-windows-images</a>\n\n- Rename the ISO file to 'win.iso'\n\n- If you want use use a modified install.wim, rename it to 'install.wim'\n\n<span color=\"red\">DO THE PREREQUISITES BEFORE CONTINUING</span>"

if [[ -f $(find $(pwd)/uup/ -name "*ARM64*.ISO") ]] || [[ -f $(find /tmp/worli/tmpuup/uup -name "*ARM64*.ISO") ]] ; then

zenity --question --title="worli" --text "Previously generated iso found, would you like to use that or use another one?"

case $? in
    [0])
    iso=$(find $(pwd)/uup/ -name "*ARM64*.ISO") || iso=$(find /tmp/worli/tmpuup/uup -name "*ARM64*.ISO")
    export fulliso=1
    ;;
    [1])
    iso=$(zenity --title "worli" --entry --text "What's the path to the 'win.iso' or 'install.wim'?\n\n E.g. '~/win.iso'")
    ;;
    *)
    exit 1
    ;;
esac

elif [[ -f $(pwd)/win.esd ]] || [[ -f /tmp/worli/tmpesd/win.esd ]] ; then

zenity --question --title="worli" --text "Previously downloaded esd found, would you like to use that or use another one?"

case $? in
    [0])
    
    if [ -f /tmp/worli/tmpesd/win.esd ]; then
        iso="/tmp/worli/tmpesd/win.esd"
    else
        iso="$(pwd)/win.esd"
    fi

    ;;
    [1])
    iso=$(zenity --title "worli" --entry --text "What's the path to the 'win.iso' or 'install.wim' or 'win.esd'?\n\n E.g. '~/win.iso'")
    ;;
    *)
    exit 1
    ;;
esac

else

iso=$(zenity --title "worli" --entry --text "What's the path to the 'win.iso' or 'install.wim' or 'win.esd'?\n\n E.g. '~/win.iso'")

fi

    ;;

    *)

    error "Invalid input"
    exit 1
    ;;
esac


if [ -f $iso ]; then
    debug "'win.iso/install.wim/win.esd' found"
else
    error "'win.iso/install.wim/win.esd' does not exist. iso veriable was set to '$iso'"
fi

if [[ $iso =~ \.[Ww][Ii][Mm]$ ]] || [[ $iso =~ \.[Ee][Ss][Dd]$ ]]; then
    export fulliso=0
    debug "full iso detected = $fulliso, $iso"
else
    export fulliso=1
    debug "full iso detected = $fulliso, $iso"
fi

disko () {

export fdisk=$(parted -l | grep "Disk /dev*" | grep -v loop | sort | gawk '{ printf "FALSE""\0"$0"\0" }' | xargs -0 zenity --list --title="worli" --text="What /dev/* is your drive?" --radiolist --multiple --column ' ' --column 'Disks' --extra-button "Rescan")

(( $? != 0 )) && exit 1

sdisk=${fdisk#Disk /dev/*}
disk="${sdisk%%:*}"

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

echo "10"

debug "Creating partitions..."

umount /dev/$disk*

parted -s /dev/$disk mklabel gpt
parted -s /dev/$disk mkpart primary 1MB 128MB
parted -s /dev/$disk set 1 esp on
parted -s /dev/$disk set 1 boot on

echo "20"

parted -s -- /dev/$disk mkpart primary 145MB -0
parted -s /dev/$disk set 2 msftdata on

sync
mkfs.fat -F 32 /dev/$nisk'1' || error "Failed to format disk"
sync

mkfs.ntfs -f /dev/$nisk'2' || error "Failed to format disk"
sync

echo "30"

echo "# Copying Windows files to the drive\n\nthis will take a while\n\nprogress shown in terminal..."
debug "Copying Windows files to the drive."

if [[ $fulliso == *"1"* ]]; then   

    mkdir -p /tmp/worli/isomount
    chmod 777 /tmp/worli/isomount

    mount $iso /tmp/worli/isomount
    
    wimapply --check /tmp/worli/isomount/sources/install.wim 1 /dev/$nisk'2' >&2
    
    umount /tmp/worli/isomount
    
    rm -rf /tmp/worli/isomount
    
else
    wimapply --check $iso 1 /dev/$nisk'2' >&2
fi

echo "40"

echo "# Mounting partitions..."

mkdir -p /tmp/worli/bootpart /tmp/worli/winpart

mount /dev/$nisk'1' /tmp/worli/bootpart
mount /dev/$nisk'2' /tmp/worli/winpart

echo "50"

echo "# Copying boot files..."

mkdir -p /tmp/worli/bootpart/EFI/Boot/
mkdir -p /tmp/worli/bootpart/EFI/Rufus/

debug "${uefntf}, ${uefntfd}"

cp ${uefntf} /tmp/worli/bootpart/EFI/Boot/
cp ${uefntfd} /tmp/worli/bootpart/EFI/Rufus/

mkdir -p /tmp/worli/winpart/EFI/Boot/
mkdir -p /tmp/worli/winpart/EFI/Microsoft/Boot/Resources

cp /tmp/worli/winpart/Windows/Boot/EFI/bootmgfw.efi /tmp/worli/winpart/EFI/Boot/bootaa64.efi 
cp ${bcd} /tmp/worli/winpart/EFI/Microsoft/Boot/BCD
cp /tmp/worli/winpart/Windows/Boot/EFI/winsipolicy.p7b /tmp/worli/winpart/EFI/Microsoft/Boot/winsipolicy.p7b
cp /tmp/worli/winpart/Windows/Boot/Resources/bootres.dll /tmp/worli/winpart/EFI/Microsoft/Boot/Resources/bootres.dll
cp -r /tmp/worli/winpart/Windows/Boot/EFI/CIPolicies /tmp/worli/winpart/EFI/Microsoft/Boot/
cp -r /tmp/worli/winpart/Windows/Boot/Fonts /tmp/worli/winpart/EFI/Microsoft/Boot/

wimupdate /tmp/worli/winpart/Windows/System32/Recovery/winre.wim 1 --command="add ${pei} /worlipe.cmd"

wimupdate /tmp/worli/winpart/Windows/System32/Recovery/winre.wim 1 --command="rename /sources/recovery/RecEnv.exe /sources/recovery/RecEnv.exe.bak"

wimupdate /tmp/worli/winpart/Windows/System32/Recovery/winre.wim 1 --command="add ${bexec} /sources/recovery/RecEnv.exe"

echo "60"
echo "# Copying the drivers to the drive..."
debug "Copying the drivers to the drive."

unzip $driv -d /tmp/worli/driverpackage
wimupdate /tmp/worli/winpart/Windows/System32/Recovery/winre.wim 1 --command="add /tmp/worli/driverpackage /drivers"

echo "70"
echo "# Copying the UEFI boot files to the drive..."
debug "Copying the UEFI boot files to the drive."

unzip $efi -d /tmp/worli/uefipackage
sudo cp /tmp/worli/uefipackage/* /tmp/worli/bootpart

if [[ $PI == *"3"* ]]; then
    echo "# Installing to Pi 3 and below, applying gptpatch..."
    dd if="$gptpatch" of=/dev/$disk conv=fsync
else
    debug "Installing to Pi 4, no need to apply gptpatch"
fi

echo "80"
echo "# Unmounting drive\n\nthis may also take a while..."
debug "Unmounting drive."

sync

umount /dev/$disk*

echo "90"
echo "# Cleaning up..."

rm -rf /tmp/worli/

if [[ $deluup == *"1"* ]]; then
    rm -rf $uuproot/uup
else
    debug "uups set to not be deleted"
fi

if [[ $delesd == *"1"* ]]; then
    rm -rf $esdpth
else
    debug "esd set to not be deleted"
fi

echo "100"
echo "# Press OK to continue"

) |
zenity --progress \
  --title="worli" \
  --text="Creating partitions..." \
  --percentage=0

(( $? != 0 )) && exit 1

zenity --title "worli" --info --ok-label="Done!" --text "Booting\n\n1. Connect the drive and other peripherals to your Raspberry Pi then boot it up.\n\n2. Assuming everything went right in the previous steps, the pi will boot up to a PE enviroment were it will do some configuring and then reboot to hopefully a full windows install.\n\nAll done :)\nThanks for using WoRli2.0"

debug "It has finnished"

exit 0
