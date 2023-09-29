#!/bin/bash -e

PAYWALLS_TESTER_API_KEY_FOR_TESTING=$REVENUECAT_XCODE_CLOUD_SIMPLE_APP_API_KEY_FOR_TESTING
PAYWALLS_TESTER_API_KEY_FOR_DEMOS=$REVENUECAT_XCODE_CLOUD_SIMPLE_APP_API_KEY_FOR_DEMOS
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -z "$PAYWALLS_TESTER_API_KEY_FOR_TESTING" ]; then
    echo "PaywallsTester API key for testing environment variable is not set."
elif [ -z "$PAYWALLS_TESTER_API_KEY_FOR_DEMOS" ]; then
    echo "PaywallsTester API key for demos environment variable is not set."
else
    echo "Replacing API keys on PaywallsTester"

    file="$SCRIPT_DIR/../PaywallsTester/Configuration.swift"
    sed -i.bak 's/private static let apiKeyFromCIForTesting = ""/private static let apiKeyFromCIForTesting = "'$PAYWALLS_TESTER_API_KEY_FOR_TESTING'"/g' $file
    sed -i.bak 's/private static let apiKeyFromCIForDemos = ""/private static let apiKeyFromCIForDemos = "'$PAYWALLS_TESTER_API_KEY_FOR_DEMOS'"/g' $file
    rm $file.bak
fi
