1. Update the version number in `RCPurchases.m`, `Purchases.podspec` and in `Purchases/Info.plist`
1. Update CHANGELOG.md for the new release
1. Commit the changes `git commit -am "Version x.y.z"`
1. `git tag -a x.y.z -m "Version x.y.z"`
1. `git push origin master && git push --tags`
1. `pod trunk push Purchases.podspec`
1. `carthage build --no-skip-current` to create a dynamic framework
1. Zip `build/Release-iphoneos/Purchases.framework` and `build/Release-iphoneos/Purchases.dsym`
1. Create a [new github release](https://github.com/revenuecat/purchases-ios/releases)
1. Upload `Purchases.framework.zip` and `Purchases.dsym.zip` to the new release
1. Update the version number in `RCPurchases.m`, `Purchases.podspec`, `README.md` and in `Purchases/Info.plist` to the snapshot version for the next release, i.e. `x.y.z-SNAPSHOT`
1. `git commit -am "Preparing for next version"`
1. `git push origin master`
