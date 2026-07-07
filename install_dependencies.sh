#!/bin/bash
echo "======================================"
echo "Phone-Link Setup Script"
echo "======================================"
echo ""

install_core="n"
install_scrcpy="n"
install_sshfs="n"
setup_droidcam="n"

read -p "1. Install Core Dependencies? (kdeconnect, qdbus, python-dbus, jq) [y/N]: " install_core
if [[ "$install_core" != "y" && "$install_core" != "Y" ]]; then
    echo "   -> Skipped. Note: The extension will NOT be able to connect to your phone or fetch battery/notifications!"
fi

read -p "2. Install Screen Mirroring? (scrcpy, adb) [y/N]: " install_scrcpy
if [[ "$install_scrcpy" != "y" && "$install_scrcpy" != "Y" ]]; then
    echo "   -> Skipped. Note: You will not be able to mirror your phone screen."
fi

read -p "3. Install File Browsing? (sshfs) [y/N]: " install_sshfs
if [[ "$install_sshfs" != "y" && "$install_sshfs" != "Y" ]]; then
    echo "   -> Skipped. Note: You will not be able to mount and browse phone files."
fi

read -p "4. Configure DroidCam Kernel Modules (v4l2loopback, snd_aloop) on startup? [y/N]: " setup_droidcam
if [[ "$setup_droidcam" != "y" && "$setup_droidcam" != "Y" ]]; then
    echo "   -> Skipped. Note: You will not be able to use your phone as a webcam or mic (unless manually loaded)."
fi

echo ""
echo "======================================"
echo "Installing selected components..."
echo "======================================"

# Determine package manager
PKG_MANAGER=""
if command -v pacman >/dev/null; then
    PKG_MANAGER="pacman"
elif command -v apt-get >/dev/null; then
    PKG_MANAGER="apt"
    sudo apt-get update
elif command -v dnf >/dev/null; then
    PKG_MANAGER="dnf"
else
    echo "Unsupported package manager. Please install packages manually."
    exit 1
fi

packages_to_install=""

# 1. Core
if [[ "$install_core" == "y" || "$install_core" == "Y" ]]; then
    if [ "$PKG_MANAGER" = "pacman" ]; then
        packages_to_install="$packages_to_install kdeconnect jq python-dbus python-gobject qt6-tools"
    elif [ "$PKG_MANAGER" = "apt" ]; then
        packages_to_install="$packages_to_install kdeconnect jq python3-dbus python3-gi qt6-tools"
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        packages_to_install="$packages_to_install kdeconnect jq python3-dbus python3-gobject qt6-qttools"
    fi
fi

# 2. Scrcpy
if [[ "$install_scrcpy" == "y" || "$install_scrcpy" == "Y" ]]; then
    if [ "$PKG_MANAGER" = "pacman" ] || [ "$PKG_MANAGER" = "dnf" ]; then
        packages_to_install="$packages_to_install scrcpy android-tools"
    elif [ "$PKG_MANAGER" = "apt" ]; then
        packages_to_install="$packages_to_install scrcpy adb"
    fi
fi

# 3. SSHFS
if [[ "$install_sshfs" == "y" || "$install_sshfs" == "Y" ]]; then
    packages_to_install="$packages_to_install sshfs"
fi

# Install packages
if [ -n "$packages_to_install" ]; then
    echo "Installing packages: $packages_to_install"
    if [ "$PKG_MANAGER" = "pacman" ]; then
        sudo pacman -S --needed $packages_to_install
    elif [ "$PKG_MANAGER" = "apt" ]; then
        sudo apt-get install -y $packages_to_install
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        sudo dnf install -y $packages_to_install
    fi
else
    echo "No packages selected for installation."
fi

# 4. DroidCam Modules
if [[ "$setup_droidcam" == "y" || "$setup_droidcam" == "Y" ]]; then
    echo ""
    echo "Configuring DroidCam kernel modules to load on startup..."
    if [ -d "/etc/modules-load.d" ]; then
        echo -e "snd_aloop\nv4l2loopback" | sudo tee /etc/modules-load.d/droidcam.conf > /dev/null
        echo "Added snd_aloop and v4l2loopback to /etc/modules-load.d/droidcam.conf"
        sudo modprobe snd_aloop 2>/dev/null || true
        sudo modprobe v4l2loopback 2>/dev/null || true
    else
        echo "Warning: /etc/modules-load.d not found. Could not configure auto-load."
    fi
fi

echo ""
echo "Done! Please reload Quickshell using the keybind (Ctrl + Super + R) to apply changes, then you may exit this window."
