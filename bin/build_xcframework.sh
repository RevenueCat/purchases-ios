mkdir builds
mkdir builds/xcframeworks

xcodebuild -create-xcframework \
	-framework ./builds/archives/appletvsimulator.xcarchive/Products/Library/Frameworks/Purchases.framework \
	-framework ./builds/archives/watchos.xcarchive/Products/Library/Frameworks/Purchases.framework \
	-framework ./builds/archives/watchsimulator.xcarchive/Products/Library/Frameworks/Purchases.framework \
	-framework ./builds/archives/iphoneos.xcarchive/Products/Library/Frameworks/Purchases.framework \
	-framework ./builds/archives/appletvos.xcarchive/Products/Library/Frameworks/Purchases.framework \
	-framework ./builds/archives/iphonesimulator.xcarchive/Products/Library/Frameworks/Purchases.framework \
	-framework ./builds/archives/macosx.xcarchive/Products/Library/Frameworks/Purchases.framework \
	-output ./builds/xcframeworks/Purchases.xcframework

xcodebuild -create-xcframework \
	-framework ./builds/archives/appletvsimulator.xcarchive/Products/Library/Frameworks/PurchasesCoreSwift.framework \
	-framework ./builds/archives/watchos.xcarchive/Products/Library/Frameworks/PurchasesCoreSwift.framework \
	-framework ./builds/archives/watchsimulator.xcarchive/Products/Library/Frameworks/PurchasesCoreSwift.framework \
	-framework ./builds/archives/iphoneos.xcarchive/Products/Library/Frameworks/PurchasesCoreSwift.framework \
	-framework ./builds/archives/appletvos.xcarchive/Products/Library/Frameworks/PurchasesCoreSwift.framework \
	-framework ./builds/archives/iphonesimulator.xcarchive/Products/Library/Frameworks/PurchasesCoreSwift.framework \
	-framework ./builds/archives/macosx.xcarchive/Products/Library/Frameworks/PurchasesCoreSwift.framework \
	-output ./builds/xcframeworks/PurchasesCoreSwift.xcframework
