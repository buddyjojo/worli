# worli

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
[^2]: Any distro with support for bash or potentially bash compatible shells (e.g. `zsh`), `wimlib`, `parted`, `dosfstools` (`mkfs.fat`), and `exfatprogs` (`mkfs.exfat`)
[^3]: worli 2.0+ and worli-gui requires dependency `zenity`
[^4]: Only the `install.wim` was needed for custom image using worli version 2.0 and above. You can use a full ISO and with a modified `install.wim` with all other alternatives.

## INSTRUCTIONS

## NOTICE: You are looking at the legacy version of worli. For faster installation (Linux only), please go check out ["worli2.0"](https://github.com/buddyjojo/worli/tree/worli2.0)

1. Go to ["Releases"](https://github.com/buddyjojo/worli/releases) and download the latest legacy (in this case, v1.4) ["worli.sh"](https://github.com/buddyjojo/worli/releases/download/1.4/worli.sh) or ["worli-gui.sh"](https://github.com/buddyjojo/worli/releases/download/1.4/worli-gui.sh) of your choice.

2. Put the script into an empty folder **WITH NO SPACES IN ITS NAME**!

3. Open a terminal in that folder and run `sudo bash worli.sh`, or `chmod +x worli.sh` and then `sudo ./worli.sh` (remove `sudo` if in a root shell)

4. Follow the instructions built-in with the script

##

##### If you have any problems or suggestions, please create a GitHub issue or tell me in our Discard severe.

**Alsor chuck our out [Discard severe](https://discord.gg/26CMEjQ47g)!**
