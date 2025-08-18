#!/bin/bash

# Exit on error
set -e

# Create temporary directory for PR swiftinterface files
mkdir -p /tmp/pr-swiftinterface

# Function to build for a specific platform and copy the interface file
build_and_copy_interface() {
    local sdk=$1
    local platform=$2
    local suffix=$3

    echo "Building RevenueCat framework for $platform..."
    xcodebuild clean build \
        -scheme "RevenueCat" \
        -derivedDataPath ".build" \
        -configuration Release \
        -sdk "$(xcrun --sdk $sdk --show-sdk-path)" \
        -destination "generic/platform=$platform" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES

    # Find and copy the interface file
    echo "Looking for .swiftinterface file for $platform..."
    DERIVED_DATA_DIR=".build"
    SWIFTINTERFACE_PATH=$(find "$DERIVED_DATA_DIR" -type f -name "RevenueCat.swiftinterface" | grep -v "private" | head -n 1)

    if [ -f "$SWIFTINTERFACE_PATH" ]; then
        echo "Found swiftinterface at: $SWIFTINTERFACE_PATH"
        cp "$SWIFTINTERFACE_PATH" "/tmp/pr-swiftinterface/RevenueCat${suffix}.swiftinterface"
        echo "Generated .swiftinterface file has been copied to /tmp/pr-swiftinterface/RevenueCat${suffix}.swiftinterface"
    else
        echo "Error: Could not find RevenueCat.swiftinterface file for $platform"
        echo "Contents of derived data directory:"
        find "$DERIVED_DATA_DIR" -type f -name "*.swiftinterface" -o -name "RevenueCat*"
        exit 1
    fi
}

# Build for each platform
build_and_copy_interface "iphonesimulator" "iOS" "-ios-simulator"
build_and_copy_interface "iphoneos" "iOS" "-ios"
build_and_copy_interface "macosx" "macOS" "-macos"
build_and_copy_interface "watchsimulator" "watchOS" "-watchos-simulator"
build_and_copy_interface "watchos" "watchOS" "-watchos"