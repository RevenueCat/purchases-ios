#!/bin/bash -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Configuring PaywallsTester CI build"

if [[ -z "${REVENUECAT_XCODE_CLOUD_RC_APP_API_KEY_OVERRIDE:-}" ]]; then
    echo "error: REVENUECAT_XCODE_CLOUD_RC_APP_API_KEY_OVERRIDE must be set"
    exit 1
fi

file="$SCRIPT_DIR/../PaywallsTester/Config/Constants.swift"
sed -i '' 's/Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String ?? ""/"'"$REVENUECAT_XCODE_CLOUD_RC_APP_API_KEY_OVERRIDE"'"/' $file
