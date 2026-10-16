//
//  AdsConfiguration.swift
//
//  Created by RevenueCat.
//

import Foundation

/// Configuration passed to ``RCAds/configure(with:)``.
///
/// Both values are optional: when omitted they are taken from the configured `Purchases` instance.
@_spi(Experimental) public struct AdsConfiguration {

    /// The RevenueCat public API key. Defaults to the key `Purchases` was configured with.
    public var apiKey: String?

    /// Base URL of the RevenueCat ad-serving backend.
    /// Defaults to `Purchases.proxyURL`, or the RevenueCat API host when no proxy is set.
    public var serverURL: URL?

    /// Creates a configuration. `nil` values fall back to the configured `Purchases` instance.
    public init(apiKey: String? = nil, serverURL: URL? = nil) {
        self.apiKey = apiKey
        self.serverURL = serverURL
    }

}

/// The fully resolved values an ad module is initialized with.
struct ResolvedAdsConfiguration: Equatable {

    let apiKey: String
    let auctionURL: URL

    var authorizationHeaderValue: String { "Bearer \(self.apiKey)" }

}

extension AdsConfiguration {

    // swiftlint:disable:next force_unwrapping
    static let defaultServerURL = URL(string: "https://api.revenuecat.com")!
    static let auctionPath = "v1/ads/openrtb2/auction"

    func resolve(purchasesAPIKey: String?, purchasesProxyURL: URL?) throws -> ResolvedAdsConfiguration {
        guard let apiKey = (self.apiKey ?? purchasesAPIKey), !apiKey.isEmpty else {
            throw AdsError(
                code: .notConfigured,
                message: "No API key: pass one in AdsConfiguration or configure Purchases first."
            )
        }

        let serverURL = self.serverURL ?? purchasesProxyURL ?? Self.defaultServerURL
        guard let scheme = serverURL.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            throw AdsError(code: .invalidConfiguration, message: "Server URL must be http(s): \(serverURL)")
        }

        return ResolvedAdsConfiguration(
            apiKey: apiKey,
            auctionURL: serverURL.appendingPathComponent(Self.auctionPath)
        )
    }

}
