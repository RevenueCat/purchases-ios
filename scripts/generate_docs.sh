# Generate Swift SourceKitten output
sourcekitten doc -- \
    -project Purchases.xcodeproj \
    -scheme PurchasesCoreSwift > swiftDoc.json

# Generate Objective-C SourceKitten output
sourcekitten doc --objc $(pwd)/Purchases/Public/Purchases.h \
    -- -x objective-c \
    -isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) \
    -I $(pwd) -fmodules > objcDoc.json

# Feed both outputs to Jazzy as a comma-separated list
jazzy --sourcekitten-sourcefile swiftDoc.json,objcDoc.json \
    --module Purchases \
    --output generated_docs/

# clean up generated files
rm swiftDoc.json
rm objcDoc.json
