// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Dependencies",
    dependencies: [
        .package(
            url: "https://github.com/RevenueCat/purchases-ios-spm", 
            branch: "main"
        ),
        // do not modify yet, because it will modify the local copy of purchases-ios
        // .package(
        //     path: "../../../../purchases-ios"
        // ),
    ]
)
