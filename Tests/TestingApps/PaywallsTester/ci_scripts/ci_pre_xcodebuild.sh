#!/bin/bash -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Replacing API keys on PaywallsTester"

file="$SCRIPT_DIR/../PaywallsTester/Configuration.swift"
sed -i.bak 's/static var api: String { "" }/static var api: String { "'"$REVENUECAT_XCODE_CLOUD_SIMPLE_APP_API_KEY"'" }/' $file
rm $file.bak

