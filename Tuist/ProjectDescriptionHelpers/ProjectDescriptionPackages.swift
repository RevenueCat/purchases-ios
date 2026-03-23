import ProjectDescription

extension Array<ProjectDescription.Package> {

    public static var projectPackages: [ProjectDescription.Package] {
        switch Environment.dependencyMode {
        case .localSwiftPackage:
            return [.package(path: .relativeToRoot("."))]
        case .remoteSwiftPackage:
            return [.package(url: "https://github.com/RevenueCat/purchases-ios", .branch("main"))]
        case .localXcodeProject, .remoteXcodeProject:
            return []
        }
    }

    public static var vanillaAdTrackingPackages: [ProjectDescription.Package] {
        switch Environment.dependencyMode {
        case .localSwiftPackage:
            return [
                .package(path: .relativeToRoot(".")),
                .package(
                    url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
                    .upToNextMajor(from: "13.0.0")
                )
            ]
        case .remoteSwiftPackage:
            return [
                .package(url: "https://github.com/RevenueCat/purchases-ios", .branch("main")),
                .package(
                    url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
                    .upToNextMajor(from: "13.0.0")
                )
            ]
        case .localXcodeProject, .remoteXcodeProject:
            return []
        }
    }

    public static var adMobPackage: [ProjectDescription.Package] {
        switch Environment.dependencyMode {
        case .localSwiftPackage:
            return [.package(path: .relativeToRoot("AdapterSDKs/RevenueCatAdMob"))]
        case .remoteSwiftPackage, .localXcodeProject, .remoteXcodeProject:
            return []
        }
    }
}
