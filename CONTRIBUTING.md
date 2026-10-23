# Contributing to dualsense-bt2usb

Thanks for helping! The most valuable contribution right now is **testing the bridge with
more games**, followed by bug reports and focused code changes.

## Report a game

Whether a game works or not, a report helps. Open a
[game report](../../issues/new?template=game-report.yml) and include:

- **Game** name and store (Steam, GOG, etc.).
- **Result:** PlayStation prompts / Xbox prompts / no controller detected.
- **What works:** buttons, light bar, rumble, adaptive triggers, touchpad, motion.
- **Wine/Proton version** (e.g. `GE-Proton11-9`, `Proton 10.0`) and how you launch the game.
- **Distribution and kernel** (`uname -r`).
- **Output of** `dualsense-bt2usb check`.
- **The bridge log.** With the wrapper it is in `$XDG_RUNTIME_DIR/dualsense-bt2usb.log`.
  It lists every feature report the game asked for, which is what we need to support a new game.

> The bridge log does not contain your controller's MAC address, but `dmesg` and Proton
> logs do. Remove MAC addresses (`xx:xx:xx:xx:xx:xx`) before pasting those.

## Report a bug

Open a [bug report](../../issues/new?template=bug-report.yml) with the steps to
reproduce, what you expected, what happened, and the bridge log.

## Change the code

1. Fork the repository and create a branch from `main`.
2. Keep changes small and focused; one fix or feature per pull request.
3. Test with a real DualSense over Bluetooth:
   ```bash
   ./dualsense-bt2usb check
   ./dualsense-bt2usb            # in one terminal
   dmesg | tail                  # the virtual pad should register as "USB HID ... on dualsense-bt2usb"
   ```
   Then run a game through `./dualsense-bt2usb-run` and confirm it still detects the pad.
4. Check syntax before pushing:
   ```bash
   python3 -m py_compile dualsense-bt2usb
   bash -n dualsense-bt2usb-run install.sh
   ```
5. Update `README.md` if behavior, options or the tested games list change.
6. Open a pull request describing what you changed and how you tested it.

### Ground rules for code changes

- **No dependencies.** The bridge uses only the Python standard library, so it is easy to
  audit. It runs with access to `/dev/uhid`, so keep it that way.
- **Feature report changes need evidence.** `BT_SAFE_FEATURES` and `ACK_ONLY_SET_FEATURES`
  protect the controller from requests that stall it over Bluetooth. If you add a report
  ID, say which game needed it and include the bridge log that shows it.
- **No network access**, no telemetry, no downloads at runtime.
- **Document only what is verified.** If a feature was not tested in a game, say so.
- Match the existing style: plain functions and a small `Bridge` class, short comments
  that explain *why*.

## Adding a controller descriptor

To support another model (for example a DualSense Edge, `054C:0DF2`), capture its USB
descriptor with `dualsense-bt2usb capture` while it is connected by cable. Add it to
`descriptors/` as `<vid>-<pid>.bin` in a pull request, and say which firmware version the
controller had.

## License

By contributing, you agree that your contributions are licensed under the
[MIT License](LICENSE) of this project.
