#### (Somewhat) automated process: 
1. Create a branch bump/x.y.z
1. Create a CHANGELOG.latest.md with the changes for the current 
version (to be used by Fastlane for the github release notes)
1. Update the version number in `RCPurchases.m`, `Purchases.podspec` and in 
`Purchases/Info.plist` by running `fastlane bump_and_update_changelog version:x.y.z`
1. Commit the changes `git commit -am "Version x.y.z"`
1. Make a PR, merge when approved
1. `cd bin`
1. `./release_version.sh -c x.y.z -n a.b.c`, where a.b.c will be the next release after this one. 
If you're releasing version 3.0.2, for example, this would be `./release_version.sh -c 3.0.2 -n 3.1.0`. 
This will do all of the other steps in the manual process.
1. Make a PR for the snapshot bump, merge when approved

#### Manual process:

1. Create a branch bump/x.y.z
1. Update the version number in `RCPurchases.m`, `Purchases.podspec` and in 
`Purchases/Info.plist` by running `fastlane bump version:x.y.z`
1. Update CHANGELOG.md for the new release
1. Commit the changes `git commit -am "Version x.y.z"`
1. Make a PR, merge when approved
1. `git tag -a x.y.z -m "Version x.y.z"`
1. `git push origin bump/x.y.z && git push --tags`
1. `pod trunk push Purchases.podspec`
1. `carthage build --archive
1. Create a [new github release](https://github.com/revenuecat/purchases-ios/releases)
1. Upload to the new release `Purchases.framework.zip`
1. Create a branch bump/a.b.c, where a.b.c is the next version of the app after this release.
1. Update the version number in `RCPurchases.m`, `Purchases.podspec` and in `Purchases/Info.plist` to the snapshot version for the next release, i.e. `x.y.z-SNAPSHOT`
1. `git commit -am "Preparing for next version"`
1. `git push origin bump/a.b.c`
1. Make a PR for the snapshot bump, merge when approved
