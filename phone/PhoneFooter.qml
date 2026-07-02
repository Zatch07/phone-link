// PhoneFooter.qml
// Render the 3 hero cards (scrcpy/webcam/mic) at the bottom of the Phone tab.
// Each card has a state machine: unavailable | offline | ready | connecting | active.
// The detailLine binding shows elapsed time and connection info when active.
// Backed by (ExtensionServices.loaded["phone-link.KdeConnectService"] || {}), (ExtensionServices.loaded["phone-link.PhoneCameraService"] || {}) and (ExtensionServices.loaded["phone-link.PhoneMicService"] || {}) singletons.


// Performance fix: multi-arg .arg() doesn't work in this Qt/Quickshell version
// Use chained .arg(x).arg(y) instead.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

/**
 * Footer of the Phone tab — renders a stacked set of hero cards for the
 * three phone-as-a-peripheral features: Scrcpy Mirror, Phone Webcam, and
 * Phone Microphone.
 *
 * When any card is in the "active" state, it expands in height and reveals
 * inline status (elapsed time, IP, /dev/videoN), a big Stop button and
 * contextual quick-action chips (flip/mirror/preview for webcam, mute/gain
 * for mic, focus/kill/screenshot for scrcpy). The notifications panel
 * above contracts automatically because the Phone panel uses
 * `Layout.fillHeight` on it.
 *
 * Click behaviour on each card:
 *   • Idle → start the feature.
 *   • Active → main click is a secondary action (focus scrcpy window, mute
 *     mic toggle, focus preview window). Use the explicit Stop button to
 *     actually stop the feature.
 *   • Settings gear (top-right) → opens the sub-page with detailed options.
 */
Item {
    id: root

    implicitHeight: visible ? footerColumn.implicitHeight : 0
    height: visible ? implicitHeight : 0
    visible: true

    signal requestOpenSubPage(url target)

    // ─── Null-safe service aliases ─────────────────────────
    readonly property var _kdc: (ExtensionServices.loaded["phone-link.KdeConnectService"] || {})
    readonly property var _cam: (ExtensionServices.loaded["phone-link.PhoneCameraService"] || {})
    readonly property var _mic: (ExtensionServices.loaded["phone-link.PhoneMicService"] || {})

    readonly property bool _scrcpyPresent: _kdc ? _kdc.scrcpyAvailable : false
    readonly property bool _droidcamPresent: _cam ? _cam.available : false
    readonly property bool _micPresent: _mic ? _mic.available : false

    readonly property bool _deviceOnline: _kdc ? _kdc.activeReachable : false

    // ─── Install guide popup state ─────────────────────────
    // When visible, shows a floating overlay listing missing dependencies
    // with copyable install commands per distro.
    property bool _installGuideVisible: false
    property var _installGuideDeps: []
    property string _installGuideTitle: Translation.tr("Missing Dependencies")

    function _openInstallGuide(deps, title) {
        root._installGuideDeps = deps || []
        root._installGuideTitle = title || Translation.tr("Missing Dependencies")
        root._installGuideVisible = true
    }

    /** Helper — formats milliseconds as "Xm Ys" or "Xs" for inline display. */
    function _fmtElapsed(ms): string {
        const s = Math.floor(ms / 1000)
        if (s < 60) return s + "s"
        const m = Math.floor(s / 60)
        const rem = s % 60
        if (m < 60) return m + "m " + (rem < 10 ? "0" : "") + rem + "s"
        const h = Math.floor(m / 60)
        const rm = m % 60
        return h + "h " + (rm < 10 ? "0" : "") + rm + "m"
    }

    ColumnLayout {
        id: footerColumn
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        // ─── 1. Scrcpy Mirror ──────────────────────────────
        PhoneFeatureCard {
            Layout.fillWidth: true
            iconName: "smart_display"
            iconShape: MaterialShape.Shape.Cookie9Sided
            title: root._scrcpyPresent
                ? ((ExtensionServices.loaded["phone-link.KdeConnectService"] || {}).scrcpyRunning
                    ? Translation.tr("scrcpy Mirror")
                    : Translation.tr("Open scrcpy Mirror"))
                : Translation.tr("Install scrcpy")
            subtitle: {
                if (!root._scrcpyPresent)
                    return Translation.tr("Click to see missing dependencies and install guide")
                if (!root._deviceOnline)
                    return Translation.tr("Pair a reachable device to mirror its screen")
                if ((ExtensionServices.loaded["phone-link.KdeConnectService"] || {}).scrcpyRunning)
                    return Translation.tr("Mirror is running · click to focus window")
                if ((ExtensionServices.loaded["phone-link.KdeConnectService"] || {}).scrcpyLaunching)
                    return Translation.tr("Launching scrcpy…")
                return Translation.tr("Launches a floating SDL window for the active phone")
            }
            state: !root._scrcpyPresent ? "unavailable"
                : !root._deviceOnline ? "offline"
                : root._kdc && root._kdc.scrcpyRunning ? "active"
                : root._kdc && root._kdc.scrcpyLaunching ? "connecting"
                : "ready"
            detailLine: (root._kdc && root._kdc.scrcpyRunning)
                ? Translation.tr("Active for %1").arg(root._fmtElapsed(root._kdc.scrcpyElapsedMs))
                : ""
            dropEnabled: root._kdc && root._kdc.scrcpyRunning && root._deviceOnline
            onFilesDropped: urls => {
                urls.forEach(url => {
                    const file = String(url).replace(/^file:\/\//, "")
                    if (file.length > 0 && root._kdc)
                        root._kdc.shareUrl(root._kdc.activeDeviceId, file)
                })
            }
            inlineActions: (root._kdc && root._kdc.scrcpyRunning) ? [
                {
                    icon: "center_focus_strong",
                    label: Translation.tr("Focus window"),
                    onClicked: () => root._kdc && root._kdc.focusScrcpyWindow()
                },
                {
                    icon: "screenshot_monitor",
                    label: Translation.tr("Phone screenshot"),
                    onClicked: () => root._kdc && root._kdc.adbScreenshot()
                },
                {
                    icon: "power_settings_new",
                    label: Translation.tr("Toggle phone power"),
                    onClicked: () => root._kdc && root._kdc.adbTogglePower()
                },
                {
                    icon: (root._kdc && root._kdc.adbReachable) ? "cast_connected" : "cast",
                    label: (root._kdc && root._kdc.adbReachable)
                        ? Translation.tr("ADB reachable")
                        : Translation.tr("ADB not connected"),
                    onClicked: () => root._kdc && root._kdc._probeAdb()
                }
            ] : []
            lastError: ""
            onClicked: {
                if (root._scrcpyPresent && root._kdc) {
                    if (root._kdc.scrcpyRunning) {
                        root._kdc.killScrcpy()
                    } else if (!root._kdc.scrcpyLaunching) {
                        root._kdc.launchScrcpy(root._kdc.activeDeviceId)
                    }
                } else if (root._kdc) {
                    root._openInstallGuide(
                        root._kdc.scrcpyMissingDeps,
                        Translation.tr("scrcpy Mirror — Missing Dependencies"))
                }
            }
            onStopClicked: {
                if (root._kdc && root._kdc.scrcpyRunning)
                    root._kdc.killScrcpy()
            }
        }

        // ─── 2. Phone Webcam ────────────────────────────────
        PhoneFeatureCard {
            Layout.fillWidth: true
            iconName: "videocam"
            iconShape: MaterialShape.Shape.Cookie7Sided
            title: root._droidcamPresent
                ? Translation.tr("Phone Webcam")
                : Translation.tr("Install DroidCam")
            subtitle: {
                if (!root._droidcamPresent)
                    return Translation.tr("Click to see missing dependencies and install guide")
                if (!root._deviceOnline)
                    return Translation.tr("Pair a reachable device to use its camera")
                if (root._cam && root._cam.connecting)
                    return Translation.tr("Connecting to %1:%2…").arg(root._cam.activeIp || "?").arg(String(root._cam.activePort))
                if (root._cam && root._cam.running)
                    return root._cam.videoDevice || "/dev/videoN"
                return Translation.tr("Tap to start · settings to configure")
            }
            state: !root._droidcamPresent ? "unavailable"
                : !root._deviceOnline ? "offline"
                : (root._cam && root._cam.connecting) ? "connecting"
                : (root._cam && root._cam.running) ? "active"
                : "ready"
            detailLine: {
                if (!root._cam || !root._cam.running) return ""
                const el = root._fmtElapsed(root._cam.elapsedMs)
                const ip = root._cam.activeIp || "(usb)"
                const port = String(root._cam.activePort)
                const dev = root._cam.videoDevice || "/dev/videoN"
                return "Active for " + el + " · " + ip + ":" + port + " · " + dev
            }
            lastError: root._cam ? root._cam.lastError : ""
            inlineActions: (root._cam && root._cam.running) ? [
                {
                    icon: "preview",
                    label: Translation.tr("Open preview window (mpv)"),
                    onClicked: () => root._cam && root._cam.openExternalPreview()
                }
            ] : []
            onClicked: {
                if (!root._droidcamPresent) {
                    root._openInstallGuide(
                        root._cam ? root._cam.missingDeps : [],
                        Translation.tr("Phone Webcam — Missing Dependencies"))
                    return
                }
                if (root._cam && (root._cam.connecting || root._cam.running)) {
                    root._cam.stopCamera()
                } else if (root._cam) {
                    root._cam.startCamera()
                }
            }
            onStopClicked: {
                if (root._cam) root._cam.stopCamera()
            }
        }

        // ─── 3. Phone Microphone ────────────────────────────
        PhoneFeatureCard {
            Layout.fillWidth: true
            iconName: "mic"
            iconShape: MaterialShape.Shape.Sunny
            title: root._micPresent
                ? Translation.tr("Phone Microphone")
                : Translation.tr("Install scrcpy or DroidCam")
            subtitle: {
                if (!root._micPresent)
                    return Translation.tr("Click to see missing dependencies and install guide")
                if (!root._deviceOnline)
                    return Translation.tr("Pair a reachable device to use its microphone")
                if (root._mic && root._mic.connecting)
                    return Translation.tr("Set up audio routing…")
                if (root._mic && root._mic.running)
                    return root._mic.muted
                        ? Translation.tr("Muted · click to unmute")
                        : Translation.tr("Active · click to mute")
                return Translation.tr("Tap to start · uses scrcpy or DroidCam")
            }
            state: !root._micPresent ? "unavailable"
                : !root._deviceOnline ? "offline"
                : (root._mic && root._mic.connecting) ? "connecting"
                : (root._mic && root._mic.running) ? "active"
                : "ready"
            detailLine: {
                if (!root._mic || !root._mic.running) return ""
                const el = root._fmtElapsed(root._mic.elapsedMs)
                const gain = String(root._mic.micGain) + "%"
                const suffix = root._mic.defaultOverridden
                    ? " · " + Translation.tr("default input")
                    : ""
                return "Active for " + el + " · " + gain + suffix
            }
            lastError: root._mic ? root._mic.lastError : ""
            inlineActions: (root._mic && root._mic.running) ? [
                {
                    icon: root._mic.muted ? "mic_off" : "mic",
                    label: root._mic.muted
                        ? Translation.tr("Unmute")
                        : Translation.tr("Mute"),
                    onClicked: () => root._mic && root._mic.toggleMute()
                },
                {
                    icon: root._mic.monitorEnabled ? "hearing" : "hearing_disabled",
                    label: root._mic.monitorEnabled
                        ? Translation.tr("Stop monitoring")
                        : Translation.tr("Hear yourself"),
                    onClicked: () => root._mic && root._mic.toggleMonitor()
                },
                {
                    icon: "tune",
                    label: Translation.tr("Gain: %1%").arg(String(root._mic.micGain)),
                    onClicked: () => {
                        if (!root._mic) return
                        const g = root._mic.micGain
                        const next = g < 100 ? 100
                                   : g < 150 ? 150
                                   : g < 200 ? 200
                                   : 50
                        root._mic.setGain(next)
                    }
                },
                {
                    icon: root._mic.defaultOverridden ? "star" : "star_border",
                    label: root._mic.defaultOverridden
                        ? Translation.tr("Restore default source")
                        : Translation.tr("Set as default input"),
                    onClicked: () => {
                        if (!root._mic) return
                        if (root._mic.defaultOverridden)
                            root._mic.restoreDefaultSource()
                        else
                            root._mic.overrideDefaultSource()
                    }
                }
            ] : []
            onClicked: {
                if (!root._micPresent) {
                    root._openInstallGuide(
                        root._mic ? root._mic.missingDeps : [],
                        Translation.tr("Phone Microphone — Missing Dependencies"))
                    return
                }
                if (root._mic && root._mic.running && !root._mic.connecting) {
                    root._mic.toggleMute()
                    return
                }
                if (root._mic && root._mic.connecting) {
                    root._mic.stopMic()
                } else if (root._mic) {
                    root._mic.startMic()
                }
            }
            onStopClicked: {
                if (root._mic) root._mic.stopMic()
            }
        }

        RippleButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            buttonRadius: Appearance.rounding.large
            colBackground: Appearance.colors.colLayer1
            colBackgroundHover: Appearance.colors.colLayer2Hover
            
            scale: down ? 0.98 : 1.0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

            contentItem: RowLayout {
                spacing: 8
                Item { Layout.fillWidth: true }
                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    text: "build"
                    iconSize: 18
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: Translation.tr("Install Dependencies")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                }
                Item { Layout.fillWidth: true }
            }
            
            onClicked: {
                Quickshell.execDetached(["kitty", "--", "bash", "-c", "cd ~/.config/illogical-impulse/extensions/installed/phone-link && ./install_dependencies.sh; echo ''; read -p 'Press Enter to exit'"])
            }
        }
    }

    // ─── Install guide popup overlay ───────────────────────
    // Shows when _installGuideVisible is true. Centers over the panel.
    InstallGuidePopup {
        id: installGuidePopup
        anchors.fill: parent
        visible: root._installGuideVisible
        missingDeps: root._installGuideDeps
        detectedDistro: {
            if (root._cam && root._cam.detectedDistro && root._cam.detectedDistro !== "unknown")
                return root._cam.detectedDistro
            if (root._mic && root._mic.detectedDistro && root._mic.detectedDistro !== "unknown")
                return root._mic.detectedDistro
            if (root._kdc && root._kdc.detectedDistro && root._kdc.detectedDistro !== "unknown")
                return root._kdc.detectedDistro
            return "unknown"
        }
        headerTitle: root._installGuideTitle
        onVisibleChanged: {
            if (!visible) root._installGuideVisible = false
        }
        onRefreshRequested: {
            if (root._cam) root._cam.refresh()
            if (root._mic) root._mic.refresh()
            if (root._kdc) {
                root._kdc.checkScrcpyProc.running = true
                root._kdc.checkAdbProc.running = true
            }
        }
    }
}
