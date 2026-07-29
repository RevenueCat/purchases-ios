//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowScreenMapper.swift

@_spi(Internal) import RevenueCat

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WorkflowScreenMapper {

    /// `paywallId` is the screen's key in `workflow.screens`, which is the paywall's own id. It cannot be
    /// read off the offering: workflows imply remote config is active, and that prunes the offering's
    /// paywall components payload (see `OfferingsManager.shouldCreatePaywallComponents`).
    static func toPaywallComponents(
        screen: WorkflowScreen,
        uiConfig: UIConfig,
        paywallId: String? = nil
    ) -> Offering.PaywallComponents {
        let data = PaywallComponentsData(
            id: paywallId,
            templateName: screen.templateName,
            assetBaseURL: screen.assetBaseURL,
            componentsConfig: screen.componentsConfig,
            componentsLocalizations: screen.componentsLocalizations,
            revision: screen.revision,
            defaultLocaleIdentifier: screen.defaultLocale,
            exitOffers: screen.exitOffers
        )
        return .init(uiConfig: uiConfig, data: data)
    }

}

#endif
