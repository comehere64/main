###########################################
## This file is a part of ADPDEDT
###########################################

MODPATH="/data/adb/modules/ADPDEDT"
ORG_PATH="$PATH"
TMP_DIR="$SCRIPT_DIR"
SCRIPT_DIR="/data/adb/ADPDEDT"
APK_PATH="$TMP_DIR/base.apk"

manual_download() {
    echo "$1"
    sleep 3
    am start -a android.intent.action.VIEW -d "https://github.com/5ec1cff/KsuWebUIStandalone/releases"
    exit 1
}

download() {
    PATH=/data/adb/magisk:/data/data/com.termux/files/usr/bin:$PATH
    if command -v curl >/dev/null 2>&1; then
        curl --connect-timeout 10 -Ls "$1"
    else
        busybox wget -T 10 --no-check-certificate -qO- "$1"
    fi
    PATH="$ORG_PATH"
}

get_webui() {
    echo "- Downloading KSU WebUI Standalone..."
    API="https://api.github.com/repos/5ec1cff/KsuWebUIStandalone/releases/latest"
    ping -c 1 -w 5 raw.githubusercontent.com &>/dev/null || manual_download "! Error: Unable to connect to raw.githubusercontent.com, please download manually."
    URL=$(download "$API" | grep -o '"browser_download_url": "[^"]*"' | cut -d '"' -f 4) || manual_download "! Error: Unable to get latest version, please download manually."
    download "$URL" > "$APK_PATH" || manual_download "! Error: APK download failed, please download manually."

    echo "- Installing..."
    pm install -r "$APK_PATH" || {
        rm -f "$APK_PATH"
        manual_download "! Error: APK installation failed, please download manually.."
    }

    echo "- Done."
    rm -f "$APK_PATH"

    echo "- Launching WebUI..."
    am start -n "io.github.a13e300.ksuwebui/.WebUIActivity" -e id "ADPDEDT"
}

# Launch KSUWebUI standalone or MMRL, install KSUWebUI standalone if both are not installed
if pm path io.github.a13e300.ksuwebui >/dev/null 2>&1; then
    echo "- Launching WebUI in KSUWebUIStandalone..."
    am start -n "io.github.a13e300.ksuwebui/.WebUIActivity" -e id "ADPDEDT"
elif pm path com.dergoogler.mmrl.wx > /dev/null 2>&1; then
    echo "- Launching WebUI in WebUI X..."
    am start -n "com.dergoogler.mmrl.wx/.ui.activity.webui.WebUIActivity" -e MOD_ID "ADPDEDT"
else
    echo "! No WebUI app found"
    get_webui
fi

echo "- WebUI launched successfully."