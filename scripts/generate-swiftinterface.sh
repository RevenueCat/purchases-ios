#!/bin/bash

# Exit on error
set -e

# Build RevenueCat framework
echo "Building RevenueCat framework..."
xcodebuild clean build \
    -scheme "RevenueCat" \
    -configuration Release \
    -sdk iphonesimulator \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Copy the generated .swiftinterface file
echo "Looking for .swiftinterface file..."
DERIVED_DATA_DIR=$(xcodebuild -showBuildSettings | grep -m 1 "OBJROOT" | cut -d'=' -f2 | xargs)
SWIFTINTERFACE_PATH=$(find "${DERIVED_DATA_DIR}" -name "RevenueCat.swiftinterface" -type f | grep -v "private" | grep "emit-module-interface-path" | head -n 1)

if [ -f "$SWIFTINTERFACE_PATH" ]; then
    cp "$SWIFTINTERFACE_PATH" ./revenuecat-api.swiftinterface
    echo "Generated .swiftinterface file has been copied to ./revenuecat-api.swiftinterface"
else
    echo "Error: Could not find RevenueCat.swiftinterface file"
    exit 1
fi