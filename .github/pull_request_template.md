## What this changes

<!-- One or two sentences. Link the issue if there is one. -->

## How it was tested

- [ ] `python3 -m py_compile dualsense-bt2usb` and `bash -n dualsense-bt2usb-run install.sh` pass
- [ ] Tested with a DualSense over Bluetooth: `dualsense-bt2usb check` is clean and the virtual pad registers
- [ ] Tested in a game (name, Wine/Proton version):

## Checklist

- [ ] No new dependencies, network access or telemetry
- [ ] Feature report changes (`BT_SAFE_FEATURES`, `ACK_ONLY_SET_FEATURES`) include the game and bridge log that justify them
- [ ] README updated if behavior, options or the tested games list changed
