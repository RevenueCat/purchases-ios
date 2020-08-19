mkdir builds
mkdir builds/archives
mkdir builds/xcframeworks

xcodebuild archive  -project "Purchases.xcodeproj" \
		-scheme "Purchases" \
		-destination "generic/platform=appletvos" \
		-configuration "Release" \
		-archivePath "./builds/archives/appletvos.xcarchive"\
		SKIP_INSTALL=NO

xcodebuild archive  -project "Purchases.xcodeproj" \
		-scheme "Purchases" \
		-destination "generic/platform=appletvsimulator" \
		-configuration "Release" \
		-archivePath "./builds/archives/appletvsimulator.xcarchive"\
		SKIP_INSTALL=NO

xcodebuild archive  -project "Purchases.xcodeproj" \
		-scheme "Purchases" \
		-destination "generic/platform=watchos" \
		-configuration "Release" \
		-archivePath "./builds/archives/watchos.xcarchive"\
		SKIP_INSTALL=NO

xcodebuild archive  -project "Purchases.xcodeproj" \
		-scheme "Purchases" \
		-destination "generic/platform=watchsimulator" \
		-configuration "Release" \
		-archivePath "./builds/archives/watchsimulator.xcarchive"\
		SKIP_INSTALL=NO

xcodebuild archive  -project "Purchases.xcodeproj" \
		-scheme "Purchases" \
		-destination "generic/platform=iphoneos" \
		-configuration "Release" \
		-archivePath "./builds/archives/iphoneos.xcarchive"\
		SKIP_INSTALL=NO

xcodebuild archive  -project "Purchases.xcodeproj" \
		-scheme "Purchases" \
		-destination "generic/platform=appletvos" \
		-configuration "Release" \
		-archivePath "./builds/archives/appletvos.xcarchive"\
		SKIP_INSTALL=NO

xcodebuild archive  -project "Purchases.xcodeproj" \
		-scheme "Purchases" \
		-destination "generic/platform=iphonesimulator" \
		-configuration "Release" \
		-archivePath "./builds/archives/iphonesimulator.xcarchive"\
		SKIP_INSTALL=NO

xcodebuild archive  -project "Purchases.xcodeproj" \
		-scheme "Purchases" \
		-destination "generic/platform=macosx" \
		-configuration "Release" \
		-archivePath "./builds/archives/macosx.xcarchive"\
		SKIP_INSTALL=NO

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
