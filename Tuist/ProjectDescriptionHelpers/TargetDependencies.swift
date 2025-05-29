import ProjectDescription

extension TargetDependency {
    public static func revenueCat(local: Bool) -> TargetDependency {
        if local {
            .project(
                target: "RevenueCat",
                path: .relativeToRoot("Projects/RevenueCat")
            )
        } else {
            .external(
                name: "RevenueCat"
            )
        }
    }

    public static func revenueCatUI(local: Bool) -> TargetDependency {
        if local {
            .project(
                target: "RevenueCatUI",
                path: .relativeToRoot("Projects/RevenueCatUI")
            )
        } else {
            .external(
                name: "RevenueCatUI"
            )
        }
    }

    public static var nimble: TargetDependency {
        .external(
            name: "Nimble"
        )
    }

    public static var snapshotTesting: TargetDependency {
        .external(
            name: "SnapshotTesting"
        )
    }

    public static var ohHTTPStubs: TargetDependency {
        .external(name: "OHHTTPStubs")
    }

    public static var ohHTTPStubsSwift: TargetDependency {
        .external(name: "OHHTTPStubsSwift")
    }
}
