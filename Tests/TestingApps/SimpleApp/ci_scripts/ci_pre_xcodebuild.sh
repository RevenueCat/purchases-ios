#!/bin/bash -e

SIMPLE_APP_API_KEY=$REVENUECAT_XCODE_CLOUD_SIMPLE_APP_API_KEY
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -z "$SIMPLE_APP_API_KEY" ]; then
    echo "SimpleApp API key environment variable is not set."
else
    echo "Replacing API key on SimpleApp"

    file="$SCRIPT_DIR/../SimpleApp/Configuration.swift"
    sed -i.bak 's/private static let apiKeyFromCI = ""/private static let apiKeyFromCI = "'$SIMPLE_APP_API_KEY'"/g' $file
    rm $file.bak
fi
