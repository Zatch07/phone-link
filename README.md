# Phone-Link

A powerful Quickshell extension that integrates your phone tightly with your Linux desktop.

## Installation & Setup

1. **Install Dependencies:**
   This extension requires several system packages to work, such as KDE Connect for communication, `sshfs` for file browsing, `scrcpy` for screen mirroring, and `droidcam-cli` for webcam support.
   
   Run the included installation script to easily install everything on supported distributions:
   ```bash
   ./install_dependencies.sh
   ```

2. **Pairing Your Phone:**
   Make sure the **KDE Connect** app is installed on your Android/iOS device. 
   Open the extension on your desktop, select your phone, and click **Pair**. Accept the pairing request on your phone.

3. **Reload Quickshell:**
   Once dependencies are installed, you may need to reload quickshell:
   ```bash
   killall quickshell
   ```

## How to Change Settings (e.g. Webcam Resolution)

Most settings can be changed interactively directly inside the extension's UI.

For example, if you want a **higher webcam resolution** (e.g. 1080p instead of 720p) or want to change your phone's mirror settings:
1. Open the Phone-Link extension UI.
2. Navigate to the **Webcam** (DroidCam) or **Screen Mirroring** (Scrcpy) view.
3. Click the dropdowns in the interface to change options like **Resolution** (e.g., `1280x720` or `1920x1080`), **FPS**, or **Camera Facing** (front/back).
4. The extension automatically remembers your choices the next time you connect!

## How It Works

Phone-Link acts as a bridge between a customized QML user interface (Quickshell) and native Linux command-line tools.

1. **DBus Integration:** The core of the extension relies on KDE Connect's local background service (`kdeconnectd`). A Python background script (`scripts/kdeconnect/monitor.py`) listens to KDE Connect's DBus events in real-time (like battery percentage, connection status, and notifications) and broadcasts them directly to the QML UI as JSON objects.
2. **Commands & Execution:** Actions inside the extension execute raw shell commands natively (e.g., launching `scrcpy` to mirror your screen or `droidcam-cli` to mount a webcam). We use `qdbus` cross-platform abstractions to securely invoke KDE Connect methods, such as mounting the phone's SFTP storage.
3. **Reactive UI:** The interface is built using Qt/QML. It uses `ExtensionServices.loaded` binding proxies to instantly update its states whenever the background services detect an event (e.g., hiding buttons if your phone disconnects from the Wi-Fi).
