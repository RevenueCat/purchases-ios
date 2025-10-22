//
//  PaywallSourceEnvironment.swift
//
//
//  Created by RevenueCat on 2/26/25.
//

#if canImport(SwiftUI)

import SwiftUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallSourceKey: EnvironmentKey {

    static let defaultValue: PaywallSource? = nil

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    /// The optional paywall source available in the current environment.
    @_spi(Internal) public var paywallSource: PaywallSource? {
        get { self[PaywallSourceKey.self] }
        set { self[PaywallSourceKey.self] = newValue }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Associates the provided paywall source with this view hierarchy so downstream paywall presentations can read it.
    @_spi(Internal) public func paywallSource(_ source: PaywallSource?) -> some View {
        self.environment(\.paywallSource, source)
    }

}

#endif

#endif
