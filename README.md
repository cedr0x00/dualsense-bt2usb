# dualsense-bt2usb

Make a **Bluetooth DualSense** look like a **USB DualSense** on Linux, so Windows games
running under Wine/Proton detect it as a PS5 controller (PlayStation button prompts,
light bar, adaptive triggers) instead of ignoring it or treating it as an Xbox pad.

Some games only accept the DualSense through its USB HID layout. Over Bluetooth they
probe the controller and drop it, or Proton hands them an emulated Xbox 360 pad.
`dualsense-bt2usb` reads the Bluetooth controller and recreates it as a virtual USB
device through the kernel's `uhid` interface, translating reports in both directions.

## Features

- Exposes the Bluetooth DualSense as `USB\VID_054C&PID_0CE6` to Wine/Proton.
- Translates input reports (sticks, buttons, triggers, touchpad, motion) from the
  Bluetooth format (`0x31`, 78 bytes) to the USB format (`0x01`, 64 bytes).
- Translates output reports (light bar, player LEDs, rumble, adaptive triggers) from
  USB (`0x02`) to Bluetooth (`0x31` with sequence number and CRC32).
- Forwards only feature reports that are safe over Bluetooth (calibration, pairing,
  firmware info) and acknowledges or refuses the rest, so the controller never stalls.
- Survives controller power-offs: the virtual pad stays and reattaches when the
  controller reconnects, so the game does not lose it.
- Launch wrapper for Steam, Lutris, Heroic or plain shell scripts.

## Limitations

- **Advanced haptics do not work over Bluetooth.** On PC, DualSense haptics are sent as
  audio to the controller's USB sound card. Over Bluetooth the PS5 uses an undocumented
  protocol that games on PC do not use. Classic rumble works.
- The headset jack and the built-in speaker/microphone are not bridged.
- Only the standard DualSense (`054C:0CE6`) ships with a descriptor. A DualSense Edge
  (`054C:0DF2`) works once you capture its descriptor (see [Other controllers](#other-controllers)).
- While the bridge runs, the desktop sees two controllers (the real Bluetooth one and the
  virtual USB one). The virtual one disappears when the bridge stops.

## Tested with

| Game | Result |
| --- | --- |
| Call of Duty: Modern Warfare 4 (campaign) | Over Bluetooth, detected as a DualSense with PlayStation button prompts. Without the bridge, the game ignores the Bluetooth pad or shows Xbox prompts. |

Test setup:
- Nobara Linux (Fedora 44), kernel 7.2
- GE-Proton11-9, run through `umu-run`
- DualSense (`054C:0CE6`), firmware `0x0110002a`, connected over Bluetooth (BlueZ)

This game also needs `PROTON_SONY_AUTO_XINPUT=0`; the wrapper sets it for you. It confirms
the virtual pad by writing feature report `0x08`, which the bridge acknowledges locally.

If you try it with another game, working or not, please open a
[game report](../../issues/new?template=game-report.yml) so it can be added here.

## Requirements

- Linux with `uhid` and `hid-playstation` (any modern kernel; both are standard modules).
- Python 3.8 or newer (standard library only, no dependencies).
- A DualSense paired over Bluetooth (BlueZ).
- Wine or Proton with hidraw support for Sony controllers (Proton 8+ / GE-Proton).

## Installation

Clone or download this repository, then from its folder:

```bash
./install.sh --udev
```

`install.sh` copies `dualsense-bt2usb` and `dualsense-bt2usb-run` to `~/.local/bin` and the
descriptors to `~/.local/share/dualsense-bt2usb/`. `--udev` also installs the udev rules
(it asks for your sudo password). Set `PREFIX` to install somewhere else, and run
`./install.sh --uninstall` to remove it.

### udev rules

The bridge needs, for the logged-in user:

| Rule | Purpose |
| --- | --- |
| `udev/71-uhid-uaccess.rules` | Read/write access to `/dev/uhid`, to create the virtual pad. |
| `udev/71-dualsense-hidraw.rules` | Access to the DualSense hidraw nodes (real and virtual). Skip it if your distribution already ships `game-devices-udev` or `steam-devices`. |

To install them by hand:

```bash
sudo install -m644 udev/71-uhid-uaccess.rules udev/71-dualsense-hidraw.rules /etc/udev/rules.d/
sudo udevadm control --reload
sudo udevadm trigger --action=change /dev/uhid
```

> **Security note:** access to `/dev/uhid` lets programs running in your session create
> virtual input devices (keyboards, mice, gamepads). Steam's own udev rules grant the same
> for Steam Input. It is reasonable on a single-user desktop; skip it on shared machines.

### Verify

```bash
dualsense-bt2usb check
```

```
/dev/uhid writable:     yes
Bluetooth DualSense:    /dev/hidraw5 (054c:0ce6), accessible
USB descriptor:         /home/you/.local/share/dualsense-bt2usb/descriptors/054c-0ce6.bin
USB DualSense:          not connected
```

## Usage

### With a launch wrapper (recommended)

`dualsense-bt2usb-run` starts the bridge when a DualSense is connected over Bluetooth,
runs your command, and stops the bridge when the command exits. If no Bluetooth
DualSense is connected, it just runs the command.

**Steam** — game Properties → Launch Options:

```
dualsense-bt2usb-run %command%
```

**Lutris / Heroic / Bottles** — set `dualsense-bt2usb-run` as the command prefix / wrapper.

**Shell script or launcher:**

```bash
dualsense-bt2usb-run umu-run ./Game.exe
```

The wrapper also sets these environment variables unless you set them yourself:

| Variable | Value | Why |
| --- | --- | --- |
| `PROTON_SONY_AUTO_XINPUT` | `0` | Some Proton builds report Sony pads to the game as an Xbox 360 pad through XInput; the game then picks that one. |
| `PROTON_NO_STEAMINPUT` | `1` | Keeps Steam Input from replacing the controller with a virtual Xbox pad. |

Wrapper options (environment variables):

| Variable | Default | Effect |
| --- | --- | --- |
| `DS_BT2USB_LOG` | `$XDG_RUNTIME_DIR/dualsense-bt2usb.log` | Bridge log file. |
| `DS_BT2USB_DISABLE` | `0` | Set to `1` to run the command without the bridge. |

### Running the bridge directly

```bash
dualsense-bt2usb            # same as: dualsense-bt2usb run
```

Leave it running while you play and stop it with Ctrl+C. Use `-d FILE` to pick a specific
USB descriptor.

> If you use Steam Input, disable it for the game (game Properties → Controller →
> *Disable Steam Input*). Otherwise Steam replaces the controller with its own virtual
> Xbox pad.

## Other controllers

The bridge needs the controller's real **USB** report descriptor. To capture it (for
example for a DualSense Edge, or if a firmware update changes it), connect the
controller with a USB cable once and run:

```bash
dualsense-bt2usb capture
```

It is saved to `~/.local/share/dualsense-bt2usb/descriptors/<vid>-<pid>.bin` and used
automatically from then on.

## How it works

```
DualSense ──Bluetooth──▶ BlueZ ──▶ hidraw (bus 0x05, report 0x31)
                                          │
                                   dualsense-bt2usb
                                          │  input   0x31 → 0x01
                                          │  output  0x02 → 0x31 + CRC32
                                          │  feature allowlisted / acknowledged
                                          ▼
                          /dev/uhid  ──▶ virtual hidraw (bus 0x03, USB descriptor)
                                          │
                                 Wine/Proton winebus (hidraw)
                                          ▼
                              Game sees USB\VID_054C&PID_0CE6
```

- **Input:** the Bluetooth `0x31` report carries the same 63-byte payload as the USB
  `0x01` report, shifted by one byte (Bluetooth adds a sequence/tag byte and a CRC).
- **Output:** the USB `0x02` report's 47-byte common block is wrapped into a 78-byte
  Bluetooth `0x31` report with a sequence number, the `0x10` tag and a CRC32 seeded with
  `0xA2`.
- **Feature reports:**
  - `0x05` (calibration), `0x09` (pairing info), `0x20` and `0x22` (firmware/hardware info)
    are forwarded to the controller.
  - `0x09` has its MAC address marked as locally administered, because `hid-playstation`
    refuses a second pad with the same MAC.
  - Writes to `0x08` are acknowledged without touching the controller, because some games
    retry forever until that write succeeds.
  - Everything else is refused. This includes the USB audio/haptics test commands `0x80`/`0x81`
    that Wine sends to USB pads; forwarded over Bluetooth, they stall and disconnect the controller.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `permission denied: /dev/uhid` | Install `udev/71-uhid-uaccess.rules`, then log out and back in, or re-trigger udev. |
| `no Bluetooth DualSense found` | Pair and connect the controller first; `dualsense-bt2usb check` lists what it sees. |
| `no USB descriptor for 054c:xxxx` | Connect the controller by USB once and run `dualsense-bt2usb capture`. |
| Game still shows Xbox prompts | Disable Steam Input for the game and make sure `PROTON_SONY_AUTO_XINPUT=0` reaches the game. |
| Game shows no controller | Check the bridge log. A feature report repeating with `EIO` means the game needs it; open an issue with the log. |
| Controller turned off mid-game | Turn it back on; the bridge reattaches automatically. |
| `Duplicate device found for MAC address` in `dmesg` | You are running an old version without the MAC tweak, or two bridges at once. |

The bridge logs every distinct feature request once, so its log shows what a game asks for.

## Contributing

Game reports, bug reports and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 dualsense-bt2usb contributors
