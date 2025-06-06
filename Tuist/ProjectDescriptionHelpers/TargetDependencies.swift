import ProjectDescription

extension TargetDependency {
    /// Returns a RevenueCat dependency that can be either local or external
    /// - Parameter local: If true, returns a local project dependency. If false, returns an external dependency
    /// from spm
    /// - Returns: A TargetDependency for RevenueCat
    public static var revenueCat: TargetDependency {
        if Environment.local {
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

    /// Returns a RevenueCatUI dependency that can be either local or external
    /// - Parameter local: If true, returns a local project dependency. If false, returns an external dependency 
    /// from spm
    /// - Returns: A TargetDependency for RevenueCatUI
    public static var revenueCatUI: TargetDependency {
        if Environment.local {
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

    /// Returns a dependency for the Nimble testing framework
    public static var nimble: TargetDependency {
        .external(
            name: "Nimble"
        )
    }

    /// Returns a dependency for the SnapshotTesting framework
    public static var snapshotTesting: TargetDependency {
        .external(
            name: "SnapshotTesting"
        )
    }

    /// Returns a dependency for the OHHTTPStubs framework
    public static var ohHTTPStubs: TargetDependency {
        .external(name: "OHHTTPStubs")
    }

    /// Returns a dependency for the OHHTTPStubsSwift framework
    public static var ohHTTPStubsSwift: TargetDependency {
        .external(name: "OHHTTPStubsSwift")
    }

    /// Returns a dependency for the StoreKit framework
    public static var storeKit: TargetDependency {
        .sdk(name: "StoreKit", type: .framework)
    }

    /// Returns a dependency for the StoreKitTest framework
    public static var storeKitTests: TargetDependency {
        .sdk(name: "StoreKitTest", type: .framework)
    }
}
