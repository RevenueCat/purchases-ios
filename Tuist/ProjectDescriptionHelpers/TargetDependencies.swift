import ProjectDescription

extension TargetDependency {
    /// Returns the RevenueCat dependency based on the dependency mode
    /// - Returns: A TargetDependency for RevenueCat
    public static var revenueCat: TargetDependency? {
        switch Environment.dependencyMode {
        case .localSwiftPackage:
            return .revenueCatRemoteSwiftPackage // Local SPM dependency is added via the project's packages
        case .remoteSwiftPackage:
            return .revenueCatRemoteSwiftPackage
        case .remoteXcodeProject:
            return .revenueCatRemoteXcodeProject
        case .localXcodeProject:
            return .revenueCatXcodeProject
        }
    }

    /// Returns the RevenueCatUI dependency based on the dependency mode
    /// - Returns: A TargetDependency for RevenueCatUI
    public static var revenueCatUI: TargetDependency? {
        switch Environment.dependencyMode {
        case .localSwiftPackage:
            return .revenueCatUIRemoteSwiftPackage // Local SPM dependency is added via the project's packages
        case .remoteSwiftPackage:
            return .revenueCatUIRemoteSwiftPackage
        case .remoteXcodeProject:
            return .revenueCatUIRemoteXcodeProject
        case .localXcodeProject:
            return .revenueCatUIXcodeProject
        }
    }

    // RevenueCat

    /// Returns the remote RevenueCat dependency as Tuist's XcodeProj-based dependency
    static var revenueCatRemoteXcodeProject: TargetDependency {
        .external(name: "RevenueCat")
    }

    /// Returns the remote RevenueCat Swift Package Manager dependency
    static var revenueCatRemoteSwiftPackage: TargetDependency {
        .package(product: "RevenueCat", type: .runtime)
    }

    /// Returns the Xcode project RevenueCat dependency
    /// - Returns: A TargetDependency for RevenueCat from Xcode project
    static var revenueCatXcodeProject: TargetDependency {
        .project(
            target: "RevenueCat",
            path: .relativeToRoot("Projects/RevenueCat"))
    }

    // RevenueCatUI

    /// Returns the remote RevenueCat dependency as Tuist's XcodeProj-based dependency
    static var revenueCatUIRemoteXcodeProject: TargetDependency {
        .external(name: "RevenueCatUI")
    }

    /// Returns the remote RevenueCat Swift Package Manager dependency
    static var revenueCatUIRemoteSwiftPackage: TargetDependency {
        .package(product: "RevenueCatUI", type: .runtime)
    }

    /// Returns the Xcode project RevenueCatUI dependency
    /// - Returns: A TargetDependency for RevenueCat from Xcode project
    static var revenueCatUIXcodeProject: TargetDependency {
        .project(
            target: "RevenueCat",
            path: .relativeToRoot("Projects/RevenueCatUI"))
    }

    // Custom Entitlement Computation

    /// Returns a RevenueCat dependency with custom entitlement computation enabled
    /// - Returns: A TargetDependency for RevenueCat_CustomEntitlementComputation
    public static var revenueCatCustomEntitlementComputation: TargetDependency {
        .project(
            target: "RevenueCat_CustomEntitlementComputation",
            path: .relativeToRoot("Projects/RevenueCat")
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
