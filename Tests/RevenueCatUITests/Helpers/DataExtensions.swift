//
//  DataExtensions.swift
//  
//
//  Created by Nacho Soto on 7/17/23.
//

import Foundation
@testable import RevenueCat
@testable import RevenueCatUI

// MARK: - Extensions

extension Offering {

    var withLocalImages: Offering {
        return self.map { $0?.withLocalImages }
    }

    /// Creates a copy of the offering's paywall with a single localization
    func with(localization: PaywallData.LocalizedConfiguration) -> Self {
        return self.map { $0?.with(localization: localization) }
    }

    /// Creates a copy of the offering's paywall with a single localization
    func with(localizationByTier: [String: PaywallData.LocalizedConfiguration]) -> Self {
        return self.map { $0?.with(localizationByTier: localizationByTier) }
    }

    /// Creates a copy of the offering's paywall with a single localization
    func with(config: PaywallData.Configuration) -> Self {
        return self.map { $0?.with(config: config) }
    }

    /// Creates a copy of the offering's paywall applying a modifier to its localization, if present.
    func map(localization modifier: (inout PaywallData.LocalizedConfiguration) -> Void) -> Self {
        return self.map { paywall in
            if let paywall, var localization = paywall.localizedConfiguration {
                modifier(&localization)
                return paywall.with(localization: localization)
            } else {
                return nil
            }
        }
    }

    /// Creates a copy of the offering's paywall applying a modifier to its multi-tier localization, if present.
    func map(localizationByTier modifier: (inout [String: PaywallData.LocalizedConfiguration]) -> Void) -> Self {
        return self.map { paywall in
            if let paywall, var localizationByTier = paywall.localizedConfigurationByTier {
                modifier(&localizationByTier)
                return paywall.with(localizationByTier: localizationByTier)
            } else {
                return nil
            }
        }
    }

    /// Creates a copy of the offering's paywall with a new template name
    func with(templateName: String) -> Self {
        return self.map { $0?.with(templateName: templateName) }
    }

    private func map(_ modifier: (PaywallData?) -> PaywallData?) -> Self {
        return .init(
            identifier: self.identifier,
            serverDescription: self.serverDescription,
            metadata: self.metadata,
            paywall: modifier(self.paywall),
            availablePackages: self.availablePackages
        )
    }

}

extension PaywallData {

    var withLocalImages: Self {
        var copy = self
        copy.assetBaseURL = URL(fileURLWithPath: Bundle.module.bundlePath)
        copy.config.images = .init(header: "header.heic",
                                   background: "background.heic",
                                   icon: "header.heic")
        copy.config.imagesByTier = .init(
            uniqueKeysWithValues: copy.config.tiers
                .lazy
                .map { ($0.id, copy.config.images) }
            )

        return copy
    }

    /// For snapshot tests to be able to produce a consistent `assetBaseURL`
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    var withTestAssetBaseURL: Self {
        var copy = self
        copy.assetBaseURL = TestData.paywallAssetBaseURL

        return copy
    }

    /// Creates a copy of the paywall with a single localization
    func with(localization: LocalizedConfiguration) -> Self {
        return .init(templateName: self.templateName,
                     config: self.config,
                     localization: localization,
                     assetBaseURL: self.assetBaseURL)
    }

    /// Creates a copy of the paywall with a single localization for a multi-tier paywall.
    func with(localizationByTier: [String: LocalizedConfiguration]) -> Self {
        return .init(templateName: self.templateName,
                     config: self.config,
                     localizationByTier: localizationByTier,
                     assetBaseURL: self.assetBaseURL)
    }

    /// Creates a copy of the paywall with a single localization
    func with(config: PaywallData.Configuration) -> Self {
        return .init(templateName: self.templateName,
                     config: config,
                     localization: self.localization,
                     localizationByTier: self.localizationByTier,
                     assetBaseURL: self.assetBaseURL)
    }

    /// Creates a copy of the paywall with a new template name
    func with(templateName: String) -> Self {
        return .init(templateName: templateName,
                     config: self.config,
                     localization: self.localization,
                     localizationByTier: self.localizationByTier,
                     assetBaseURL: self.assetBaseURL)
    }

}
