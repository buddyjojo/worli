# worli2.0

<img src="https://user-images.githubusercontent.com/76966404/138036784-79d9e23f-7eae-414c-904e-9c8883382bed.png" alt="alt text" title="logo made by fengzi" width="128" height="128">

### Simple WoR on Linux Installer. 

Built for simplicity and compatibility.

## INFORMATION

#### Feature comparison:

| Feature | worli (2.x) | worli (1.4) | worli-gui (1.4) | wor-flasher |
| --- | --- | --- | --- | --- |
| Flashes WoR | ✅ | ✅ | ✅ | ✅ |
| Installation Speed | Fast[^1] | Normal | Normal | Normal |
| Distro Support | Any[^2] | Any[^2] | Any[^2] | Debian-based |
| macOS Support | ❌ | ✅ | ✅ | ❌ |
| Graphical Interface | ✅[^3] | ❌ | ✅[^3] | ✅ |
| UUP Dump Integration | ✅ | ❌ | ✅ | ✅ |
| Custom WIM Support[^4] | ✅ | ❌ | ❌ | ❌ |

[^1]: Performance gain depends on the hardware setup (largely storage device)
[^2]: Any distro with support for bash or potentially bash compatible shells (e.g. `zsh`), `wimlib`, `parted`, `dosfstools` (`mkfs.fat`), `exfatprogs` (`mkfs.exfat`), and for worli 2.0+, NTFS support (NTFS read and write support and `mkfs.ntfs` command)
[^3]: worli 2.0+ and worli-gui requires dependency `zenity`
[^4]: Only the `install.wim` was needed for custom image using worli version 2.0 and above. You can use a full ISO and with a modified `install.wim` with all other alternatives.

**NOTE: This version doesn't currently and may never work on macOS due to the fact NTFS support is required. If this is necessary, please use the [legacy version](https://github.com/buddyjojo/worli/tree/main) instead.**

#### Full dependency list:

Required dependencies: `zenity`, `wimupdate` and `wimapply` ([wimlib](https://wimlib.net/)), `parted`, `mk.ntfs` ([ntfs-3g/ntfsprogs](https://github.com/tuxera/ntfs-3g)), `zip`, `gawk`.

Required dependencies for auto file downloads: `wget`, `jq`.

Required dependencies for direct ESD download: `aria2c`

Required dependencies for auto ISO generation: `jq`, `aria2c`, `cabextract`, `chntpw`, `mkisofs` or `genisoimage`.

## INSTRUCTIONS

1. Go to "Releases" and download the latest ["worli2.0.sh"](https://github.com/buddyjojo/worli/releases/latest/download/worli2.0.sh).

2. Put the script into an empty folder **WITH NO SPACES IN ITS NAME**!

3. Open a terminal in that folder and run `sudo bash worli2.0.sh`, or `chmod +x worli2.0.sh` and then `sudo ./worli2.0.sh` (remove `sudo` if in a root shell)

4. Follow the on-screen instructions provided by the script

#### A tip:

If you wish to not have the Windows Recovery Environment and want a quicker deployment (since it takes a bit to unpack and repack the WIM file), grab the [`worlipe-no-re.cmd`](https://raw.githubusercontent.com/buddyjojo/worli/worli2.0/files/worlipe-no-re.cmd) from the files directory in this repo and edit the line around ~85 (very noticeable) of `worli2.0.sh` (pei="/tmp/worli/worlipe.cmd") to the path of the previously downloaded CMD script.
This is not necessary if you're using the manual download option, you just need to specify the other script when prompted in that case.

##

##### If you have any problems or suggestions, please create a GitHub issue or tell me in our Discard severe.

**Alsor chuck our out [Discard severe](https://discord.gg/26CMEjQ47g)!**
