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

# Get build settings and derived data directory
echo "Getting build settings..."
BUILD_SETTINGS=$(xcodebuild -scheme RevenueCat -showBuildSettings)
echo "Build settings paths:"
echo "$BUILD_SETTINGS" | grep -E "OBJROOT|CONFIGURATION_BUILD_DIR|TARGET_BUILD_DIR"

DERIVED_DATA_DIR=$(echo "$BUILD_SETTINGS" | grep -m 1 "OBJROOT" | cut -d'=' -f2 | xargs)
echo "Derived data directory: $DERIVED_DATA_DIR"

echo "Searching for all .swiftinterface files..."
find "$DERIVED_DATA_DIR" -type f -name "*.swiftinterface" 2>/dev/null

echo "Looking specifically for RevenueCat.swiftinterface (excluding private)..."
SWIFTINTERFACE_PATH=$(find "$DERIVED_DATA_DIR" -type f -name "RevenueCat.swiftinterface" | grep -v "private" | head -n 1)

if [ -f "$SWIFTINTERFACE_PATH" ]; then
    echo "Found swiftinterface at: $SWIFTINTERFACE_PATH"
    cp "$SWIFTINTERFACE_PATH" ./revenuecat-api.swiftinterface
    echo "Generated .swiftinterface file has been copied to ./revenuecat-api.swiftinterface"
else
    echo "Error: Could not find RevenueCat.swiftinterface file"
    echo "Contents of build directory (recursive):"
    find "$DERIVED_DATA_DIR" -type f -name "*.swiftinterface" -o -name "RevenueCat*" 2>/dev/null
    exit 1
fi