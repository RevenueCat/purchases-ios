#!/bin/sh

device="${TARGET_DEVICE_IDENTIFIER:-${TARGET_DEVICE_UDID:-}}"
if [ -z "$device" ]; then
    device="booted"
fi

case "${PLATFORM_NAME:-}" in
    *simulator | "")
        ;;
    *)
        exit 0
        ;;
esac

defaults_directory="${TMPDIR:-/tmp}/revenuecat-tests-simulator-defaults"
global_defaults="$defaults_directory/${device}-global.plist"
datetime_defaults="$defaults_directory/${device}-datetime.plist"

boot_device_if_needed() {
    if [ "$device" != "booted" ]; then
        xcrun simctl boot "$device" >/dev/null 2>&1 || true
        xcrun simctl bootstatus "$device" -b >/dev/null 2>&1 || true
    fi
}

delete_global_defaults() {
    xcrun simctl spawn "$device" defaults delete NSGlobalDomain AppleLocale >/dev/null 2>&1 || true
    xcrun simctl spawn "$device" defaults delete NSGlobalDomain AppleLanguages >/dev/null 2>&1 || true
}

delete_datetime_defaults() {
    xcrun simctl spawn "$device" defaults delete com.apple.preferences.datetime timezone >/dev/null 2>&1 || true
}

set_locale() {
    boot_device_if_needed
    mkdir -p "$defaults_directory"

    xcrun simctl spawn "$device" defaults export NSGlobalDomain - > "$global_defaults" 2>/dev/null \
        || rm -f "$global_defaults"
    xcrun simctl spawn "$device" defaults export com.apple.preferences.datetime - > "$datetime_defaults" 2>/dev/null \
        || rm -f "$datetime_defaults"

    xcrun simctl spawn "$device" defaults write NSGlobalDomain AppleLocale en_US || true
    xcrun simctl spawn "$device" defaults write NSGlobalDomain AppleLanguages -array en-US || true
    xcrun simctl spawn "$device" defaults write com.apple.preferences.datetime timezone UTC || true
    xcrun simctl spawn "$device" launchctl setenv TZ UTC || true
}

restore_locale() {
    if [ -f "$global_defaults" ]; then
        xcrun simctl spawn "$device" defaults import NSGlobalDomain "$global_defaults" >/dev/null 2>&1 \
            || delete_global_defaults
        rm -f "$global_defaults"
    else
        delete_global_defaults
    fi

    if [ -f "$datetime_defaults" ]; then
        xcrun simctl spawn "$device" defaults import com.apple.preferences.datetime "$datetime_defaults" >/dev/null 2>&1 \
            || delete_datetime_defaults
        rm -f "$datetime_defaults"
    else
        delete_datetime_defaults
    fi

    xcrun simctl spawn "$device" launchctl unsetenv TZ >/dev/null 2>&1 || true
}

case "${1:-}" in
    set)
        set_locale
        ;;
    restore)
        restore_locale
        ;;
    *)
        echo "Usage: $0 set|restore" >&2
        exit 1
        ;;
esac
