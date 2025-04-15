// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Dependencies",
    dependencies: [
        // .package(
        //     url: "https://github.com/RevenueCat/purchases-ios-spm", 
        //     from: "5.21.0"
        // ),
        .package(
            path: "../../../../purchases-ios"
        ),
    ]
)
