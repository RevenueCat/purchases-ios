// periphery:ignore:all
// swiftlint:disable:this file_name
// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all
import Foundation
// MARK: - Swift Bundle Accessor for Frameworks
private class BundleFinder {}
extension Foundation.Bundle {
/// Since RevenueCat is a dynamic framework, the bundle for classes within this module can be used directly.
    static let module = Bundle(for: BundleFinder.self)
}

// swiftformat:enable all
// swiftlint:enable all