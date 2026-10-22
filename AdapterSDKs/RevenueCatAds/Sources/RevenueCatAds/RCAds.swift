//
//  RCAds.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(PrebidMobile)
@_spi(Internal) import RevenueCat

/// Entry point for RevenueCat ad serving.
@available(iOS 15.0, *)
@MainActor
@_spi(Experimental) public final class RCAds {

    private(set) static var module: AdModule?

    private init() {}

    /// Configures ad serving. Call once, after `Purchases.configure`, before loading any ad.
    ///
    /// - Parameter configuration: Overrides for the API key and server URL. By default both are taken
    ///   from the configured `Purchases` instance.
    /// - Throws: ``AdsError`` with code ``AdsError/Code/notConfigured`` or
    ///   ``AdsError/Code/invalidConfiguration``.
    public static func configure(with configuration: AdsConfiguration = AdsConfiguration()) throws {
        try Self.configure(with: configuration, makeModule: { PrebidAdModule() })
    }

    static func configure(with configuration: AdsConfiguration, makeModule: () -> AdModule) throws {
        let resolved = try configuration.resolve(
            purchasesAPIKey: Purchases.isConfigured ? Purchases.shared.apiKey : nil,
            purchasesProxyURL: Purchases.proxyURL
        )
        let module = makeModule()
        try module.initialize(with: resolved)
        Self.module = module
    }

    static func reset() {
        Self.module = nil
    }

}

#endif
