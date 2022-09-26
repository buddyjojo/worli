# worli

## NOTE: there's a new and quicker version for linux ["HERE"](https://github.com/buddyjojo/worli/tree/worli2.0)

<img src="https://user-images.githubusercontent.com/76966404/138036784-79d9e23f-7eae-414c-904e-9c8883382bed.png" alt="alt text" title="logo made by fengzi" width="128" height="128">

### Simple WoR on Linux Installer.

Built for simplicity and compatibility.

Unlike Botspot's wor-flasher that only works on Debian and is a bit bloated, this script is meant to be more simpler and work on any distro with bash (or potentially bash compatible, e.g. `zsh`), `wimlib`, `parted`, `dosfstools` (`mkfs.fat`), and `exfatprogs` (`mkfs.exfat`)

(worli-gui requires `zenity`).

This script now supports macOS too! (experimental)

There's now a Zenity based GUI too!

worli-gui now has uupdump ISO creation support (also a bit experimental)

Also you can use your own ISO and even a modified `install.wim`*

*\* A modified `install.wim` to still requires an ISO file for the `boot.wim` and boot files*

## INSTRUCTIONS:

1. Go to "Releases" and download the latest ["worli.sh"](https://github.com/buddyjojo/worli/releases/latest/download/worli.sh) or ["worli-gui.sh"](https://github.com/buddyjojo/worli/releases/latest/download/worli-gui.sh) of your choice.

  > HELP WANTED: If you have a bit of spare time it would be nice if you try the script in the repo's code section and see if it works, if it does or any problem araises please create an issue or contact me on the Discard severe.

2. Put the script into an empty folder **WITH NO SPACES IN ITS NAME**!

3. Open a terminal in that folder and run `sudo bash worli.sh`, or `chmod +x worli.sh` and then `sudo ./worli.sh` (remove `sudo` if in a root shell)

4. Follow the instructions built-in with the script

##

##### If you have any problems or suggestions, please create a GitHub issue or tell me in our Discard severe.

**Alsor chuck our out [Discard severe](https://discord.gg/26CMEjQ47g)!**
