#!/bin/bash -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Replacing API keys on PaywallsTester"

file="$SCRIPT_DIR/../PaywallsTester/Config/ConfigItem.swift"
sed -i '' 's/static var apiKey: String { "" }/static var apiKey: String { "'"$REVENUECAT_XCODE_CLOUD_RC_APP_API_KEY"'" }/' $file

# This allow Local.xcconfig to be found by Xcode
xcconfig_file="$(cd "$SCRIPT_DIR/../../../../" && pwd)/Local.xcconfig"

echo "Enabling PAYWALL_COMPONENTS compiler flag in $xcconfig_file"
echo "SWIFT_ACTIVE_COMPILATION_CONDITIONS = \$(inherited) PAYWALL_COMPONENTS" > "$xcconfig_file"

# Update Package.swift with PAYWALL_COMPONENTS define
package_file="$(cd "$SCRIPT_DIR/../../../../" && pwd)/Package.swift"
sed -i '' 's/\/\/ REPLACE_WITH_DEFINES_HERE/.define("PAYWALL_COMPONENTS")/' "$package_file"

