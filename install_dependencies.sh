#!/bin/bash
echo "Installing dependencies for Phone-Link..."

if command -v pacman >/dev/null; then
    echo "Arch Linux detected. Installing via pacman..."
    sudo pacman -S --needed kdeconnect sshfs scrcpy android-tools jq python-dbus python-gobject qt6-tools
    echo "----------------------------------------"
    echo "NOTE: DroidCam requires the CLI tool and v4l2loopback module."
    echo "Please install it from the AUR if you plan to use the Webcam feature:"
    echo "e.g., yay -S droidcam"
    echo "----------------------------------------"
elif command -v apt-get >/dev/null; then
    echo "Debian/Ubuntu detected. Installing via apt-get..."
    sudo apt-get update
    sudo apt-get install -y kdeconnect sshfs scrcpy adb jq python3-dbus python3-gi qt6-tools
    echo "----------------------------------------"
    echo "NOTE: DroidCam requires the CLI tool and v4l2loopback module."
    echo "Please install droidcam manually from https://github.com/dev47apps/droidcam"
    echo "----------------------------------------"
elif command -v dnf >/dev/null; then
    echo "Fedora detected. Installing via dnf..."
    sudo dnf install -y kdeconnect sshfs scrcpy android-tools jq python3-dbus python3-gobject qt6-qttools
    echo "----------------------------------------"
    echo "NOTE: DroidCam requires the CLI tool and v4l2loopback module."
    echo "----------------------------------------"
else
    echo "Unsupported package manager."
    echo "Please manually install the following packages:"
    echo "- kdeconnect"
    echo "- sshfs"
    echo "- scrcpy"
    echo "- adb (android-tools)"
    echo "- jq"
    echo "- python-dbus"
    echo "- python-gobject"
    echo "- qdbus (qt5-tools or qt6-tools)"
    echo "- droidcam-cli (for webcam)"
fi

echo "Done!"
