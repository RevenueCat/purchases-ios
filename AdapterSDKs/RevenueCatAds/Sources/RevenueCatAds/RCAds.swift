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
    /// - Throws: ``AdsError`` with code ``AdsError/Code/notConfigured`` if `Purchases` is not configured,
    ///   or ``AdsError/Code/invalidConfiguration``.
    public static func configure(with configuration: AdsConfiguration = AdsConfiguration()) throws {
        try Self.configure(
            with: configuration,
            module: PrebidAdModule(),
            purchasesAPIKey: Purchases.isConfigured ? Purchases.shared.apiKey : nil,
            purchasesProxyURL: Purchases.proxyURL
        )
    }

    static func configure(
        with configuration: AdsConfiguration,
        module: AdModule,
        purchasesAPIKey: String?,
        purchasesProxyURL: URL?
    ) throws {
        // Ad tracking goes through `Purchases.shared`, so an explicit API key alone is not enough.
        guard let purchasesAPIKey else {
            throw AdsError(code: .notConfigured, message: "Call Purchases.configure before RCAds.configure.")
        }

        let resolved = try configuration.resolve(
            purchasesAPIKey: purchasesAPIKey,
            purchasesProxyURL: purchasesProxyURL
        )
        try module.initialize(with: resolved)
        Self.module = module
    }

    #if DEBUG
    static func reset() {
        Self.module = nil
    }
    #endif

}

#endif
