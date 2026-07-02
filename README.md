# Phone-Link

A powerful Quickshell extension that integrates your phone tightly with your Linux desktop.

## Installation & Setup

1. **Install Dependencies (The Easy Way):**
   This extension requires several system packages to work, such as KDE Connect for communication, `sshfs` for file browsing, `scrcpy` for screen mirroring, and `droidcam-cli` for webcam support.
   
   To install them, just open the Phone Link extension tab, and click the **"Install Dependencies" tab/button** at the very bottom of the page! 
   
   This will instantly launch an interactive setup wizard in Kitty that allows you to choose exactly which features you want to install. It will also seamlessly configure your Linux kernel modules (`v4l2loopback` and `snd_aloop`) so your virtual webcam and mic work reliably on every startup.

   *(If you'd rather run it manually from the terminal, simply execute `./install_dependencies.sh` in the extension's folder).*

2. **Pairing Your Phone:**
   Make sure the **KDE Connect** app is installed on your Android/iOS device. 
   Open the extension on your desktop, select your phone, and click **Pair**. Accept the pairing request on your phone.

3. **Reload Quickshell:**
   Once dependencies are installed, you may need to reload Quickshell to see the changes:
   ```bash
   killall quickshell && quickshell &
   ```

## How to Change Settings (e.g. Webcam Resolution)

Most settings can be customized instantly directly from the **Extension Manager UI**.

For example, if you want a **higher webcam resolution** (e.g., 1080p instead of 720p):
1. Open the Quickshell **Installed Extensions** page.
2. Click the dropdown arrow on the **Phone Link** card.
3. Use the **Webcam Resolution** selector to choose between `480p`, `720p`, or `1080p`. The extension will automatically remember this choice the next time you connect your camera!

Additionally, other settings can be changed directly inside the Phone Link interface:
- Open the Phone-Link extension UI.
- Navigate to the **Webcam** (DroidCam) or **Screen Mirroring** (Scrcpy) view.
- Tweak the dropdowns to change options like **FPS**, or **Camera Facing** (front/back).

## How It Works

Phone-Link acts as a bridge between a customized QML user interface (Quickshell) and native Linux command-line tools.

1. **DBus Integration:** The core of the extension relies on KDE Connect's local background service (`kdeconnectd`). A Python background script (`scripts/kdeconnect/monitor.py`) listens to KDE Connect's DBus events in real-time (like battery percentage, connection status, and notifications) and broadcasts them directly to the QML UI as JSON objects.
2. **Commands & Execution:** Actions inside the extension execute raw shell commands natively (e.g., launching `scrcpy` to mirror your screen or `droidcam-cli` to mount a webcam). We use `qdbus` cross-platform abstractions to securely invoke KDE Connect methods, such as mounting the phone's SFTP storage.
3. **Reactive UI:** The interface is built using Qt/QML. It uses `ExtensionServices.loaded` binding proxies to instantly update its states whenever the background services detect an event (e.g., hiding buttons if your phone disconnects from the Wi-Fi).

## Credits

Special thanks to [P3drovfx](https://github.com/P3drovfx) for providing the underlying functionality and inspiration for this project!
