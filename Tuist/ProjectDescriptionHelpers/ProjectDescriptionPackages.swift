import ProjectDescription

extension Array<ProjectDescription.Package> {

    public static var projectPackages: [ProjectDescription.Package] {
        if Environment.dependencyMode == .localSwiftPackage {
            return [.package(path: "../..")]
        } else if Environment.dependencyMode == .remoteSwiftPackage {
            return [.package(url: "https://github.com/RevenueCat/purchases-ios", .branch("main"))]
        } else {
            return []
        }
    }
}