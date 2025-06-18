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
            .revenueCatLocal
        }
    }

    /// Returns a local RevenueCat dependency from SPM
    /// - Returns: A TargetDependency for RevenueCat from external source
    public static var revenueCatLocal: TargetDependency {
        .external(
            name: "RevenueCat"
        )
    }

    /// Returns a RevenueCat dependency with custom entitlement computation enabled
    /// - Returns: A TargetDependency for RevenueCat_CustomEntitlementComputation
    public static var revenueCatCustomEntitlementComputation: TargetDependency {
        .project(
            target: "RevenueCat_CustomEntitlementComputation",
            path: .relativeToRoot("Projects/RevenueCat")
        )
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
            .revenueCatUILocal
        }
    }

    /// Returns a local RevenueCatUI dependency from SPM
    /// - Returns: A TargetDependency for RevenueCatUI from external source
    public static var revenueCatUILocal: TargetDependency {
        .external(
            name: "RevenueCatUI"
        )
    }

    /// Returns a ReceiptParser dependency
    /// - Returns: A TargetDependency for ReceiptParser
    public static var receiptparser: TargetDependency {
        .project(
            target: "ReceiptParser",
            path: .relativeToRoot("Projects/RevenueCat")
        )
    }

    /// Returns a dependency for the Nimble testing framework
    /// - Returns: A TargetDependency for Nimble
    public static var nimble: TargetDependency {
        .external(
            name: "Nimble"
        )
    }

    /// Returns a dependency for the SnapshotTesting framework
    /// - Returns: A TargetDependency for SnapshotTesting
    public static var snapshotTesting: TargetDependency {
        .external(
            name: "SnapshotTesting"
        )
    }

    /// Returns a dependency for the OHHTTPStubs framework
    /// - Returns: A TargetDependency for OHHTTPStubs
    public static var ohHTTPStubs: TargetDependency {
        .external(name: "OHHTTPStubs")
    }

    /// Returns a dependency for the OHHTTPStubsSwift framework
    /// - Returns: A TargetDependency for OHHTTPStubsSwift
    public static var ohHTTPStubsSwift: TargetDependency {
        .external(name: "OHHTTPStubsSwift")
    }

    /// Returns a dependency for the StoreKit framework
    /// - Returns: A TargetDependency for StoreKit
    public static var storeKit: TargetDependency {
        .sdk(name: "StoreKit", type: .framework)
    }

    /// Returns a dependency for the StoreKitTest framework
    /// - Returns: A TargetDependency for StoreKitTest
    public static var storeKitTests: TargetDependency {
        .sdk(name: "StoreKitTest", type: .framework)
    }
}
