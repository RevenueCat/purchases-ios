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

    let diagnostics: Diagnostics
    let externalPurchases: ExternalPurchases

    init(diagnostics: Diagnostics = .init()) {
        self.init(diagnostics: diagnostics, externalPurchases: .init())
    }

    init(diagnostics: Diagnostics, externalPurchases: ExternalPurchases) {
        self.diagnostics = diagnostics
        self.externalPurchases = externalPurchases
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.diagnostics = try container.decodeIfPresent(Diagnostics.self, forKey: .diagnostics) ?? .init()
        self.externalPurchases = try container.decodeIfPresent(ExternalPurchases.self,
                                                               forKey: .externalPurchases) ?? .init()
    }

    struct Diagnostics: Decodable, Equatable {

        let enabled: Bool

        init(enabled: Bool = false) {
            self.enabled = enabled
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        }

    }

    /// The rules for purchases taken outside the store, one entry per store.
    struct ExternalPurchases: Decodable, Equatable {

        let appStore: AppStore

        init() {
            self.init(appStore: .init())
        }

        init(appStore: AppStore) {
            self.appStore = appStore
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.appStore = try container.decodeIfPresent(AppStore.self, forKey: .appStore) ?? .init()
        }

    }

}

extension SDKSettings.ExternalPurchases {

    struct AppStore: Decodable, Equatable {

        /// The storefronts where Apple's external purchase APIs are not required, as ISO 3166-1 alpha-3 codes.
        ///
        /// Empty when the backend sends none, so no storefront is treated as one of them.
        let storefrontsAllowedWithoutStoreEligibility: Set<String>

        init() {
            self.init(storefrontsAllowedWithoutStoreEligibility: [])
        }

        init(storefrontsAllowedWithoutStoreEligibility: Set<String>) {
            self.storefrontsAllowedWithoutStoreEligibility = storefrontsAllowedWithoutStoreEligibility
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // Compared against what StoreKit reports, so held in one case rather than trusted to arrive in it.
            let storefronts = try container.decodeIfPresent([String].self,
                                                            forKey: .storefrontsAllowedWithoutStoreEligibility)
            self.storefrontsAllowedWithoutStoreEligibility = Set((storefronts ?? []).map { $0.uppercased() })
        }

    }

}

private extension SDKSettings {

    enum CodingKeys: String, CodingKey {
        case diagnostics
        case externalPurchases
    }

}

private extension SDKSettings.Diagnostics {

    enum CodingKeys: String, CodingKey {
        case enabled
    }

}

private extension SDKSettings.ExternalPurchases {

    enum CodingKeys: String, CodingKey {
        case appStore
    }

}

private extension SDKSettings.ExternalPurchases.AppStore {

    enum CodingKeys: String, CodingKey {
        case storefrontsAllowedWithoutStoreEligibility
    }

}
