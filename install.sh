#!/usr/bin/env bash
# Install dualsense-bt2usb for the current user.
#
#   ./install.sh               install into ~/.local (bin + share)
#   ./install.sh --udev        also install the udev rules (asks for sudo)
#   ./install.sh --uninstall   remove the user install (udev rules are left in place)
#   PREFIX=/opt/x ./install.sh install somewhere else
#
# Copyright (c) 2026 dualsense-bt2usb contributors. Licensed under the MIT License (see LICENSE).
set -eu

SRC=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PREFIX=${PREFIX:-$HOME/.local}
BIN=$PREFIX/bin
SHARE=$PREFIX/share/dualsense-bt2usb
UDEV_DIR=/etc/udev/rules.d
UDEV_RULES=(71-uhid-uaccess.rules 71-dualsense-hidraw.rules)

install_udev=0
case ${1:-} in
    '') ;;
    --udev) install_udev=1 ;;
    --uninstall)
        rm -f "$BIN/dualsense-bt2usb" "$BIN/dualsense-bt2usb-run"
        rm -rf "$SHARE"
        echo "Removed dualsense-bt2usb from $PREFIX."
        echo "udev rules (if installed) remain in $UDEV_DIR: ${UDEV_RULES[*]}"
        exit 0
        ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1 (use --udev, --uninstall or --help)" >&2; exit 2 ;;
esac

command -v python3 >/dev/null || { echo 'python3 is required' >&2; exit 1; }

install -Dm755 "$SRC/dualsense-bt2usb" "$BIN/dualsense-bt2usb"
install -Dm755 "$SRC/dualsense-bt2usb-run" "$BIN/dualsense-bt2usb-run"
install -d "$SHARE/descriptors"
install -m644 "$SRC"/descriptors/*.bin "$SHARE/descriptors/"
echo "Installed dualsense-bt2usb and dualsense-bt2usb-run to $BIN"

if [[ $install_udev == 1 ]]; then
    for rule in "${UDEV_RULES[@]}"; do
        sudo install -Dm644 "$SRC/udev/$rule" "$UDEV_DIR/$rule"
    done
    sudo udevadm control --reload
    sudo udevadm trigger --action=change /dev/uhid
    sudo udevadm trigger --action=change --subsystem-match=hidraw
    echo "Installed udev rules to $UDEV_DIR"
fi

case ":$PATH:" in
    *":$BIN:"*) ;;
    *) echo "note: $BIN is not in your PATH" ;;
esac
echo 'Run "dualsense-bt2usb check" to verify the setup.'
