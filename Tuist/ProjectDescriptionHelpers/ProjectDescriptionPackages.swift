import ProjectDescription

extension Array<ProjectDescription.Package> {

    public static var projectPackages: [ProjectDescription.Package] {
        switch Environment.dependencyMode {
        case .localSwiftPackage:
            return [.package(path: "../..")]
        case .remoteSwiftPackage:
            return [.package(url: "https://github.com/RevenueCat/purchases-ios", .branch("main"))]
        case .localXcodeProject, .remoteXcodeProject:
            return []
        }
    }
}
