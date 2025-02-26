#!/bin/bash -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Replacing API keys on PaywallsTester"

file="$SCRIPT_DIR/../PaywallsTester/Config/Constants.swift"
sed -i '' 's/Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String ?? ""/"'"$REVENUECAT_XCODE_CLOUD_RC_APP_API_KEY"'"/' $file

