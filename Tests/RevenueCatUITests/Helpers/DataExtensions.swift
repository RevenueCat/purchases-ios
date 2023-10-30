//
//  DataExtensions.swift
//  
//
//  Created by Nacho Soto on 7/17/23.
//

import Foundation
import RevenueCat
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
        copy.config.images = .init(header: "header.jpg",
                                   background: "background.jpg",
                                   icon: "header.jpg")

        return copy
    }

    /// For snapshot tests to be able to produce a consistent `assetBaseURL`
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
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

    /// Creates a copy of the paywall with a new template name
    func with(templateName: String) -> Self {
        return .init(templateName: templateName,
                     config: self.config,
                     localization: self.localizedConfiguration,
                     assetBaseURL: self.assetBaseURL)
    }

}
