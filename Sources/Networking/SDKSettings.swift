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

    init() {
        self.init(externalPurchases: .init())
    }

    init(externalPurchases: ExternalPurchases) {
        self.externalPurchases = externalPurchases
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.externalPurchases = try container.decodeIfPresent(ExternalPurchases.self,
                                                               forKey: .externalPurchases) ?? .init()
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

        /// Whether this app config reports its external purchases to Apple with a token.
        ///
        /// A token obliges a report, so one is only minted where the backend says so. `false` when the backend
        /// sends none.
        let tokenReportingEnabled: Bool

        init() {
            self.init(storefrontsAllowedWithoutStoreEligibility: [], tokenReportingEnabled: false)
        }

        init(storefrontsAllowedWithoutStoreEligibility: Set<String>, tokenReportingEnabled: Bool) {
            self.storefrontsAllowedWithoutStoreEligibility = storefrontsAllowedWithoutStoreEligibility
            self.tokenReportingEnabled = tokenReportingEnabled
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // Compared against what StoreKit reports, so held in one case rather than trusted to arrive in it.
            let storefronts = try container.decodeIfPresent([String].self,
                                                            forKey: .storefrontsAllowedWithoutStoreEligibility)
            self.storefrontsAllowedWithoutStoreEligibility = Set((storefronts ?? []).map { $0.uppercased() })
            self.tokenReportingEnabled = try container.decodeIfPresent(Bool.self,
                                                                       forKey: .tokenReportingEnabled) ?? false
        }

    }

}

private extension SDKSettings {

    enum CodingKeys: String, CodingKey {
        case externalPurchases
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
        case tokenReportingEnabled
    }

}
