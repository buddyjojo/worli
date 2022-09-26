# worli
<img src="https://user-images.githubusercontent.com/76966404/138036784-79d9e23f-7eae-414c-904e-9c8883382bed.png" alt="alt text" title="logo made by fengzi" width="128" height="128">

### Simple WoR on Linux Installer.

Built for simplicity and compatibility.

Unlike Botspot's wor-flasher that only works on Debian, is a bit bloated and uses an older slower method of deployment, this script is meant to be more simpler (and quicker!) and work on any distro with bash (or potentially bash compatible, e.g. `zsh`), `zenity`, `wimlib`, `parted`, `dosfstools` (`mkfs.fat`), and NTFS support (`mkfs.ntfs` command)

**NOTE**: This version can't and may never work on Macos due to the fact ntfs is required. please use the [old branch](https://github.com/buddyjojo/worli/tree/main) instead.

Also you can use your own ISO and even a modified `install.wim`

## INSTRUCTIONS:

1. Go to "Releases" and download the latest ["worli2.0.sh"](https://github.com/buddyjojo/worli/releases/latest/download/worli2.0.sh).

2. Put the script into an empty folder **WITH NO SPACES IN ITS NAME**!

3. Open a terminal in that folder and run `sudo bash worli2.0.sh`, or `chmod +x worli2.0.sh` and then `sudo ./worli2.0.sh` (remove `sudo` if in a root shell)

4. Follow the instructions built-in with the script

##

## Tip

If you do not care about the windows recovery enviroment and want a quicker deployment (it takes a bit to unpack and repack the wim), grab the `worlipe-no-re.cmd` from the files directory in this repo and edit line 83 of `worli2.0.sh` (pei="/tmp/worli/worlipe.cmd") to the path of the previously downloaded cmd script.
This is not necessary if using the manual download option, just specify the other script when prompted (duh). 

##### If you have any problems or suggestions, please create a GitHub issue or tell me in our Discard severe.

**Alsor chuck our out [Discard severe](https://discord.gg/26CMEjQ47g)!**
