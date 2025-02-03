#!/bin/bash -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Replacing API keys on PaywallsTester"

file="$SCRIPT_DIR/../PaywallsTester/Config/ConfigItem.swift"
sed -i '' 's/static var apiKey: String { "" }/static var apiKey: String { "'"$REVENUECAT_XCODE_CLOUD_RC_APP_API_KEY"'" }/' $file

