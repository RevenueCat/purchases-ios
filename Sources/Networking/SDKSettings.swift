//
//  SDKSettings.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

/// The SDK-specific settings served through the `sdk_settings` remote config topic.
struct SDKSettings: Decodable, Equatable {

    let externalPurchases: ExternalPurchases
    let diagnostics: Diagnostics

    init(
        externalPurchases: ExternalPurchases = Self.noExternalPurchases,
        diagnostics: Diagnostics = .init()
    ) {
        self.externalPurchases = externalPurchases
        self.diagnostics = diagnostics
    }

    /// The rules for purchases taken outside the store, one entry per store.
    struct ExternalPurchases: Decodable, Equatable {

        let appStore: AppStore

    }

    struct Diagnostics: Decodable, Equatable {

        let enabled: Bool

        init(enabled: Bool = false) {
            self.enabled = enabled
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.enabled = (try? container.decode(Bool.self, forKey: .enabled)) ?? false
        }

    }

}

extension SDKSettings {

    init() {
        self.init(externalPurchases: Self.noExternalPurchases, diagnostics: .init())
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.externalPurchases = (try? container.decode(ExternalPurchases.self, forKey: .externalPurchases))
            ?? Self.noExternalPurchases
        self.diagnostics = (try? container.decode(Diagnostics.self, forKey: .diagnostics)) ?? .init()
    }

    private static let noExternalPurchases = ExternalPurchases(
        appStore: .init(storefrontsAllowedWithoutStoreEligibility: [])
    )

}

extension SDKSettings.ExternalPurchases {

    struct AppStore: Decodable, Equatable {

        /// The storefronts where Apple's external purchase APIs are not required, as ISO 3166-1 alpha-3 codes.
        ///
        /// Empty when the backend sends none, so no storefront is treated as one of them.
        let storefrontsAllowedWithoutStoreEligibility: Set<String>

    }

}

extension SDKSettings.ExternalPurchases.AppStore {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Compared against what StoreKit reports, so held in one case rather than trusted to arrive in it.
        let storefronts = try container.decodeIfPresent([String].self,
                                                        forKey: .storefrontsAllowedWithoutStoreEligibility)
        self.storefrontsAllowedWithoutStoreEligibility = Set((storefronts ?? []).map { $0.uppercased() })
    }

}

private extension SDKSettings {

    enum CodingKeys: String, CodingKey {
        case externalPurchases
        case diagnostics
    }

}

private extension SDKSettings.Diagnostics {

    enum CodingKeys: String, CodingKey {
        case enabled
    }

}

private extension SDKSettings.ExternalPurchases.AppStore {

    enum CodingKeys: String, CodingKey {
        case storefrontsAllowedWithoutStoreEligibility
    }

}
